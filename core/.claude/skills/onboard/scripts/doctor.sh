#!/usr/bin/env bash
# doctor.sh — post-install health check for an AI-Workflows control plane.
#
# Usage:
#   doctor.sh [target-dir]        (defaults to $PWD)
#
# Read-only. Inspects an INSTALLED project (not the template repo) and
# reports per-check PASS / WARN / FAIL with a one-line reason each, then a
# summary. Exit code: 0 if no FAIL, 1 if any FAIL (so CI / automation can
# gate on it). WARN never fails the exit code.
#
# Checks:
#   1. Structure        — required files + dirs present
#   2. Placeholders     — no un-rendered template placeholders left in the surface
#   3. Plugins          — pr-review-toolkit (required), superpowers (recommended)
#   4. Code style       — code-style.md populated (not still the install stub)
#   5. Brain hot path   — brain-hot.md present + carries the A001..A010 block
#   6. Spec scaffolding — STATUS / backlog / sprints / retros / designs present
#   7. Settings         — .claude/settings.json rendered

set -o pipefail

TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  printf 'doctor: target not found: %s\n' "${1:-}"
  exit 1
}

PASS=0; WARN=0; FAIL=0
ok()   { printf '  [PASS] %s\n' "$1"; PASS=$((PASS+1)); }
warn() { printf '  [WARN] %s\n' "$1"; WARN=$((WARN+1)); }
bad()  { printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL+1)); }

printf 'AI-Workflows doctor — %s\n\n' "$TARGET"

# Bail early if this clearly isn't an installed control plane.
if [[ ! -d "$TARGET/.claude" || ! -f "$TARGET/CLAUDE.md" ]]; then
  bad "no .claude/ + CLAUDE.md here — run doctor from an installed project root (or pass the path)"
  printf '\nSummary: %d pass · %d warn · %d fail\n' "$PASS" "$WARN" "$FAIL"
  exit 1
fi

# ---------- 1. Structure ----------
printf '1. Structure\n'
for f in \
  "CLAUDE.md" \
  ".claude/rules/brain-hot.md" \
  ".claude/rules/agent-pre-task-ritual.md" \
  ".claude/agents/backend-engineer.md" \
  ".claude/agents/frontend-engineer.md" \
  ".claude/agents/senior-tech-lead.md"; do
  if [[ -e "$TARGET/$f" ]]; then ok "$f present"; else bad "$f MISSING"; fi
done
[[ -d "$TARGET/.claude/skills" ]] && ok ".claude/skills/ present" || bad ".claude/skills/ MISSING"

# ---------- 2. Placeholder leaks ----------
# Pattern is written with escaped braces so the installer's own render pass
# does NOT treat this script as a template needing substitution.
printf '2. Placeholder leaks\n'
LEAKS=""
for root in "$TARGET/.claude" "$TARGET/docs" "$TARGET/CLAUDE.md" "$TARGET/README.md"; do
  [[ -e "$root" ]] || continue
  hits="$(grep -rIlE '\{\{[A-Z_]{2,}\}\}' "$root" 2>/dev/null)" || true
  [[ -n "$hits" ]] && LEAKS+="$hits"$'\n'
done
LEAKS="$(printf '%s' "$LEAKS" | sed '/^$/d')"
if [[ -z "$LEAKS" ]]; then
  ok "no un-rendered placeholders in .claude/ · docs/ · CLAUDE.md · README.md"
else
  n="$(printf '%s\n' "$LEAKS" | wc -l | tr -d ' ')"
  bad "$n file(s) still contain un-rendered placeholders — re-run install with a full config:"
  printf '%s\n' "$LEAKS" | sed "s|^$TARGET/|         · |"
fi

# ---------- 3. Plugins ----------
printf '3. Plugins\n'
PLUGINS_JSON="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
have_plugin() {  # $1 = plugin short name (without @marketplace)
  [[ -f "$PLUGINS_JSON" ]] || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -e --arg p "$1" '(.plugins // {}) | keys[] | select(startswith($p + "@"))' "$PLUGINS_JSON" >/dev/null 2>&1
  else
    grep -q "\"$1@" "$PLUGINS_JSON" 2>/dev/null
  fi
}
if [[ -f "$PLUGINS_JSON" ]]; then
  have_plugin pr-review-toolkit \
    && ok "pr-review-toolkit installed (Gate 4b reviewers)" \
    || bad "pr-review-toolkit MISSING — Gate 4b degrades to feature-dev:code-reviewer. Install via /plugin → claude-plugins-official"
  have_plugin superpowers \
    && ok "superpowers installed (TDD / verify / debug skills)" \
    || warn "superpowers not installed — A-rule skill invocations no-op; inline disciplines still apply. Install via /plugin"
else
  warn "no installed_plugins.json at $PLUGINS_JSON — can't confirm plugins (set CLAUDE_CONFIG_DIR if relocated)"
fi

# ---------- 4. Code style ----------
printf '4. Code style\n'
CS="$TARGET/.claude/rules/code-style.md"
if [[ ! -f "$CS" ]]; then
  warn "code-style.md absent — run /onboard to generate the project's learned conventions"
elif grep -qiE '\*\*stub|populate this by running|<!-- *stub|TODO: *fill' "$CS"; then
  warn "code-style.md is still the install stub — run /onboard to populate it (engineers read this)"
else
  ok "code-style.md populated"
fi

# ---------- 5. Brain hot path ----------
printf '5. Brain hot path\n'
BH="$TARGET/.claude/rules/brain-hot.md"
if [[ ! -f "$BH" ]]; then
  bad "brain-hot.md MISSING — the always-loaded rule set is gone"
elif grep -q 'A001' "$BH" && grep -q 'A010' "$BH"; then
  ok "brain-hot.md carries the A001..A010 always-apply block"
else
  warn "brain-hot.md present but the A001..A010 block looks incomplete"
fi

# ---------- 6. Spec scaffolding ----------
printf '6. Spec scaffolding\n'
for f in \
  "docs/spec/STATUS.md" \
  "docs/spec/backlog.md"; do
  if [[ -f "$TARGET/$f" ]]; then ok "$f present"; else warn "$f absent — /onboard or first sprint creates it"; fi
done
for d in \
  "docs/spec/sprints" \
  "docs/spec/retros" \
  "docs/designs"; do
  if [[ -d "$TARGET/$d" ]]; then ok "$d/ present"; else warn "$d/ absent — created on first sprint"; fi
done

# ---------- 7. Settings ----------
printf '7. Settings\n'
if [[ -f "$TARGET/.claude/settings.json" ]]; then
  if command -v jq >/dev/null 2>&1; then
    jq -e . "$TARGET/.claude/settings.json" >/dev/null 2>&1 \
      && ok ".claude/settings.json present + valid JSON" \
      || bad ".claude/settings.json present but is NOT valid JSON"
  else
    ok ".claude/settings.json present (install jq to validate JSON)"
  fi
else
  warn ".claude/settings.json absent — profile may not have rendered; re-run install with --profile"
fi

# ---------- Summary ----------
printf '\nSummary: %d pass · %d warn · %d fail\n' "$PASS" "$WARN" "$FAIL"
if [[ $FAIL -gt 0 ]]; then
  printf 'Result: NOT READY — resolve the FAIL items above.\n'
  exit 1
elif [[ $WARN -gt 0 ]]; then
  printf 'Result: READY (with warnings) — review WARN items; most clear after /onboard.\n'
  exit 0
else
  printf 'Result: READY — control plane is healthy.\n'
  exit 0
fi
