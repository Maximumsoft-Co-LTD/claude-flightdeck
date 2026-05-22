#!/usr/bin/env bash
# AI-Workflows installer — copies the control-plane template into a target project.
#
# Usage:
#   ./install.sh <target-dir> [--profile P] [--preset name1,name2] [--brain-path PATH] [--config FILE] [--dry-run] [--force]
#   ./install.sh diff <target-dir>          # report version + file drift vs template
#   ./install.sh --version                  # print template version and exit
#
# --profile selects the permission/hook foundation rendered to
# .claude/settings.json (see docs/setup/permission-profiles.md):
#   restricted  — read-only Bash allow-list (audit / pair-programming sessions)
#   standard    — common dev tools (go/make/git/gh/docker/npm/curl/jq + read-only)  [DEFAULT]
#   permissive  — Bash(*) with a deny-list of obviously destructive shapes
#
# Examples:
#   ./install.sh ~/code/my-new-service
#   ./install.sh ./target --profile restricted
#   ./install.sh ./target --preset k8s-helm --brain-path ~/Obsidian/brain
#   ./install.sh ./target --config template.config --force
#   ./install.sh ./target --dry-run                 # show what would happen
#   ./install.sh diff ~/code/my-new-service         # drift report
#
# Vars substituted in *.tmpl files (Mustache-style {{NAME}}):
#   PROJECT_NAME, PROJECT_SLUG, AGENT_PREFIX, TECH_STACK_DESC, BRAIN_PATH, TASK_ID_PREFIX
#
# Behavior: copies core/ then merges selected presets/* over the same paths,
# then renders placeholders and strips the .tmpl suffix. Backs up any pre-existing
# .claude/ or CLAUDE.md to .claude.backup-<timestamp>/ unless --force is set.
# After install, writes $TARGET/.ai-workflows/manifest.json (version, install
# date, presets, placeholder names, template source_commit) for drift control.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read template version from the canonical VERSION file (single source of
# truth). Empty if the file is missing — the installer still works but no
# manifest version field will be written.
AIWF_VERSION=""
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
  AIWF_VERSION="$(head -n1 "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')"
fi

TARGET=""
PRESETS=""
BRAIN_PATH=""
CONFIG_FILE=""
DRY_RUN=0
FORCE=0
SUBCOMMAND=""
PROFILE="standard"   # restricted | standard | permissive

PROJECT_NAME=""
PROJECT_SLUG=""
AGENT_PREFIX=""
TECH_STACK_DESC=""
TASK_ID_PREFIX=""

die()  { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
note() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[32m  ok\033[0m  %s\n' "$*"; }

usage() {
  sed -n '2,22p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

# ---------- arg parse ----------
# Subcommand detection (must be first positional arg if present).
# Currently supported: `diff <target>` — compare installed manifest vs
# current template. Otherwise the first positional is treated as the
# install target as before.
if [[ "${1:-}" == "diff" ]]; then
  SUBCOMMAND="diff"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --version)
      printf 'AI-Workflows v%s\n' "${AIWF_VERSION:-unknown}"
      exit 0
      ;;
    --preset)        PRESETS="$2"; shift 2 ;;
    --profile)       PROFILE="$2"; shift 2 ;;
    --brain-path)    BRAIN_PATH="$2"; shift 2 ;;
    --config)        CONFIG_FILE="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=1; shift ;;
    --force)         FORCE=1; shift ;;
    --) shift; break ;;
    -*) die "unknown flag: $1 (try --help)" ;;
    *)
      [[ -z "$TARGET" ]] || die "unexpected positional arg: $1"
      TARGET="$1"; shift ;;
  esac
done

