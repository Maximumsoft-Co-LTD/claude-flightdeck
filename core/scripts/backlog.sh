#!/usr/bin/env bash
# backlog.sh — deterministic backlog hygiene for the AI-Workflows control plane.
#
# Why this exists (the short version)
# -----------------------------------
# Backlog `Status` drift is the #1 reason `/work` re-picks already-shipped work.
# The cure is to stop *trusting* a hand-maintained status column and start
# *deriving* done-ness mechanically:
#   - the hot file (docs/project/backlog.md `## Active`) holds ONLY open / wip rows;
#   - terminal rows (done / wontfix / superseded-by) are swept to a thin COLD
#     ledger (docs/project/archive/backlog-archive.md) that is grepped, never
#     loaded wholesale;
#   - an item is "done" iff it is ABSENT from Active and PRESENT in the archive.
# This script is that mechanism. It runs in bash + CI — **zero LLM tokens** — so
# the heavy, repetitive reconciliation never burns model context.
# Rationale + the hot/cold split: docs/setup/index-discipline.md.
#
# Status enum (delivery lifecycle ONLY — design-review state lives in designs/INDEX.md):
#   Active (hot):     open | wip S<N>
#   Terminal (cold):  done S<N> | wontfix | superseded-by B<ID>
#
# Design
# ------
# - Dependency-free (pure bash; macOS bash 3.2 + CI bash 5). No bash-4 features.
# - Idempotent where it writes (sweep is a no-op once Active is clean).
# - Never deletes detail: the archive is one thin line; full detail stays in the
#   sprint files + ideas/ + git history.
# - Root resolves to the project (the dir holding docs/project/backlog.md):
#   override with BACKLOG_ROOT=<dir> for tests.
#
# Usage:
#   scripts/backlog.sh check                 # CI gate: enum-conformance + size cap (exit 1 on drift)
#   scripts/backlog.sh verify <B###>         # pick-gate: exit 0 open · 1 closed · 2 unknown
#   scripts/backlog.sh sweep                 # move terminal Active rows -> cold archive (idempotent)
#   scripts/backlog.sh reconcile             # advisory: wip rows that look already-closed in their sprint
#   scripts/backlog.sh index                 # regenerate docs/project/backlog-index.md (derived, can't drift)
#   scripts/backlog.sh archive-sprints [--keep N] [--apply]   # de-clutter sprints/ (dry-run unless --apply)
#   scripts/backlog.sh install-hook          # git pre-commit gate: backlog can't be committed drifted (always-synced)

set -uo pipefail

ROOT="${BACKLOG_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKLOG="$ROOT/docs/project/backlog.md"
ARCHIVE="$ROOT/docs/project/archive/backlog-archive.md"
INDEX="$ROOT/docs/project/backlog-index.md"
SPRINTS="$ROOT/docs/project/sprints"
SIZE_CAP="${BACKLOG_SIZE_CAP:-800}"          # hard fail: hot backlog line budget
BYTE_CAP="${BACKLOG_BYTE_CAP:-120000}"       # hard fail: ~120 KB (the real token cost — rows can be huge)
ARCHIVE_CAP="${BACKLOG_ARCHIVE_CAP:-1000}"   # warn: roll the cold ledger past this

die()  { echo "backlog.sh: $*" >&2; exit 2; }
have_backlog() { [ -f "$BACKLOG" ] || die "no backlog at $BACKLOG (set BACKLOG_ROOT?)"; }

# Print the `## Active` section body (rows between `## Active` and the next `## `).
active_section() { awk '/^## Active/{a=1;next} /^## /{a=0} a' "$BACKLOG"; }

# Active table rows that name a backlog item (start with `| B<digits>`).
active_rows() { active_section | grep -E '^\|[[:space:]]*B[0-9]' || true; }

# Last table cell of a row = the Status column (robust to extra columns).
row_status() {
  awk -F'|' '{ s=$(NF-1); gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); print s }'
}
row_field() { # row_field <n>  -> trimmed nth pipe field
  awk -F'|' -v n="$1" '{ s=$n; gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); print s }'
}

