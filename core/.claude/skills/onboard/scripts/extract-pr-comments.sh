#!/usr/bin/env bash
# extract-pr-comments.sh — pull recent PR review comments via the gh CLI
# for `/onboard` Stage 3 "convention sniffer".
#
# Usage:
#   extract-pr-comments.sh [target-dir] [--limit N] [--months N]
#
# Outputs JSONL on stdout — one record per comment, suitable for downstream
# `awk` / `jq` / agent aggregation. Schema:
#   {"pr":123, "author":"alice", "body":"...", "path":"src/x.go",
#    "line":42, "created":"2026-05-01T..."}
#
# Fail-open behavior:
#   - gh CLI missing  → empty output + exit 0
#   - not in a git repo OR no `origin` remote → empty output + exit 0
#   - origin isn't on github.com → empty output + exit 0
#   - gh API auth fails → empty output + exit 0
#
# This script only READS the remote — it never opens / edits / labels PRs.

set -o pipefail

TARGET="${1:-$PWD}"
LIMIT=20
MONTHS=6

shift_args=$#
i=2
while [[ $i -le $shift_args ]]; do
  case "${!i}" in
    --limit)  i=$((i+1)); LIMIT="${!i}" ;;
    --months) i=$((i+1)); MONTHS="${!i}" ;;
  esac
  i=$((i+1))
done

# Pre-flight: required tools.
command -v gh >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

cd "$TARGET" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Determine the owner/repo from the origin remote.
ORIGIN="$(git config --get remote.origin.url 2>/dev/null || echo '')"
[[ -n "$ORIGIN" ]] || exit 0

# Extract owner/repo from various URL shapes:
#   git@github.com:owner/repo.git    → owner/repo
#   https://github.com/owner/repo    → owner/repo
#   https://github.com/owner/repo.git→ owner/repo
case "$ORIGIN" in
  *github.com[:/]*)
    OWNER_REPO="$(echo "$ORIGIN" | sed -E 's#.*github\.com[:/]([^/]+/[^/]+)(\.git)?$#\1#; s/\.git$//')"
    ;;
  *) exit 0 ;;
esac

# Verify gh auth.
gh auth status >/dev/null 2>&1 || exit 0

SINCE_ISO="$(date -u -v"-${MONTHS}m" +%Y-%m-%d 2>/dev/null || \
             date -u -d "${MONTHS} months ago" +%Y-%m-%d 2>/dev/null || \
             echo '2020-01-01')"

# 1. List recent merged PRs.
PRS="$(gh pr list --repo "$OWNER_REPO" \
        --state merged --limit "$LIMIT" \
        --json number,mergedAt,title \
        --jq ".[] | select(.mergedAt > \"${SINCE_ISO}\") | .number" 2>/dev/null)"

[[ -z "$PRS" ]] && exit 0

# 2. For each PR, fetch review comments (line comments) via gh api.
#    Endpoint: /repos/{owner}/{repo}/pulls/{pr}/comments
while IFS= read -r pr; do
  [[ -z "$pr" ]] && continue
  gh api "repos/${OWNER_REPO}/pulls/${pr}/comments" --paginate 2>/dev/null \
    | jq -c --argjson pr "$pr" '
        .[]? |
        {pr: $pr,
         author: .user.login,
         body: .body,
         path: .path,
         line: (.line // .original_line // null),
         created: .created_at}
      ' 2>/dev/null
done <<< "$PRS"

exit 0
