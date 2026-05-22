#!/usr/bin/env bash
# Lint dispatcher hook for Claude Code PostToolUse.
#
# Reads the tool-event JSON from stdin, looks at tool_input.file_path,
# picks a linter from the extension, and runs it. On a real lint failure
# this exits 2 — Claude Code feeds the captured stderr back to the model
# so it can self-correct on the next turn.
#
# Linters are optional. If none is installed for a language, the hook
# exits 0 silently (it should never block an edit on a machine that
# simply doesn't have the toolchain).
#
# Auto-fix is intentionally OFF. We want Claude to see the diagnostics
# and fix them in-conversation, not have files mutate behind its back.

set -uo pipefail

# jq is the only hard dependency. Fail open if it's not installed.
command -v jq >/dev/null 2>&1 || exit 0

EVENT_JSON="$(cat)"
FILE_PATH="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_input.file_path // empty')"

[ -n "$FILE_PATH" ] || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# Normalize relative paths to absolute so the in-project check below
# doesn't false-negative on a relative file_path. Use realpath when
# available; fall back to a portable prefix join otherwise.
if command -v realpath >/dev/null 2>&1; then
  FILE_PATH="$(realpath -m "$FILE_PATH" 2>/dev/null || printf '%s' "$FILE_PATH")"