# board_done <ID> -> echoes "S<N>" if a sprint board marks that ID `[x]` (done),
# else nothing. Matches the board format where the backlog ID IS the first-cell
# task ID (`| B413 | ... | `[x]` | ...`). High-PRECISION: a hit means definitely
# done, so it reliably catches a backlog row mislabeled open/wip/blob (the re-pick
# disease). NOT high-recall: it intentionally does NOT match older mapping-style
# boards (`| 83.A | task | repo | B413+B414 | ... | [ ] Not Started |`) — those
# often drifted to "Not Started" even for shipped work, so absence of a hit means
# "unknown", never "open". For those, git history is the arbiter (see
# /backlog-migrate). Absence of a hit is therefore never treated as proof-of-open.
board_done() {
  local id="$1"
  grep -rlE "^\|[[:space:]]*$id[[:space:]]*\|.*\[x\]" \
      "$SPRINTS"/*/tasks.md "$SPRINTS"/historical/*/tasks.md 2>/dev/null \
    | sed -E "s#.*/(S[0-9]+)/tasks.md#\1#" | head -n1
}

TERMINAL_RE='^(done S[0-9]+|wontfix|superseded-by B[0-9]+)$'
ACTIVE_RE='^(open|wip S[0-9]+)$'

# ----------------------------------------------------------------------------
cmd_check() {
  have_backlog
  local fail=0
  # 1. Enum conformance — every Active B-row's status is exactly open | wip S<N>.
  #    Catches BOTH drift directions: terminal-left-in-Active (done/wontfix/...)
  #    AND mislabeled blobs (verified / discovery / "scheduled S## ... done").
  local bad
  bad="$(awk '
    /^## Active/{a=1;next} /^## /{a=0}
    a && /^\|[[:space:]]*B[0-9]/ {
      n=split($0,f,"|"); s=f[n-1]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",s)
      if (s !~ /^(open|wip S[0-9]+)$/) print "    " $0
    }' "$BACKLOG")"
  if [ -n "$bad" ]; then
    echo "✗ backlog ## Active has rows whose Status is not 'open' or 'wip S<N>':"
    echo "$bad"
    echo "  → terminal rows (done/wontfix/superseded-by) must be swept:  scripts/backlog.sh sweep"
    echo "  → a free-text/blob status (e.g. 'verified', 'discovery') is drift — normalize it."
    fail=1
  fi
  # 2. Hard size cap — the hot file (Read every /work) must never grow back to the
  #    316 KB / 1465-line failure. Cap BOTH lines and bytes: rows can be huge
  #    (a single real backlog row reached ~2.6 KB), so bytes is the truer token cost.
  local n b; n="$(wc -l < "$BACKLOG" | tr -d ' ')"; b="$(wc -c < "$BACKLOG" | tr -d ' ')"
  if [ "$n" -gt "$SIZE_CAP" ]; then
    echo "✗ backlog.md is $n lines (> $SIZE_CAP). Sweep closed rows: scripts/backlog.sh sweep"
    fail=1
  fi
  if [ "$b" -gt "$BYTE_CAP" ]; then
    echo "✗ backlog.md is $b bytes (> $BYTE_CAP ≈ $((BYTE_CAP/1000))KB). Sweep closed rows AND move long descriptions/status-narratives out of table cells into <details> blocks or the design doc."
    fail=1
  fi
  if [ "$fail" -eq 0 ]; then
    echo "✓ backlog hygiene: ## Active enum-clean · $n lines ≤ $SIZE_CAP · $b bytes ≤ $BYTE_CAP"
  fi
  return "$fail"
}

