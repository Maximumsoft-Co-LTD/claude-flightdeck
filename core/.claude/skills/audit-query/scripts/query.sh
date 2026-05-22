#!/usr/bin/env bash
# audit-query — aggregate docs/spec/audit/*.jsonl into a markdown digest.
#
# Read-only. Fail-open on missing audit dir; exit 1 only if jq is missing.
# Portable: macOS (BSD date) + Linux (GNU date) compatibility.
#
# Flags:
#   --since DATE         ISO YYYY-MM-DD (default: 7 days before today, UTC)
#   --until DATE         ISO YYYY-MM-DD (default: today, UTC)
#   --sprint S<N>        Match task IDs of form *-S<N>.* (e.g. S03 → URLSH-S03.04)
#   --agent NAME         Filter by subagent_type
#   --task ID            Filter by exact task_id
#   --top files|agents|tasks   Emphasize a section (default: agents)
#   --audit-dir PATH     Override docs/spec/audit (used by smoke tests)
#   -h, --help           Print usage
#
# Output: markdown digest on stdout.

set -uo pipefail

# ---------- jq pre-flight ----------
if ! command -v jq >/dev/null 2>&1; then
  echo "audit-query requires jq; install jq (brew install jq / apt install jq)" >&2
  exit 1
fi

# ---------- defaults ----------
SINCE=""
UNTIL=""
SPRINT=""
AGENT=""
TASK=""
TOP="agents"
AUDIT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/docs/spec/audit"

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------- arg parse ----------
while [ $# -gt 0 ]; do
  case "$1" in
    --since)      SINCE="$2"; shift 2 ;;
    --until)      UNTIL="$2"; shift 2 ;;
    --sprint)     SPRINT="$2"; shift 2 ;;
    --agent)      AGENT="$2"; shift 2 ;;
    --task)       TASK="$2"; shift 2 ;;
    --top)        TOP="$2"; shift 2 ;;
    --audit-dir)  AUDIT_DIR="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *)
      echo "audit-query: unknown flag: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# ---------- portable date helpers ----------
# Compute today (UTC) and (today - 7 days) in YYYY-MM-DD.
# macOS uses `-v-7d`; GNU uses `-d '7 days ago'`. Detect by trying GNU first.
date_n_days_ago() {
  local n="$1"
  if date -u -d "$n days ago" +%Y-%m-%d >/dev/null 2>&1; then
    date -u -d "$n days ago" +%Y-%m-%d
  else
    date -u -v-"${n}"d +%Y-%m-%d
  fi
}

TODAY="$(date -u +%Y-%m-%d)"
[ -z "$SINCE" ] && SINCE="$(date_n_days_ago 7)"
[ -z "$UNTIL" ] && UNTIL="$TODAY"

# Validate ISO format (cheap sanity check).
case "$SINCE" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) echo "audit-query: --since must be YYYY-MM-DD, got: $SINCE" >&2; exit 2 ;;
esac
case "$UNTIL" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) echo "audit-query: --until must be YYYY-MM-DD, got: $UNTIL" >&2; exit 2 ;;
esac

# Convert window to inclusive timestamp bounds used by jq string compare.
SINCE_TS="${SINCE}T00:00:00Z"
UNTIL_TS="${UNTIL}T23:59:59Z"

# ---------- audit dir pre-flight ----------
if [ ! -d "$AUDIT_DIR" ]; then
  echo "no audit log found yet (enable the audit hook to start collecting — see docs/setup/audit-trail.md §Hook configuration)"
  exit 0
fi

# ---------- file selection ----------
# Only consider YYYY-MM.jsonl files whose month overlaps the window. String
# compare on YYYY-MM works because the file naming is lexicographically sorted.
SINCE_MONTH="${SINCE%-*}"   # YYYY-MM
UNTIL_MONTH="${UNTIL%-*}"