# ---------- diff subcommand ----------
# Reports drift between a target's `.ai-workflows/manifest.json` and the
# current template. Lists files that have been modified since the
# manifest's recorded `source_commit`. Output is path-only (no diffs);
# operator runs `git diff` / their own diff tool on the listed paths.
if [[ "$SUBCOMMAND" == "diff" ]]; then
  [[ -n "$TARGET" ]] || die "diff: missing <target-dir>"
  [[ -d "$TARGET" ]] || die "diff: target not found: $TARGET"
  MANIFEST="$TARGET/.ai-workflows/manifest.json"
  [[ -f "$MANIFEST" ]] || die "diff: no manifest at $MANIFEST (target not installed via this template?)"
  if command -v jq >/dev/null 2>&1; then
    INSTALLED="$(jq -r '.version // "unknown"' "$MANIFEST")"
    SOURCE_COMMIT="$(jq -r '.source_commit // ""' "$MANIFEST")"
    INSTALL_DATE="$(jq -r '.install_date // ""' "$MANIFEST")"
  else
    # jq fallback — best-effort grep parse.
    INSTALLED="$(grep -E '"version"' "$MANIFEST" | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')"
    SOURCE_COMMIT="$(grep -E '"source_commit"' "$MANIFEST" | head -1 | sed -E 's/.*"source_commit"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')"
    INSTALL_DATE="$(grep -E '"install_date"' "$MANIFEST" | head -1 | sed -E 's/.*"install_date"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')"
  fi
  printf 'Target installed v%s, current template v%s.\n' "${INSTALLED:-unknown}" "${AIWF_VERSION:-unknown}"
  printf '  manifest      %s\n' "$MANIFEST"
  printf '  install_date  %s\n' "${INSTALL_DATE:-?}"
  printf '  source_commit %s\n' "${SOURCE_COMMIT:-<unknown / tarball install>}"
  echo
  if [[ -n "$INSTALL_DATE" ]]; then
    note "Files in target's .claude/ and docs/playbooks/ modified since install_date:"
    # Use the manifest file's mtime as a stable reference (touched at
    # install end). Path-only output; operator runs their own diff tool.
    find "$TARGET/.claude" "$TARGET/docs/playbooks" -type f -newer "$MANIFEST" 2>/dev/null | sed "s|^$TARGET/||" | sort || true
  fi
  echo
  if [[ -n "$AIWF_VERSION" && -n "$INSTALLED" && "$INSTALLED" != "$AIWF_VERSION" ]]; then
    warn "version drift: target v$INSTALLED vs template v$AIWF_VERSION"
    warn "upgrade path (current): re-run ./install.sh $TARGET --force after backing up."
  fi
  exit 0
fi

[[ -n "$TARGET" ]] || die "missing <target-dir> (try --help)"

# ---------- config load / prompt ----------
slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }

prompt_var() {
  # $1 = var name, $2 = prompt text, $3 = default (optional)
  local var="$1" text="$2" default="${3:-}" val=""
  if [[ -n "${!var:-}" ]]; then return; fi
  if [[ -n "$default" ]]; then
    printf '%s [%s]: ' "$text" "$default" >&2
  else
    printf '%s: ' "$text" >&2
  fi
  read -r val </dev/tty || val=""
  [[ -n "$val" ]] || val="$default"
  printf -v "$var" '%s' "$val"
}

if [[ -n "$CONFIG_FILE" ]]; then
  [[ -f "$CONFIG_FILE" ]] || die "config file not found: $CONFIG_FILE"
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  note "loaded config: $CONFIG_FILE"
fi

# interactive prompts for anything still empty (skip in dry-run if all set)
prompt_var PROJECT_NAME      "Project name (human-readable, e.g. \"My Service\")"
PROJECT_SLUG_DEFAULT="$(slugify "$PROJECT_NAME")"
prompt_var PROJECT_SLUG      "Project slug (kebab-case)" "$PROJECT_SLUG_DEFAULT"
prompt_var AGENT_PREFIX      "Agent prefix (e.g. \"myservice\")" "$PROJECT_SLUG"
prompt_var TECH_STACK_DESC   "Tech stack (free text)" "TBD"
prompt_var TASK_ID_PREFIX    "Task ID prefix (e.g. \"PROJ\" → PROJ-001)" "$(printf '%s' "$AGENT_PREFIX" | tr '[:lower:]' '[:upper:]')"
[[ -z "$BRAIN_PATH" ]] && prompt_var BRAIN_PATH "External Brain path (Obsidian vault, blank to use in-repo .claude/memory/)" ""