# ----------------------------------------------------------------------------
cmd_verify() {
  have_backlog
  local id="${1:-}"; [ -n "$id" ] || die "verify needs a backlog ID (e.g. B042)"
  case "$id" in B*) ;; *) id="B$id" ;; esac
  # Closed if it sits in the cold ledger…
  if [ -f "$ARCHIVE" ] && grep -qE "^\|[[:space:]]*$id[[:space:]]*\|" "$ARCHIVE"; then
    echo "CLOSED  $id — in cold archive: $(grep -m1 -E "^\|[[:space:]]*$id[[:space:]]*\|" "$ARCHIVE")"
    return 1
  fi
  # …or a sprint board already marks it done (authoritative — beats the Status
  # column, which is exactly what drifts). Catches a row mislabeled open/wip/blob.
  local sp; sp="$(board_done "$id")"
  if [ -n "$sp" ]; then
    echo "CLOSED  $id — sprint board $sp/tasks.md marks it \`[x]\` done. Status column is stale; do not re-implement."
    return 1
  fi
  # …or still in Active but already at a terminal status (shipped, not yet swept).
  local row st
  row="$(active_rows | grep -E "^\|[[:space:]]*$id[[:space:]]*\|" | head -n1)"
  if [ -n "$row" ]; then
    st="$(printf '%s\n' "$row" | row_status)"
    if printf '%s' "$st" | grep -qE "$TERMINAL_RE"; then
      echo "CLOSED  $id — Active row is terminal ('$st') but not yet swept. Run: scripts/backlog.sh sweep"
      return 1
    fi
    echo "OPEN    $id — status '$st', no sprint board marks it done. Safe to pick."
    return 0
  fi
  echo "UNKNOWN $id — not in ## Active, the cold archive, nor any sprint board. Do NOT assume open; check the sprint records."
  return 2
}

# ----------------------------------------------------------------------------
cmd_sweep() {
  have_backlog
  mkdir -p "$(dirname "$ARCHIVE")"
  if [ ! -f "$ARCHIVE" ]; then
    {
      echo "# Backlog Archive (cold ledger) — one thin line per closed item."
      echo
      echo "> Generated + appended by \`scripts/backlog.sh sweep\`. **Grep this, never Read it"
      echo "> wholesale.** Full detail lives in the sprint files + \`ideas/\` + git history."
      echo "> Rolls to \`backlog-archive-2.md\` past $ARCHIVE_CAP lines."
      echo
      echo "| ID | Status | Title |"
      echo "|----|--------|-------|"
    } > "$ARCHIVE"
  fi
  local tmp_new tmp_swept
  tmp_new="$(mktemp)"; tmp_swept="$(mktemp)"
  awk -v SW="$tmp_swept" '
    /^## Active/ { active=1; print; next }
    /^## /       { active=0; print; next }
    {
      if (active && $0 ~ /^\|[[:space:]]*B[0-9]/) {
        n=split($0,f,"|"); s=f[n-1]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",s)
        if (s ~ /^(done S[0-9]+|wontfix|superseded-by B[0-9]+)$/) { print $0 > SW; next }
      }
      print
    }' "$BACKLOG" > "$tmp_new"
  local count; count="$(grep -cE '^\|' "$tmp_swept" 2>/dev/null || true)"; count="${count:-0}"
  if [ "$count" -eq 0 ]; then
    rm -f "$tmp_new" "$tmp_swept"
    echo "✓ sweep: nothing to do (## Active is already open/wip-only)"
    return 0
  fi
  # Reformat swept rows -> thin archive lines: | ID | Status | Title |
  awk -F'|' '{
    id=$2; ti=$4; st=$(NF-1)
    gsub(/^[[:space:]]+|[[:space:]]+$/,"",id)
    gsub(/^[[:space:]]+|[[:space:]]+$/,"",ti)
    gsub(/^[[:space:]]+|[[:space:]]+$/,"",st)
    printf "| %s | %s | %s |\n", id, st, ti
  }' "$tmp_swept" >> "$ARCHIVE"
  mv "$tmp_new" "$BACKLOG"
  rm -f "$tmp_swept"
  echo "✓ sweep: moved $count terminal row(s) from ## Active → ${ARCHIVE#$ROOT/}"
  local an; an="$(wc -l < "$ARCHIVE" | tr -d ' ')"
  [ "$an" -gt "$ARCHIVE_CAP" ] && echo "  ⚠ archive is $an lines (> $ARCHIVE_CAP) — roll oldest into backlog-archive-2.md"
  return 0
}