# Collect candidate files in deterministic order.
FILES=""
# `set +f` to ensure glob expansion is on; nullglob isn't POSIX so loop guards.
for f in "$AUDIT_DIR"/*.jsonl; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .jsonl)"      # YYYY-MM
  case "$base" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]) ;;
    *) continue ;;
  esac
  if [ "$base" \> "$UNTIL_MONTH" ] || [ "$base" \< "$SINCE_MONTH" ]; then
    continue
  fi
  FILES="$FILES $f"
done

if [ -z "$FILES" ]; then
  echo "no dispatches in window ($SINCE to $UNTIL) — widen --since or verify audit hook is enabled"
  exit 0
fi

# ---------- build jq filter ----------
# Apply ts window + optional agent / task / sprint filters in one pass.
# We use streaming `jq -c` to keep memory low, then re-feed via `jq -s` for
# grouping in the next stage.
JQ_FILTER='select(.ts >= $since and .ts <= $until)'
[ -n "$AGENT" ]  && JQ_FILTER="$JQ_FILTER | select(.subagent_type == \$agent)"
[ -n "$TASK" ]   && JQ_FILTER="$JQ_FILTER | select(.task_id == \$task)"
[ -n "$SPRINT" ] && JQ_FILTER="$JQ_FILTER | select(.task_id != null and (.task_id | test(\"-\" + \$sprint + \"\\\\.\")))"

# Stream filter → temp file; the slurped aggregations re-read it.
TMP="$(mktemp -t audit-query.XXXXXX)" || { echo "audit-query: mktemp failed" >&2; exit 1; }
trap 'rm -f "$TMP"' EXIT

# shellcheck disable=SC2086  # intentional word-split on $FILES
cat $FILES \
  | jq -c \
      --arg since "$SINCE_TS" \
      --arg until "$UNTIL_TS" \
      --arg agent "$AGENT" \
      --arg task  "$TASK" \
      --arg sprint "$SPRINT" \
      "$JQ_FILTER" \
  > "$TMP" 2>/dev/null || true

TOTAL="$(wc -l < "$TMP" | tr -d ' ')"

if [ "$TOTAL" -eq 0 ]; then
  echo "no dispatches in window ($SINCE to $UNTIL) for filters: agent=${AGENT:-*} task=${TASK:-*} sprint=${SPRINT:-*}"
  exit 0
fi

# Count gate-failure indicators (non-empty `reason`).
FAILS="$(jq -c 'select(.reason != "" and .reason != null)' "$TMP" 2>/dev/null | wc -l | tr -d ' ')"

# ---------- emit markdown ----------
printf '# Audit Summary — %s to %s\n\n' "$SINCE" "$UNTIL"
printf '## Dispatches: %s (%s with non-empty reason)\n\n' "$TOTAL" "$FAILS"

# By-agent table — count + p50 + p95 of duration_ms.
# Percentiles computed via sort + index pick (cheap, no extra deps).
printf '## By agent\n\n'
printf '| Agent | Count | p50 dur (ms) | p95 dur (ms) |\n'
printf '|---|---|---|---|\n'
jq -s '
  group_by(.subagent_type)
  | map({
      agent: (.[0].subagent_type // "(unknown)"),
      count: length,
      durs:  (map(.duration_ms) | map(select(. != null and . != "")))
    })
  | map(. + {
      p50: (if (.durs | length) == 0 then null
            else (.durs | sort | .[((length-1)/2 | floor)])
            end),
      p95: (if (.durs | length) == 0 then null
            else (.durs | sort | .[((length-1)*95/100 | floor)])
            end)
    })
  | sort_by(-.count)
  | .[]
  | "| \(.agent) | \(.count) | \(.p50 // "-") | \(.p95 // "-") |"
' "$TMP" -r 2>/dev/null
printf '\n'

# Top 5 longest dispatches.
printf '## Top 5 longest dispatches\n\n'
printf '| Agent | Task | Duration (ms) | Files touched |\n'
printf '|---|---|---|---|\n'
jq -s '
  map(select(.duration_ms != null and .duration_ms != ""))
  | sort_by(-.duration_ms)
  | .[:5]
  | .[]
  | "| \(.subagent_type // "(unknown)") | \(.task_id // "-") | \(.duration_ms) | \((.files_touched // []) | length) |"
' "$TMP" -r 2>/dev/null
printf '\n'

# Top 10 most-touched files.
printf '## Top 10 most-touched files\n\n'
printf '| File | Touches | Last touched |\n'
printf '|---|---|---|\n'
jq -s '
  [ .[] as $row
    | ($row.files_touched // [])[]?
    | {file: ., ts: $row.ts} ]
  | group_by(.file)
  | map({
      file:  .[0].file,
      count: length,
      last:  (map(.ts) | max)
    })
  | sort_by(-.count)
  | .[:10]
  | .[]
  | "| \(.file) | \(.count) | \(.last) |"
' "$TMP" -r 2>/dev/null
printf '\n'

# Recurring task IDs (count > 1).
printf '## Recurring task IDs (multi-dispatch — retries / multi-phase)\n\n'
RECURRING="$(jq -s '
  map(select(.task_id != null and .task_id != ""))
  | group_by(.task_id)
  | map({task: .[0].task_id, n: length})
  | map(select(.n > 1))
  | sort_by(-.n)
  | .[]
  | "| \(.task) | \(.n) |"
' "$TMP" -r 2>/dev/null)"
if [ -z "$RECURRING" ]; then
  printf '_No task IDs appear more than once in this window._\n\n'
else
  printf '| Task | Dispatches |\n|---|---|\n%s\n\n' "$RECURRING"
fi

# Gate-failure indicator.
printf '## Gate-failure indicator\n\n'
if [ "$FAILS" -eq 0 ]; then
  printf '_No events with a non-empty `reason` field in this window._\n\n'
else
  printf '%s events with a non-empty `reason` field. Inspect:\n\n' "$FAILS"
  printf '```bash\njq -c '"'"'select(.reason != "" and .reason != null)'"'"' %s\n```\n\n' "$AUDIT_DIR/*.jsonl"
fi

# Footer — emphasis hint per --top choice.
case "$TOP" in
  files)  printf '> Emphasis: **files** — see the top-10 most-touched files table above for refactor candidates.\n' ;;
  tasks)  printf '> Emphasis: **tasks** — see the recurring-task-IDs table above for retry / multi-phase work.\n' ;;
  agents|*) printf '> Emphasis: **agents** — see the by-agent table above for latency profile per subagent type.\n' ;;
esac

exit 0
