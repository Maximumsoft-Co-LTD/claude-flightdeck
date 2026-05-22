#!/usr/bin/env bash
# detect-topology.sh — repo topology probe for `/onboard` Stage 0.
#
# Usage:
#   detect-topology.sh [target-dir]        (defaults to $PWD)
#
# Outputs a single JSON object on stdout. Schema:
#   {
#     "type": "single-go" | "single-node" | "single-python" | "single-other"
#           | "monorepo"  | "meta-repo"   | "empty",
#     "languages": ["go", "typescript", ...],
#     "areas":     ["backend", "frontend", "k8s", ...],
#     "has_submodules":    true|false,
#     "existing_install":  true|false,
#     "manifest":          "<path>" | null,
#     "sibling_installs":  ["../service-a", "../service-b", ...],
#     "presets_recommended": ["go-hex", "nextjs-fsd", ...],
#     "arch_fit":          {"go-hex":"high|low", ...},  // does the repo actually follow each preset's architecture?
#     "git_repo":         true|false,
#     "git_commits":      <int>
#   }
#
# Read-only. Never modifies the target. Fail-open: if a probe errors,
# the corresponding field is `null` / `false` / `[]`, not a hard exit.

set -o pipefail

TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  printf '{"error": "target not found", "target": "%s"}\n' "${1:-}"
  exit 0
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- language detection ----------
declare -a LANGS=()
declare -a AREAS=()
declare -a SIBLINGS=()
declare -a PRESETS=()
[[ -f "$TARGET/go.mod" ]] && LANGS+=("go")
find "$TARGET" -maxdepth 3 -name 'go.mod' -not -path '*/vendor/*' 2>/dev/null \
  | head -1 | grep -q . && [[ ! -f "$TARGET/go.mod" ]] && LANGS+=("go")

if [[ -f "$TARGET/package.json" ]] || find "$TARGET" -maxdepth 3 -name 'package.json' -not -path '*/node_modules/*' 2>/dev/null | head -1 | grep -q .; then
  # Distinguish ts vs js by presence of tsconfig.json
  if find "$TARGET" -maxdepth 3 -name 'tsconfig.json' 2>/dev/null | head -1 | grep -q .; then
    LANGS+=("typescript")
  else
    LANGS+=("javascript")
  fi
fi

[[ -f "$TARGET/pyproject.toml" ]] || [[ -f "$TARGET/setup.py" ]] || [[ -f "$TARGET/requirements.txt" ]] && LANGS+=("python")
[[ -f "$TARGET/Cargo.toml" ]] && LANGS+=("rust")
[[ -f "$TARGET/pom.xml" ]] || [[ -f "$TARGET/build.gradle" ]] || [[ -f "$TARGET/build.gradle.kts" ]] && LANGS+=("java")
[[ -f "$TARGET/Gemfile" ]] && LANGS+=("ruby")

# De-dup
LANGS=($(printf '%s\n' "${LANGS[@]}" | awk '!seen[$0]++'))

# ---------- area detection (monorepo signal) ----------
# An "area" is a top-level dir with its own manifest (go.mod / package.json /
# pyproject.toml / Cargo.toml / Chart.yaml / values.yaml).
shopt -s nullglob
for d in "$TARGET"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  case "$name" in
    node_modules|vendor|.git|.claude|target|dist|build|venv|.venv|__pycache__) continue ;;
  esac
  if [[ -f "$d/go.mod" || -f "$d/package.json" || -f "$d/pyproject.toml" \
     || -f "$d/Cargo.toml" || -f "$d/Chart.yaml" || -f "$d/Makefile" \
     || -f "$d/Dockerfile" || -f "$d/values.yaml" ]]; then
    AREAS+=("$name")
  fi
done

# ---------- submodule detection ----------
HAS_SUBMODULES=false
[[ -f "$TARGET/.gitmodules" ]] && HAS_SUBMODULES=true

# ---------- existing install + sibling installs ----------
EXISTING_INSTALL=false
MANIFEST="null"
if [[ -f "$TARGET/.ai-workflows/manifest.json" ]]; then
  EXISTING_INSTALL=true
  MANIFEST="\"$TARGET/.ai-workflows/manifest.json\""
fi