# ----------------------------------------------------------------------------
# Advisory: flag any Active row (open OR wip) that a sprint board already marks
# `[x]` done — i.e. shipped but still sitting in the hot file with a stale status.
# Never hard-fails (board IDs can legitimately differ from backlog IDs on some
# projects); on projects where backlog ID == sprint task ID this is high-signal.
cmd_reconcile() {
  have_backlog
  local flagged=0
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    local id st sp
    id="$(printf '%s\n' "$row" | row_field 2)"
    st="$(printf '%s\n' "$row" | row_status)"
    sp="$(board_done "$id")"
    if [ -n "$sp" ]; then
      echo "  ? $id is '$st' in ## Active but $sp/tasks.md marks it \`[x]\` done → set to 'done $sp' and sweep."
      flagged=1
    fi
  done <<EOF
$(active_rows)
EOF
  if [ "$flagged" -eq 0 ]; then
    echo "✓ reconcile: no Active row is marked done on a sprint board"
  else
    echo "  (advisory — these are shipped-but-still-Active; reconcile before they cause a re-pick)"
  fi
  return 0
}

# ----------------------------------------------------------------------------
cmd_index() {
  have_backlog
  local nopen nwip sprints
  nopen="$(active_rows | row_status | grep -cE '^open$' || true)"
  nwip="$(active_rows | row_status | grep -cE '^wip S[0-9]+$' || true)"
  sprints="$(active_rows | row_status | grep -oE 'S[0-9]+' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  [ -n "$sprints" ] || sprints="—"
  {
    echo "# Backlog Index — generated by scripts/backlog.sh index (do not edit by hand)"
    echo
    echo "> Derived from \`backlog.md\` \`## Active\`. Regenerated on every sweep so it"
    echo "> cannot drift. \`/work\` reads this for a 1-glance resolver before the full file."
    echo
    echo "| Bucket | Value |"
    echo "|--------|-------|"
    echo "| open (pickable) | $nopen |"
    echo "| wip (in a sprint) | $nwip |"
    echo "| sprints with wip | $sprints |"
  } > "$INDEX"
  echo "✓ index: regenerated ${INDEX#$ROOT/} ($nopen open · $nwip wip)"
  return 0
}

