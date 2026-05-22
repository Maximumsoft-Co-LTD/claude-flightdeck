#!/usr/bin/env bash
# mine-git-history.sh — extract recurring-fix patterns from git log for
# `/onboard` Stage 3 (Pattern mining).
#
# Usage:
#   mine-git-history.sh [target-dir] [--months N] [--limit N]
#                       [--format jsonl|markdown]
#
# Reads the target's git log for fix-class commits (fix:, revert:, hotfix:,
# bugfix:, "fix " subject prefix, "bug " subject prefix), buckets them by
# the most-touched files + by the most-frequent message keywords, and
# outputs candidate A-rule signals for `onboarding-engineer` to draft from.
#
# Output (default = jsonl, one record per signal):
#   {"type":"hotspot",  "path":"src/handler.go", "fix_count":12, "first":"2025-08-01", "last":"2026-04-22"}
#   {"type":"keyword",  "keyword":"deadlock",    "count":4,      "sample_subjects":["fix: db deadlock", ...]}
#   {"type":"reverter", "path":"src/cache.go",   "revert_count":3, "last":"2026-02-11"}
#
# Read-only. No git fetch / no git pull. Fail-open: no git → empty output + exit 0.

set -o pipefail

TARGET="${1:-$PWD}"
MONTHS=6
LIMIT=200
FORMAT="jsonl"

shift_args=$#
i=2
while [[ $i -le $shift_args ]]; do
  case "${!i}" in
    --months)  i=$((i+1)); MONTHS="${!i}" ;;
    --limit)   i=$((i+1)); LIMIT="${!i}" ;;
    --format)  i=$((i+1)); FORMAT="${!i}" ;;
  esac
  i=$((i+1))
done

cd "$TARGET" 2>/dev/null || { echo "{}"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || exit 0   # not a git repo → silent
git log -1 >/dev/null 2>&1 || exit 0                # no commits → silent

SINCE="$MONTHS months ago"

# Collect fix-class commit SHAs (subject-pattern match).
# We accept conventional-commit prefixes + freeform "fix " / "bug ".
FIX_PATTERN='^(fix|revert|hotfix|bugfix)(\(|:|$)|^fix |^bug |^Fix |^Revert |^Hotfix '
SHAS="$(git log --since="$SINCE" --pretty='%H%x09%s' 2>/dev/null \
        | grep -E "$(printf '\t')(${FIX_PATTERN})" \
        | head -n "$LIMIT" \
        | cut -f1)"

[[ -z "$SHAS" ]] && exit 0

# ---------- Signal 1: hotspot files (files touched by multiple fix commits) ----------
TMPDIR_M="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_M"' EXIT

# files-per-sha
while IFS= read -r sha; do
  [[ -z "$sha" ]] && continue
  git show --name-only --pretty=format: "$sha" 2>/dev/null \
    | grep -v '^$' \
    | while IFS= read -r f; do
        printf '%s\t%s\n' "$f" "$sha" >> "$TMPDIR_M/file-sha.tsv"
      done
done <<< "$SHAS"

# Hotspots: files that appear in ≥ 3 fix commits (high signal).
if [[ -s "$TMPDIR_M/file-sha.tsv" ]]; then
  awk -F'\t' '{count[$1]++} END {for (f in count) if (count[f] >= 3) print count[f]"\t"f}' "$TMPDIR_M/file-sha.tsv" \
    | sort -rn \
    | head -20 \
    | while IFS=$'\t' read -r count path; do
        first="$(git log --since="$SINCE" --diff-filter=M --pretty=%cs -- "$path" 2>/dev/null | tail -1)"
        last="$(git log --since="$SINCE"  --diff-filter=M --pretty=%cs -- "$path" 2>/dev/null | head -1)"
        printf '{"type":"hotspot","path":"%s","fix_count":%s,"first":"%s","last":"%s"}\n' \
               "$path" "$count" "$first" "$last"
      done
fi

# ---------- Signal 2: keyword frequency in fix subjects ----------
# Strip noise words; collect tokens that recur ≥ 3 times.
STOP='the|a|an|in|on|to|for|of|and|or|by|is|are|with|from|fix|fixed|bug|revert|hotfix|bugfix|broken|issue|err|error|errors|case|cases|use|using|when|where|that|this'

git log --since="$SINCE" --pretty='%s' 2>/dev/null \
  | grep -E "^(${FIX_PATTERN})" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -c 'a-z0-9' '\n' \
  | awk -v stop="$STOP" '
      BEGIN { n=split(stop, sw, "|"); for (i=1;i<=n;i++) s[sw[i]]=1 }
      length($0) >= 4 && !($0 in s) { c[$0]++ }
      END { for (k in c) if (c[k] >= 3) print c[k]"\t"k }' \
  | sort -rn | head -15 \
  | while IFS=$'\t' read -r count keyword; do
      # 2-3 sample subjects per keyword for context.
      samples="$(git log --since="$SINCE" --pretty='%s' 2>/dev/null \
                 | grep -iE "\b${keyword}\b" \
                 | head -3 \
                 | sed 's/"/\\"/g' \
                 | awk '{printf "\"%s\"", $0; if(NR<3) printf ","}')"
      printf '{"type":"keyword","keyword":"%s","count":%s,"sample_subjects":[%s]}\n' \
             "$keyword" "$count" "$samples"
    done

# ---------- Signal 3: revert hotspots (paths whose changes were reverted) ----------
git log --since="$SINCE" --pretty='%H' --grep='^Revert\|^revert' 2>/dev/null \
  | head -50 \
  | while IFS= read -r sha; do
      git show --name-only --pretty=format: "$sha" 2>/dev/null \
        | grep -v '^$' \
        | while IFS= read -r f; do printf '%s\n' "$f"; done
    done \
  | sort | uniq -c | sort -rn \
  | awk '$1 >= 2 { print $1"\t"$2 }' \
  | head -10 \
  | while IFS=$'\t' read -r count path; do
      last="$(git log --since="$SINCE" --grep='^Revert' --diff-filter=M --pretty=%cs -- "$path" 2>/dev/null | head -1)"
      printf '{"type":"reverter","path":"%s","revert_count":%s,"last":"%s"}\n' \
             "$path" "$count" "$last"
    done

exit 0