# Look ONE level up for sibling installs (../service-a/.ai-workflows/...).
PARENT="$(dirname "$TARGET")"
if [[ "$PARENT" != "$TARGET" && -d "$PARENT" ]]; then
  for sib in "$PARENT"/*/; do
    [[ "$(basename "$sib")" == "$(basename "$TARGET")" ]] && continue
    [[ -f "$sib.ai-workflows/manifest.json" ]] && SIBLINGS+=("../$(basename "$sib")")
  done
fi

# ---------- topology classification ----------
N_AREAS=${#AREAS[@]}
N_LANGS=${#LANGS[@]}
if [[ $N_AREAS -gt 1 ]]; then
  if [[ "$HAS_SUBMODULES" == "true" ]]; then
    TYPE="meta-repo"
  else
    TYPE="monorepo"
  fi
elif [[ $N_LANGS -eq 0 && $N_AREAS -eq 0 ]]; then
  TYPE="empty"
elif [[ $N_LANGS -eq 1 ]]; then
  case "${LANGS[0]}" in
    go)                    TYPE="single-go" ;;
    typescript|javascript) TYPE="single-node" ;;
    python)                TYPE="single-python" ;;
    *)                     TYPE="single-other" ;;
  esac
else
  # Multi-language but no clear area dirs — treat as single (mixed) for now.
  TYPE="single-other"
fi

# ---------- preset recommendation ----------
LANGS_JOINED=" ${LANGS[*]:-} "
AREAS_JOINED=" ${AREAS[*]:-} "

[[ "$LANGS_JOINED" == *" go "* ]] && PRESETS+=("go-hex")
if [[ "$LANGS_JOINED" == *" typescript "* || "$LANGS_JOINED" == *" javascript "* ]]; then
  # Next.js signal? Vue signal?
  if grep -lq '"next"' "$TARGET"/package.json "$TARGET"/*/package.json 2>/dev/null; then
    PRESETS+=("nextjs-fsd")
  fi
  if grep -lq '"vue"' "$TARGET"/package.json "$TARGET"/*/package.json 2>/dev/null; then
    PRESETS+=("vue-pinia")
  fi
fi
[[ "$AREAS_JOINED" == *" k8s "* || "$AREAS_JOINED" == *" charts "* \
   || "$AREAS_JOINED" == *" deploy "* || -f "$TARGET/Chart.yaml" ]] && PRESETS+=("k8s-helm")
PRESETS=($(printf '%s\n' "${PRESETS[@]}" | awk 'NF && !seen[$0]++'))

# ---------- architecture-fit probe ----------
# A preset is recommended on a *language* signal, which does NOT prove the
# project follows the preset's architecture. Probe each recommended preset's
# signature dirs/tooling → high|low, so /onboard can warn before the wrong
# preset is confirmed (e.g. go.mod present but no hexagonal layout).
arch_fit_for() {
  case "$1" in
    go-hex)
      if find "$TARGET" -maxdepth 4 -type d \( -path '*/internal/domain' -o -path '*/internal/ports' -o -path '*/internal/usecase' \) 2>/dev/null | head -1 | grep -q . \
         || grep -rsq 'verify-isolation' "$TARGET"/Makefile "$TARGET"/*/Makefile 2>/dev/null; then
        echo high; else echo low; fi ;;
    nextjs-fsd)
      if { find "$TARGET" -maxdepth 4 -type d -path '*/features' 2>/dev/null | head -1 | grep -q . \
           && find "$TARGET" -maxdepth 4 -type d -path '*/entities' 2>/dev/null | head -1 | grep -q .; } \
         || grep -rsq 'eslint-plugin-boundaries' "$TARGET"/package.json "$TARGET"/*/package.json 2>/dev/null; then
        echo high; else echo low; fi ;;
    vue-pinia)
      if grep -rsq '"pinia"' "$TARGET"/package.json "$TARGET"/*/package.json 2>/dev/null \
         && find "$TARGET" -maxdepth 4 -type d -name stores 2>/dev/null | head -1 | grep -q .; then
        echo high; else echo low; fi ;;
    k8s-helm)
      if find "$TARGET" -maxdepth 3 -name 'Chart.yaml' 2>/dev/null | head -1 | grep -q .; then
        echo high; else echo low; fi ;;
    *) echo unknown ;;
  esac
}

ARCH_FIT_JSON='{'
af_first=1
for p in "${PRESETS[@]:-}"; do
  [[ -n "$p" ]] || continue
  [[ $af_first -eq 1 ]] || ARCH_FIT_JSON+=','
  ARCH_FIT_JSON+="\"$p\":\"$(arch_fit_for "$p")\""
  af_first=0
done
ARCH_FIT_JSON+='}'

# ---------- git repo state ----------
GIT_REPO=false
GIT_COMMITS=0
if [[ -d "$TARGET/.git" ]] || git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_REPO=true
  GIT_COMMITS="$(git -C "$TARGET" rev-list --count HEAD 2>/dev/null || echo 0)"
fi

# ---------- JSON emit (no jq required) ----------
json_array() {
  # $@ items; emits ["a","b",...] with NO trailing comma. Empty → []
  # Skip empty-string elements (an unset / expanded-empty array passed
  # via "${arr[@]:-}" can show up as a single "" arg — that's not a
  # real element).
  local first=1; printf '['
  for x in "$@"; do
    [[ -n "$x" ]] || continue
    [[ $first -eq 1 ]] || printf ','
    printf '"%s"' "${x//\"/\\\"}"
    first=0
  done
  printf ']'
}

printf '{'
printf '"type":"%s",' "$TYPE"
printf '"languages":'; json_array "${LANGS[@]:-}"; printf ','
printf '"areas":';     json_array "${AREAS[@]:-}"; printf ','
printf '"has_submodules":%s,' "$HAS_SUBMODULES"
printf '"existing_install":%s,' "$EXISTING_INSTALL"
printf '"manifest":%s,' "$MANIFEST"
printf '"sibling_installs":'; json_array "${SIBLINGS[@]:-}"; printf ','
printf '"presets_recommended":'; json_array "${PRESETS[@]:-}"; printf ','
printf '"arch_fit":%s,' "$ARCH_FIT_JSON"
printf '"git_repo":%s,' "$GIT_REPO"
printf '"git_commits":%s' "$GIT_COMMITS"
printf '}\n'