# ----------------------------------------------------------------------------
# Dry-run planner by default; --apply executes git mv + INDEX rows. Keeps the
# active sprints/ dir to the most-recent --keep N closed sprints.
cmd_archive_sprints() {
  local keep=3 apply=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --keep) keep="${2:-3}"; shift 2 ;;
      --apply) apply=1; shift ;;
      *) die "archive-sprints: unknown arg '$1'" ;;
    esac
  done
  [ -d "$SPRINTS" ] || die "no sprints dir at $SPRINTS"
  # Closed sprint = has a retro.md. Sort by sprint number, keep newest N closed.
  local closed; closed="$(find "$SPRINTS" -maxdepth 2 -name retro.md 2>/dev/null \
    | sed -E "s#$SPRINTS/(S[0-9]+)/retro.md#\1#" | grep -E '^S[0-9]+$' \
    | sort -t S -k2 -n)"
  [ -n "$closed" ] || { echo "✓ archive-sprints: no closed sprints (no retro.md found)"; return 0; }
  local total; total="$(printf '%s\n' "$closed" | grep -c .)"
  local drop; drop=$(( total - keep ))
  if [ "$drop" -le 0 ]; then
    echo "✓ archive-sprints: $total closed sprint(s) ≤ keep=$keep — nothing to roll"
    return 0
  fi
  local candidates; candidates="$(printf '%s\n' "$closed" | head -n "$drop")"
  local idx="$SPRINTS/historical/INDEX.md"
  echo "archive-sprints: roll $drop oldest closed sprint(s) → sprints/historical/ (keep newest $keep)"
  printf '%s\n' "$candidates" | while IFS= read -r s; do
    [ -n "$s" ] || continue
    if [ "$apply" -eq 1 ]; then
      mkdir -p "$SPRINTS/historical"
      if git -C "$ROOT" rev-parse >/dev/null 2>&1; then
        git -C "$ROOT" mv "$SPRINTS/$s" "$SPRINTS/historical/$s" 2>/dev/null || mv "$SPRINTS/$s" "$SPRINTS/historical/$s"
      else
        mv "$SPRINTS/$s" "$SPRINTS/historical/$s"
      fi
      [ -f "$idx" ] || { printf '# Historical Sprints — INDEX\n\n| Sprint | Archived |\n|--------|----------|\n' > "$idx"; }
      echo "| $s | (script) |" >> "$idx"
      echo "  ✓ moved $s → historical/"
    else
      echo "  would move: sprints/$s → sprints/historical/$s"
    fi
  done
  [ "$apply" -eq 0 ] && echo "  (dry-run — re-run with --apply to execute the git mv + INDEX rows)"
  return 0
}

# ----------------------------------------------------------------------------
# Commit-time enforcement = "synced at all times": no drifted/bloated backlog can
# be committed. The hook only fires when docs/project/backlog.md is staged, so it
# never blocks unrelated commits. Override a stuck commit with `git commit --no-verify`.
cmd_install_hook() {
  git -C "$ROOT" rev-parse >/dev/null 2>&1 || die "not a git repo (run from the project root)"
  local hookdir; hookdir="$(git -C "$ROOT" rev-parse --git-path hooks)"
  case "$hookdir" in /*) ;; *) hookdir="$ROOT/$hookdir" ;; esac
  mkdir -p "$hookdir"
  local hook="$hookdir/pre-commit"
  if [ -e "$hook" ] && ! grep -q 'backlog.sh check' "$hook" 2>/dev/null; then
    echo "A pre-commit hook already exists: $hook"
    echo "Add these lines to keep the backlog always-synced:"
    echo '  git diff --cached --name-only | grep -q "^docs/project/backlog.md$" \'
    echo '    && { bash scripts/backlog.sh check || exit 1; }'
    return 0
  fi
  cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
# AI-Workflows backlog hygiene gate (scripts/backlog.sh install-hook).
# Blocks a commit that would leave docs/project/backlog.md drifted or bloated.
# Override (rarely): git commit --no-verify
if git diff --cached --name-only | grep -q '^docs/project/backlog.md$'; then
  bash scripts/backlog.sh check || {
    echo "✗ backlog hygiene gate failed — fix the rows above (or: git commit --no-verify)" >&2
    exit 1
  }
fi
HOOK
  chmod +x "$hook"
  echo "✓ installed pre-commit hook → ${hook#$ROOT/}"
  echo "  Every commit that stages docs/project/backlog.md now runs 'backlog.sh check'."
}

# ----------------------------------------------------------------------------
usage() { sed -n '2,200p' "${BASH_SOURCE[0]}" | grep -E '^#( |$)' | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
  check)           shift; cmd_check "$@" ;;
  verify)          shift; cmd_verify "$@" ;;
  sweep)           shift; cmd_sweep "$@" ;;
  reconcile)       shift; cmd_reconcile "$@" ;;
  index)           shift; cmd_index "$@" ;;
  archive-sprints) shift; cmd_archive_sprints "$@" ;;
  install-hook)    shift; cmd_install_hook "$@" ;;
  ""|-h|--help|help) usage ;;
  *) die "unknown command '$1' (try: check | verify | sweep | reconcile | index | archive-sprints | install-hook)" ;;
esac