else
  case "$FILE_PATH" in
    /*) : ;;
    *)  FILE_PATH="$PROJECT_DIR/$FILE_PATH" ;;
  esac
fi

[ -f "$FILE_PATH" ] || exit 0

# Only lint files inside the project tree.
case "$FILE_PATH" in
  "$PROJECT_DIR"/*) ;;
  *) exit 0 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

# Run a linter. On non-zero exit, emit a labeled report to stderr and
# exit 2 so Claude Code surfaces it back to the model.
run_linter() {
  local label="$1"; shift
  local out rc=0
  out="$("$@" 2>&1)" || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf '── %s: %s ──\n%s\n' "$label" "$FILE_PATH" "$out" >&2
    exit 2
  fi
}

# Prefer a project-local node binary over the global one — most JS/TS
# repos pin their linter version in node_modules.
node_bin() {
  local name="$1"
  if [ -x "$PROJECT_DIR/node_modules/.bin/$name" ]; then
    printf '%s\n' "$PROJECT_DIR/node_modules/.bin/$name"
  elif have "$name"; then
    printf '%s\n' "$name"
  fi
}

case "$FILE_PATH" in
  *.go)
    # gofmt has no module dependency — always run it first.
    if have gofmt; then
      diff="$(gofmt -d "$FILE_PATH" 2>&1)" || true
      if [ -n "$diff" ]; then
        printf '── gofmt: %s not formatted ──\n%s\n' "$FILE_PATH" "$diff" >&2
        exit 2
      fi
    fi

    # golangci-lint needs a go.mod somewhere above the file — outside a
    # module it errors with "no go files to analyze" and is unhelpful.
    # Walk up looking for go.mod; skip the linter if there's no module.
    has_go_mod=0
    dir="$(dirname "$FILE_PATH")"
    while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
      if [ -f "$dir/go.mod" ]; then has_go_mod=1; break; fi
      dir="$(dirname "$dir")"
    done

    if [ "$has_go_mod" -eq 1 ] && have golangci-lint; then
      rc=0
      out="$(golangci-lint run "$FILE_PATH" 2>&1)" || rc=$?
      # "no go files to analyze" means the loader couldn't resolve the
      # package context — treat as a soft skip, but warn so build-tag
      # gated files (`//go:build ignore`, wrong-OS tags) don't go silent.
      if [ "$rc" -ne 0 ]; then
        if printf '%s' "$out" | grep -q 'no go files to analyze'; then
          printf '── golangci-lint: soft-skip (no go files to analyze): %s ──\n' "$FILE_PATH" >&2
        else
          printf '── golangci-lint: %s ──\n%s\n' "$FILE_PATH" "$out" >&2
          exit 2
        fi
      fi
    fi
    ;;

  *.py)
    if have ruff; then
      run_linter "ruff" ruff check "$FILE_PATH"
    elif have flake8; then
      run_linter "flake8" flake8 "$FILE_PATH"
    elif have pylint; then
      run_linter "pylint" pylint --score=n "$FILE_PATH"
    fi
    ;;

  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
    bin="$(node_bin eslint)"
    if [ -n "$bin" ]; then
      run_linter "eslint" "$bin" "$FILE_PATH"
    else
      bin="$(node_bin biome)"
      if [ -n "$bin" ]; then
        run_linter "biome" "$bin" lint "$FILE_PATH"
      fi
    fi
    ;;

  *.html|*.htm)
    bin="$(node_bin htmlhint)"
    if [ -n "$bin" ]; then
      run_linter "htmlhint" "$bin" "$FILE_PATH"
    else
      bin="$(node_bin prettier)"
      if [ -n "$bin" ]; then
        run_linter "prettier" "$bin" --check "$FILE_PATH"
      fi
    fi
    ;;

  *.css|*.scss|*.sass|*.less)
    bin="$(node_bin stylelint)"
    if [ -n "$bin" ]; then
      run_linter "stylelint" "$bin" "$FILE_PATH"
    else
      bin="$(node_bin prettier)"
      if [ -n "$bin" ]; then
        run_linter "prettier" "$bin" --check "$FILE_PATH"
      fi
    fi
    ;;

  *.rs)
    # cargo clippy needs a Cargo.toml above the file; walk up for it.
    has_cargo=0
    dir="$(dirname "$FILE_PATH")"
    while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
      if [ -f "$dir/Cargo.toml" ]; then has_cargo=1; cargo_dir="$dir"; break; fi
      dir="$(dirname "$dir")"
    done
    if [ "$has_cargo" -eq 1 ] && have cargo; then
      rc=0
      out="$(cd "$cargo_dir" && cargo clippy --quiet --message-format=short -- -D warnings 2>&1)" || rc=$?
      if [ "$rc" -ne 0 ]; then
        printf '── cargo clippy: %s ──\n%s\n' "$FILE_PATH" "$out" >&2
        exit 2
      fi
    fi
    ;;

  *.sh|*.bash)
    if have shellcheck; then
      run_linter "shellcheck" shellcheck "$FILE_PATH"
    fi
    ;;

  *.rb)
    if have rubocop; then
      run_linter "rubocop" rubocop --no-color --format quiet "$FILE_PATH"
    fi
    ;;

  *.java)
    if have checkstyle; then
      run_linter "checkstyle" checkstyle "$FILE_PATH"
    elif have spotless; then
      run_linter "spotless" spotless --check "$FILE_PATH"
    fi
    ;;

  *.kt|*.kts)
    if have ktlint; then
      run_linter "ktlint" ktlint "$FILE_PATH"
    fi
    ;;

  *.php)
    if have phpcs; then
      run_linter "phpcs" phpcs --report=emacs "$FILE_PATH"
    fi
    ;;

  *.lua)
    if have luacheck; then
      run_linter "luacheck" luacheck --no-color "$FILE_PATH"
    fi
    ;;

  *.swift)
    if have swiftformat; then
      run_linter "swiftformat" swiftformat --lint "$FILE_PATH"
    elif have swiftlint; then
      run_linter "swiftlint" swiftlint lint --quiet "$FILE_PATH"
    fi
    ;;

  *.ipynb)
    # Jupyter notebooks: extract code cells and lint as python.
    # Requires jq (already a dependency) + a python linter.
    if have jq && have ruff; then
      rc=0
      cells="$(jq -r '.cells[] | select(.cell_type == "code") | .source | join("")' "$FILE_PATH" 2>/dev/null || true)"
      if [ -n "$cells" ]; then
        # Pipe extracted source through ruff via stdin so we don't write a temp file.
        out="$(printf '%s' "$cells" | ruff check --stdin-filename "$FILE_PATH" - 2>&1)" || rc=$?
        if [ "$rc" -ne 0 ]; then
          printf '── ruff (notebook cells): %s ──\n%s\n' "$FILE_PATH" "$out" >&2
          exit 2
        fi
      fi
    fi
    ;;
esac

exit 0