# validate slug
[[ "$PROJECT_SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "PROJECT_SLUG must be kebab-case: got '$PROJECT_SLUG'"
[[ "$AGENT_PREFIX" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "AGENT_PREFIX must be kebab-case: got '$AGENT_PREFIX'"

# validate profile
case "$PROFILE" in
  restricted|standard|permissive) ;;
  *) die "invalid --profile: '$PROFILE' (expected: restricted | standard | permissive)" ;;
esac

# resolve target
TARGET="$(mkdir -p "$TARGET" && cd "$TARGET" && pwd)"

note "Install plan:"
printf '  target          %s\n' "$TARGET"
printf '  project name    %s\n' "$PROJECT_NAME"
printf '  project slug    %s\n' "$PROJECT_SLUG"
printf '  agent prefix    %s\n' "$AGENT_PREFIX"
printf '  task prefix     %s\n' "$TASK_ID_PREFIX"
printf '  tech stack      %s\n' "$TECH_STACK_DESC"
printf '  brain path      %s\n' "${BRAIN_PATH:-<in-repo .claude/memory/>}"
printf '  presets         %s\n' "${PRESETS:-<core only>}"
printf '  profile         %s\n' "$PROFILE"
printf '  dry-run         %s\n' "$([[ $DRY_RUN -eq 1 ]] && echo yes || echo no)"
printf '  force           %s\n' "$([[ $FORCE -eq 1 ]] && echo yes || echo no)"
echo

# ---------- existence / backup ----------
backup_existing() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  if [[ $FORCE -eq 1 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      warn "would --force overwrite: $path"
    else
      warn "--force: removing $path"
      rm -rf "$path"
    fi
    return 0
  fi
  local ts; ts="$(date +%Y%m%d-%H%M%S)"
  local bak="${path}.backup-${ts}"
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "would back up: $path → $bak"
  else
    warn "backing up: $path → $bak"
    mv "$path" "$bak"
  fi
}

# settings.json gets soft-merge treatment below — DON'T back it up here, the
# soft-merge function decides whether to overwrite or write the snippet
# side-by-side.
for p in "$TARGET/CLAUDE.md" "$TARGET/docs/spec/STATUS.md"; do
  [[ -e "$p" ]] && backup_existing "$p"
done
# .claude/ as a whole: back it up only if --force is NOT set AND the target
# has files we don't own (skills, agents from a custom setup). Conservative
# default — back up the whole folder. The soft-merge will then restore
# settings.json from the backup.
# Path the soft-merge step looks for the user's old settings at.
# We put it INSIDE the backup directory (not the target root) so a mid-install
# abort doesn't leave a stale, potentially secret-bearing file lying around
# in the user's project.
STASH_PATH=""

# Trap to guarantee stash cleanup even if the script aborts.
# shellcheck disable=SC2064
trap '[[ -n "${STASH_PATH:-}" && -f "$STASH_PATH" ]] && rm -f "$STASH_PATH" || true' EXIT INT TERM

if [[ -e "$TARGET/.claude" ]]; then
  EXISTING_SETTINGS=""
  [[ -f "$TARGET/.claude/settings.json" ]] && EXISTING_SETTINGS="$TARGET/.claude/settings.json"
  backup_existing "$TARGET/.claude"
  if [[ -n "$EXISTING_SETTINGS" && $DRY_RUN -eq 0 && $FORCE -eq 0 ]]; then
    # find the backup we just made (most recent .backup-* of .claude)
    LATEST_BAK="$(ls -dt "$TARGET"/.claude.backup-* 2>/dev/null | head -1 || true)"
    if [[ -n "$LATEST_BAK" && -f "$LATEST_BAK/settings.json" ]]; then
      # stash it for the soft-merge step. Kept inside the backup dir for safety
      # (the trap removes it on any exit so it never pollutes the project).
      STASH_PATH="$LATEST_BAK/.user-settings.json.stash"
      cp "$LATEST_BAK/settings.json" "$STASH_PATH" 2>/dev/null || STASH_PATH=""
    fi
  fi
fi

# ---------- copy core ----------
copy_tree() {
  # $1 src dir, $2 dest dir
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  if [[ $DRY_RUN -eq 1 ]]; then
    find "$src" -type f | while read -r f; do
      local rel="${f#$src/}"
      printf '  + %s\n' "$dst/$rel"
    done
    return 0
  fi
  mkdir -p "$dst"
  # cp -R preserves dotfiles when source path ends with /. on macOS+linux bash
  cp -R "$src"/. "$dst"/
}

note "Copying core/ → $TARGET/"
copy_tree "$SCRIPT_DIR/core" "$TARGET"

# Ensure hook scripts are executable after copy (defensive — cp -R should
# preserve mode, but some shares / filesystems strip the bit).
if [[ $DRY_RUN -eq 0 && -d "$TARGET/.claude/hooks" ]]; then
  find "$TARGET/.claude/hooks" -type f -name '*.sh' -exec chmod +x {} +
fi

# ---------- select permission profile ----------
# core/ ships three settings.<profile>.json.tmpl variants. Pick the one
# matching --profile, rename it to settings.json.tmpl so the render pass
# turns it into settings.json. Discard the other two.
select_profile() {
  local chosen="$TARGET/.claude/settings.${PROFILE}.json.tmpl"
  local target_tmpl="$TARGET/.claude/settings.json.tmpl"
  if [[ $DRY_RUN -eq 1 ]]; then
    note "would select profile: $PROFILE (settings.${PROFILE}.json.tmpl → settings.json)"
    return 0
  fi
  [[ -f "$chosen" ]] || die "profile template missing: $chosen (corrupt install or new profile not on disk)"
  mv "$chosen" "$target_tmpl"
  # discard the other variants — they're not for this install.
  rm -f "$TARGET/.claude/settings.restricted.json.tmpl" \
        "$TARGET/.claude/settings.standard.json.tmpl" \
        "$TARGET/.claude/settings.permissive.json.tmpl"
  ok "profile selected: $PROFILE (→ .claude/settings.json)"
}
select_profile

# ---------- merge presets ----------
if [[ -n "$PRESETS" ]]; then
  IFS=',' read -ra PRESET_LIST <<< "$PRESETS"
  for p in "${PRESET_LIST[@]}"; do
    p="$(printf '%s' "$p" | tr -d '[:space:]')"
    [[ -n "$p" ]] || continue
    PRESET_SRC="$SCRIPT_DIR/presets/$p"
    [[ -d "$PRESET_SRC" ]] || die "preset not found: $p (look in $SCRIPT_DIR/presets/)"
    note "Merging preset/$p → $TARGET/.claude + docs/"
    # preset layout mirrors install destinations:
    #   presets/<name>/agents/*  → .claude/agents/
    #   presets/<name>/rules/*   → .claude/rules/
    #   presets/<name>/skills/*  → .claude/skills/
    #   presets/<name>/docs/*    → docs/
    [[ -d "$PRESET_SRC/agents" ]] && copy_tree "$PRESET_SRC/agents" "$TARGET/.claude/agents"
    [[ -d "$PRESET_SRC/rules"  ]] && copy_tree "$PRESET_SRC/rules"  "$TARGET/.claude/rules"
    [[ -d "$PRESET_SRC/skills" ]] && copy_tree "$PRESET_SRC/skills" "$TARGET/.claude/skills"
    [[ -d "$PRESET_SRC/docs"   ]] && copy_tree "$PRESET_SRC/docs"   "$TARGET/docs"
  done
fi

# ---------- render placeholders ----------
# Escape regex-significant chars in replacement RHS for sed
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }

render_substitute() {
  # $1 src path; output path = src with .tmpl suffix stripped.
  # Substitutes {{PLACEHOLDERS}}. If .tmpl is in the name, also renames.
  local src="$1"
  local dst="${src%.tmpl}"
  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ "$src" != "$dst" ]]; then
      printf '  ↻ %s → %s (render + rename)\n' "$src" "$dst"
    else
      printf '  ↻ %s (in-place render)\n' "$src"
    fi
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  sed \
    -e "s/{{PROJECT_NAME}}/$(sed_escape "$PROJECT_NAME")/g" \
    -e "s/{{PROJECT_SLUG}}/$(sed_escape "$PROJECT_SLUG")/g" \
    -e "s/{{AGENT_PREFIX}}/$(sed_escape "$AGENT_PREFIX")/g" \
    -e "s/{{TECH_STACK_DESC}}/$(sed_escape "$TECH_STACK_DESC")/g" \
    -e "s/{{BRAIN_PATH}}/$(sed_escape "${BRAIN_PATH:-.claude/memory}")/g" \
    -e "s/{{TASK_ID_PREFIX}}/$(sed_escape "$TASK_ID_PREFIX")/g" \
    "$src" > "$tmp"
  if [[ "$src" != "$dst" ]]; then
    mv "$tmp" "$dst"
    rm -f "$src"
  else
    mv "$tmp" "$src"
  fi
}

