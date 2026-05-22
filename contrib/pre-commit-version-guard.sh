#!/usr/bin/env bash
# AI-Workflows template repo — pre-commit guard.
#
# Refuses commits that touch core/ or presets/ without bumping VERSION
# (or staging it). Catches the silent-drift class: someone adds a rule
# to core/.claude/rules/ and forgets to bump v0.2.x → v0.2.y, so
# installs done after the change still report the same version as
# installs done before — drift detection breaks.
#
# Install (template repo maintainers only — not shipped to install
# targets):
#   ln -s "$(pwd)/contrib/pre-commit-version-guard.sh" .git/hooks/pre-commit
#   # or via pre-commit framework:
#   pre-commit install
#
# Skip for a single commit (when you know what you're doing):
#   AIWF_SKIP_VERSION_GUARD=1 git commit -m '...'

set -euo pipefail

# Allow operators to skip in emergencies.
if [[ "${AIWF_SKIP_VERSION_GUARD:-0}" == "1" ]]; then
  exit 0
fi

# Find the repo root (script may be invoked from anywhere in the tree).
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# What changed in this commit (staged only).
STAGED="$(git diff --cached --name-only --diff-filter=ACMRT)"
[[ -n "$STAGED" ]] || exit 0  # nothing staged → nothing to guard

# Did any file under core/ or presets/ change?
TEMPLATE_CHANGED=0
while IFS= read -r f; do
  case "$f" in
    core/*|presets/*) TEMPLATE_CHANGED=1; break ;;
  esac
done <<< "$STAGED"

[[ $TEMPLATE_CHANGED -eq 1 ]] || exit 0

# Template content changed. Was VERSION staged too?
if grep -qxF 'VERSION' <<< "$STAGED"; then
  exit 0
fi

# Bail with a clear message + the recovery path.
cat >&2 <<EOF
══════════════════════════════════════════════════════════════════════
  pre-commit guard: VERSION not bumped
══════════════════════════════════════════════════════════════════════
This commit changes files under core/ or presets/, but VERSION wasn't
staged. Installs that hit this commit will report the OLD version,
breaking install.sh diff drift detection.

Fix one of:

  1. Bump VERSION (patch for fixes, minor for features, major for
     breaking changes — semver), then re-stage:

        \$ echo "0.2.1" > VERSION  # adjust to the right bump
        \$ git add VERSION

  2. If this is genuinely a no-behavior commit (whitespace, comment
     typo) — bypass with:

        \$ AIWF_SKIP_VERSION_GUARD=1 git commit ...

  3. If a CI / release script will bump VERSION later — bypass with
     the same env var, and ensure CI does the bump on merge.

Staged template files:
$(echo "$STAGED" | grep -E '^(core|presets)/' | sed 's/^/    /')

══════════════════════════════════════════════════════════════════════
EOF
exit 1
