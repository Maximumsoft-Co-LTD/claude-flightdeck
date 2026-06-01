#!/usr/bin/env bash
# validate-skills.sh — structural + link validator for the template's OWN
# control-plane sources (core/.claude/skills, core/.claude/agents) + a
# mis-pathed-link sweep across core/.
#
# Why this exists
# ---------------
# The SHIPPED workflow (core/.github/workflows/ai-workflow-validation.yml)
# validates an *installed* project's rendered .claude/ — but nothing validated
# the template's OWN core/ sources. So a hand-authored skill could ship a
# missing `## Token budget`, a name that drifts from its directory, or a rotted
# relative cross-link with no gate catching it. This is that gate.
#
# It is a REPO-ONLY dev tool: it lives at the template repo root and is never
# copied into a consumer project (only core/ + presets/ ship). It enforces the
# four skill-authoring rules mechanically (see core/docs/setup/skill-authoring.md).
#
# Design
# ------
# - Dependency-free (pure bash; runs on macOS bash 3.2 + CI bash 5).
# - `.tmpl`-aware: a link to `x.md` is satisfied by `x.md` OR `x.md.tmpl`
#   (the installer renders + strips the .tmpl suffix at install time).
# - metavar-aware: link targets containing `{{PLACEHOLDER}}` or `<META>`
#   (e.g. `sprint-S<N>`, `D<NNN>-<slug>.md`) are path *patterns*, not links.
# - PRECISION over recall on links: a broken link is reported as a FAIL only
#   when its basename exists *elsewhere* in core/ — i.e. a real control-plane
#   doc that was mis-pathed (wrong `../` depth / moved file). A link to a
#   basename that exists nowhere is illustrative/example content (sample output
#   in references/, example paths in a template) and is skipped + counted, not
#   failed. This keeps the gate high-signal instead of drowning in example noise.
# - FAIL (exit 1): missing name/description; missing `## Token budget` (skills);
#   skill name != directory; a mis-pathed cross-link.
# - WARN (exit 0): SKILL.md over the size budget; a description that looks
#   summary-style instead of trigger/symptom-based (CSO). Warnings never fail CI.
#
# Usage:  scripts/validate-skills.sh                  # defaults to core/
#         scripts/validate-skills.sh <claude-dir> <link-root>

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="${1:-$ROOT/core/.claude}"
LINK_ROOT="${2:-$ROOT/core}"
SIZE_BUDGET=250

fail=0; warn=0; skipped=0
FAILS=(); WARNS=()
add_fail() { FAILS+=("$1"); fail=$((fail+1)); }
add_warn() { WARNS+=("$1"); warn=$((warn+1)); }

# Resolve a relative markdown link from a file's dir → echo "ok" | "broken".
check_link() {
  local fromdir="$1" target="$2"
  target="${target%%#*}"        # drop #anchor
  target="${target%% *}"        # drop ` "title"` suffix
  [ -z "$target" ] && { echo ok; return; }            # pure anchor
  case "$target" in
    http://*|https://*|mailto:*|/*) echo ok; return;;   # external / absolute
    *'{{'*|*'<'*) echo ok; return;;                     # placeholder / metavar pattern
  esac
  local r="$fromdir/$target"
  if [ -e "$r" ] || [ -e "$r.tmpl" ]; then echo ok; else echo broken; fi
}

# ---- structural checks: skills ----
for skdir in "$CLAUDE_DIR"/skills/*/; do
  [ -d "$skdir" ] || continue
  sk="$(basename "$skdir")"
  f="$skdir/SKILL.md"
  [ -f "$f" ] || { add_fail "skills/$sk: no SKILL.md"; continue; }
  name="$(grep -m1 -E '^name:' "$f" | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]*$//; s/^["'"'"']//; s/["'"'"']$//')"
  [ -n "$name" ] || add_fail "skills/$sk: missing 'name:' frontmatter"
  grep -m1 -qE '^description:[[:space:]]*\S' "$f" || add_fail "skills/$sk: missing 'description:' frontmatter"
  { [ -z "$name" ] || [ "$name" = "$sk" ]; } || add_fail "skills/$sk: name '$name' != directory '$sk'"
  grep -qE '^##[[:space:]]+Token budget' "$f" || add_fail "skills/$sk: missing '## Token budget' section"
  lc="$(wc -l < "$f" | tr -d ' ')"
  [ "$lc" -le "$SIZE_BUDGET" ] || add_warn "skills/$sk: SKILL.md is $lc lines (> $SIZE_BUDGET — split rarely-used material into references/)"
  desc="$(grep -m1 -E '^description:' "$f")"
  echo "$desc" | grep -qiE "use when|when the user|/[a-z]|after |before |symptom|flaky|fails|returns|gone wrong|whenever" \
    || add_warn "skills/$sk: description may be summary-style, not trigger/symptom-based (CSO)"
done

# ---- structural checks: agents ----
for af in "$CLAUDE_DIR"/agents/*.md; do
  [ -f "$af" ] || continue
  an="$(basename "$af")"
  grep -m1 -qE '^name:[[:space:]]*\S' "$af" || add_fail "agents/$an: missing 'name:' frontmatter"
  grep -m1 -qE '^description:[[:space:]]*\S' "$af" || add_fail "agents/$an: missing 'description:' frontmatter"
done

# ---- mis-pathed-link sweep across core/ markdown ----
# Emit FAIL:: (mis-pathed real doc) and SKIP:: (illustrative/example) lines from
# the subshell; tally them in the main shell.
linkscan="$(
  find "$LINK_ROOT" -type f \( -name '*.md' -o -name '*.md.tmpl' \) 2>/dev/null | while IFS= read -r mf; do
    fromdir="$(dirname "$mf")"
    grep -oE '\]\([^)]+\)' "$mf" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r lnk; do
      [ "$(check_link "$fromdir" "$lnk")" = broken ] || continue
      t="${lnk%%#*}"; t="${t%% *}"; base="$(basename "$t")"
      [ "$base" = "README.md" ] && { echo "SKIP::${mf#$ROOT/} -> $lnk"; continue; }
      if find "$LINK_ROOT" -type f \( -name "$base" -o -name "$base.tmpl" \) 2>/dev/null | grep -q .; then
        echo "FAIL::${mf#$ROOT/} -> $lnk"
      else
        echo "SKIP::${mf#$ROOT/} -> $lnk"
      fi
    done
  done
)"
while IFS= read -r line; do
  case "$line" in
    FAIL::*) add_fail "mis-pathed link: ${line#FAIL::}";;
    SKIP::*) skipped=$((skipped+1));;
  esac
done <<< "$linkscan"

# ---- report ----
echo "── validate-skills ──"
echo "claude dir: ${CLAUDE_DIR#$ROOT/}    link root: ${LINK_ROOT#$ROOT/}"
[ "$skipped" -gt 0 ] && echo "(skipped $skipped link(s) to example/non-existent paths — illustrative content)"
if [ "$warn" -gt 0 ]; then
  echo
  echo "⚠  $warn warning(s):"
  for w in "${WARNS[@]}"; do echo "   - $w"; done
fi
if [ "$fail" -gt 0 ]; then
  echo
  echo "✗  $fail failure(s):"
  for x in "${FAILS[@]}"; do echo "   - $x"; done
  echo
  echo "FAILED"
  exit 1
fi
echo
echo "✓  structural checks pass; no mis-pathed cross-links — $warn warning(s)"