note "Rendering placeholders…"
# Pass 1: every *.tmpl gets rendered + renamed.
while IFS= read -r -d '' f; do render_substitute "$f"; done \
  < <(find "$TARGET" -type f -name '*.tmpl' -print0)
# Pass 2: every other text file gets in-place placeholder substitution
# (only files that actually contain a {{...}} placeholder, for speed).
# Limit to .claude/, docs/, CLAUDE.md, and README.md so we never touch
# user-tracked code outside the workflow scope.
for root in "$TARGET/.claude" "$TARGET/docs" "$TARGET/CLAUDE.md" "$TARGET/README.md"; do
  [[ -e "$root" ]] || continue
  while IFS= read -r -d '' f; do
    # skip the .tmpl files (already handled) and any binary file
    [[ "$f" == *.tmpl ]] && continue
    grep -lI '{{[A-Z_][A-Z_0-9]\+}}' "$f" >/dev/null 2>&1 || continue
    render_substitute "$f"
  done < <(find "$root" -type f -print0)
done

# ---------- settings.json soft-merge ----------
# If the target had a pre-existing settings.json that looked customized
# (different from a fresh foundation render), preserve it. The foundation
# version becomes a side-by-side snippet for hand-merge.
soft_merge_settings() {
  local stash="${STASH_PATH:-}"
  local foundation="$TARGET/.claude/settings.json"
  [[ -n "$stash" && -f "$stash" ]] || return 0
  if [[ $DRY_RUN -eq 1 ]]; then
    note "would soft-merge settings.json (snippet beside user copy)"
    return 0
  fi
  # Compare stashed (user) vs fresh foundation. Prefer jq-driven byte-equality
  # on key-sorted JSON (preserves array order for hooks — which matters,
  # since hook execution follows array order). Fall back to byte-equality of
  # the raw files if jq isn't available.
  local equal=0
  if command -v jq >/dev/null 2>&1; then
    if diff -q <(jq -S . "$stash" 2>/dev/null) <(jq -S . "$foundation" 2>/dev/null) >/dev/null 2>&1; then
      equal=1
    fi
  else
    if cmp -s "$stash" "$foundation"; then
      equal=1
    fi
  fi
  if [[ $equal -eq 1 ]]; then
    # User's old file matches the fresh foundation — no customizations to
    # preserve. Trap will reap the stash on exit.
    return 0
  fi
  # Non-trivial differences → preserve user copy, write foundation as snippet
  mv "$foundation" "$TARGET/.claude/settings.foundation.json"
  cp "$stash" "$foundation"
  # Stash already inside backup dir; trap will clean it. Don't re-delete here.
  warn "settings.json had customizations — preserved user version."
  warn "Foundation hooks + permissions written to:"
  warn "    $TARGET/.claude/settings.foundation.json"
  warn "Merge manually (the hook block is what's new — see docs/setup/settings-merge.md)."
}
soft_merge_settings

