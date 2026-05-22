#!/usr/bin/env bash
# PreToolUse hook — block obvious secret leaks before they reach a tool call.
#
# Scope: Bash, Write, Edit. Reads the tool-event JSON on stdin, inspects
# tool_input.command (Bash) or tool_input.content + .file_path (Write/Edit).
# On a likely leak, exits 2 with a stderr message — Claude Code surfaces
# the message back to the model and the tool call is aborted.
#
# Philosophy: conservative. Prefer false negatives over false positives.
# We only flag patterns that look like a deliberate echo / write of a
# sensitive value. Entropy-based scanning of arbitrary file content is
# OUT OF SCOPE (too many false positives — UUIDs, hashes, base64 blobs).
# We only entropy-scan when the file path matches .env* / secret* /
# credentials*.
#
# Fails open (exit 0) if jq is missing — the rule never blocks dev on
# a machine without the toolchain. CI / gitleaks is the second net.

set -uo pipefail

# Hard dependency: jq for parsing the event JSON. Fail open if absent.
command -v jq >/dev/null 2>&1 || exit 0

EVENT_JSON="$(cat 2>/dev/null || true)"
[ -n "$EVENT_JSON" ] || exit 0

TOOL_NAME="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_name // empty' 2>/dev/null)"
[ -n "$TOOL_NAME" ] || exit 0

# Sensitive env-var name pattern. Keep in lock-step with
# docs/setup/secret-handling.md "agent-redaction rule".
SENSITIVE_VAR_REGEX='([A-Z][A-Z0-9_]*_(TOKEN|KEY|SECRET|PASSWORD|PASSWD|PWD))|(PASSWORD[A-Z0-9_]*)|((AWS|GCP|AZURE|OPENAI|ANTHROPIC|STRIPE|SLACK|GH|GITHUB)_[A-Z0-9_]+)'

# Filename pattern for entropy-worthy paths.
SENSITIVE_PATH_REGEX='(^|/)(\.env([._-][^/]*)?|secrets?([._-][^/]*)?|credentials?([._-][^/]*)?)$'

block() {
  # $1 = reason. Print to stderr, exit 2 (Claude Code surfaces stderr to the model).
  printf '── secret-redact: %s ──\n' "$1" >&2
  printf 'blocked: potential secret leak — see docs/setup/secret-handling.md\n' >&2
  exit 2
}

scan_bash_command() {
  local cmd="$1"

  # Pattern A — echo/printf/cat of a sensitive env-var by name.
  # Matches: echo "$AWS_SECRET_KEY", printf '%s' $DB_PASSWORD, cat ~/.aws/credentials.
  if printf '%s' "$cmd" | grep -E -q '(\b(echo|printf|cat|tee)\b[^|;&]*\$\{?'"$SENSITIVE_VAR_REGEX"')'; then
    block "echo/printf/cat of a sensitive env var detected"
  fi

  # Pattern B — sensitive var piped to network egress (curl/nc/wget body).
  # We're permissive about Authorization-header forms (the standard pattern);
  # we only block when the value is in the body / query string.
  if printf '%s' "$cmd" | grep -E -q '\b(curl|wget|nc|netcat)\b[^|;&]*(-d|--data|--data-raw|--data-binary)[[:space:]]*[^[:space:]]*\$\{?'"$SENSITIVE_VAR_REGEX"; then
    block "sensitive env var piped into network request body"
  fi

  # Pattern C — redirecting a sensitive var to a file.
  # echo "$TOKEN" > /tmp/x ; printf '%s' $KEY >> file
  if printf '%s' "$cmd" | grep -E -q '\$\{?'"$SENSITIVE_VAR_REGEX"'\}?[^|;&]*[[:space:]]*>[>]?[[:space:]]*[^|;&[:space:]]+'; then
    block "sensitive env var redirected to a file"
  fi

  # Pattern D — cat / less / git log of a known-sensitive file path.
  if printf '%s' "$cmd" | grep -E -q '\b(cat|less|more|head|tail|bat|git[[:space:]]+log)\b[^|;&]*'"$SENSITIVE_PATH_REGEX"; then
    block "reading a likely-secret file (.env / credentials / secrets)"
  fi

  # Pattern E — set -x / bash -x / xtrace in a command that touches a sensitive var.
  if printf '%s' "$cmd" | grep -E -q '(set[[:space:]]+-[a-z]*x|bash[[:space:]]+-[a-z]*x)' \
     && printf '%s' "$cmd" | grep -E -q '\$\{?'"$SENSITIVE_VAR_REGEX"; then
    block "xtrace / set -x enabled while handling a sensitive env var"
  fi
}

scan_write_content() {
  local file_path="$1" content="$2"

  # Only entropy-scan content when the filename looks secret-bearing.
  # This is conservative on purpose — many legitimate files contain
  # high-entropy strings (UUIDs, hashes, lockfiles).
  if printf '%s' "$file_path" | grep -E -q "$SENSITIVE_PATH_REGEX"; then
    # Allow placeholder-style content (your-key-here, <REDACTED>, etc).
    if printf '%s' "$content" | grep -E -q '(your[-_][a-z]+[-_]here|<[A-Z_]+>|CHANGEME|REPLACE_ME|example|EXAMPLE|placeholder|PLACEHOLDER|xxx+|XXX+|\.\.\.|TODO)'; then
      # Looks like a template / .env.example — let it through.
      return 0
    fi
    # If any line looks like KEY=non-placeholder-value, block.
    if printf '%s' "$content" | grep -E -q '^[A-Z][A-Z0-9_]*=[^[:space:]#]{8,}'; then
      block "writing a likely-real secret to $file_path (use .env.example with placeholders)"
    fi
  fi
}

case "$TOOL_NAME" in
  Bash)
    CMD="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    [ -n "$CMD" ] || exit 0
    scan_bash_command "$CMD"
    ;;
  Write|Edit|MultiEdit)
    FILE_PATH="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
    CONTENT="$(printf '%s' "$EVENT_JSON" | jq -r '(.tool_input.content // .tool_input.new_string // empty)' 2>/dev/null)"
    [ -n "$FILE_PATH" ] || exit 0
    scan_write_content "$FILE_PATH" "$CONTENT"
    ;;
esac

exit 0