# ---------- placeholder lint (verify nothing left) ----------
if [[ $DRY_RUN -eq 0 ]]; then
  if leftover="$(grep -rln '{{[A-Z_]\{2,\}}}' "$TARGET" 2>/dev/null || true)"; then
    if [[ -n "$leftover" ]]; then
      warn "unrendered placeholders remain in:"
      printf '   %s\n' $leftover
      warn "(probably a new var added to a .tmpl but not to install.sh — patch sed block)"
    fi
  fi
fi

# ---------- write install manifest ----------
# Drift control: record what got installed where + which template commit
# produced it. The `diff` subcommand reads this back. Placeholder VALUES
# are deliberately NOT recorded (PROJECT_NAME etc. are fine, but a real
# project might pass secrets through env vars — only NAMES are stored).
write_manifest() {
  [[ $DRY_RUN -eq 1 ]] && { note "would write manifest: $TARGET/.ai-workflows/manifest.json"; return 0; }
  mkdir -p "$TARGET/.ai-workflows"
  local manifest="$TARGET/.ai-workflows/manifest.json"
  local install_date
  install_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_commit
  source_commit="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
  # presets array
  local presets_json="[]"
  if [[ -n "$PRESETS" ]]; then
    presets_json="$(printf '%s' "$PRESETS" | awk -F, '{
      printf "["
      for (i=1;i<=NF;i++) {
        gsub(/^[ \t]+|[ \t]+$/,"",$i)
        if (i>1) printf ","
        printf "\"%s\"", $i
      }
      printf "]"
    }')"
  fi
  cat > "$manifest" <<EOF
{
  "version": "${AIWF_VERSION:-unknown}",
  "install_date": "$install_date",
  "source_commit": "$source_commit",
  "profile": "$PROFILE",
  "presets": $presets_json,
  "placeholders": {
    "PROJECT_NAME": "$PROJECT_NAME",
    "PROJECT_SLUG": "$PROJECT_SLUG",
    "AGENT_PREFIX": "$AGENT_PREFIX",
    "TASK_ID_PREFIX": "$TASK_ID_PREFIX",
    "TECH_STACK_DESC": "$TECH_STACK_DESC",
    "BRAIN_PATH_SET": $([[ -n "$BRAIN_PATH" ]] && echo true || echo false)
  }
}
EOF
  ok "wrote manifest: $manifest"
}
write_manifest

# ---------- next steps ----------
echo
ok "install complete."
echo
note "Next steps:"
cat <<EOF
  1. cd "$TARGET"
  2. Edit docs/spec/STATUS.md — set your first sprint
  3. Append project-specific rules to .claude/rules/brain-hot.md
     (add your A001, A002, … local rules section)
  4. Edit CLAUDE.md — fill in the dispatch-routing table for your stack
  5. Open Claude Code in the project, then try:
        /next-task        — pick something to work on
        /design-review    — UI fidelity gate (if you ship UI)
        /retro            — sprint close + audit
  6. Found a rough edge? Send feedback upstream:
        /flightdeck-feedback     — draft + send a GitHub issue (opt-in)
        or see docs/setup/feedback.md for prefilled issue links
EOF
[[ -n "$BRAIN_PATH" ]] && note "External Brain wired: $BRAIN_PATH (see brain-hot.md footer)"
[[ -z "$BRAIN_PATH" ]] && note "In-repo Brain enabled: .claude/memory/ (export BRAIN_PATH later to switch)"
