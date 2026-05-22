#!/usr/bin/env bash
# Audit-trail hook for Claude Code.
#
# Triggered as a PostToolUse hook on the `Agent` tool and as a
# SubagentStop hook. Reads the tool event JSON from stdin, distills a
# compact audit record, and appends one JSONL line (newline-delimited
# JSON / ndjson) to docs/spec/audit/YYYY-MM.jsonl.
#
# JSONL schema (one object per line, ndjson-friendly for Splunk /
# Datadog / ELK ingestion — see docs/setup/audit-trail.md):
#
#   ts             ISO8601 UTC timestamp (event-side timestamp)
#   event          "PostToolUse" | "SubagentStop"
#   tool           tool name (typically "Agent")
#   agent_id       harness-assigned agent id, if present
#   subagent_type  e.g. "general-purpose" / "<prefix>-orchestrator"
#   task_id        extracted from the invocation prompt (e.g. PROJ-S03.04)
#   files_touched  array of paths the tool reports as touched (best-effort)
#   reason         exit / return reason if present
#   duration_ms    elapsed time if the event carries it
#   sha_before     git rev-parse HEAD at hook entry (empty for non-git)
#   sha_after      git rev-parse HEAD at hook exit (empty for non-git)
#   project        $CLAUDE_PROJECT_DIR basename
#
# Fail-open: jq missing, write failure, malformed input — exit 0 and
# never block the dispatch. The hook is observability, not enforcement.

set -uo pipefail

# jq is required to parse the event JSON. If it's not installed, fail
# open — never block dispatch on a missing dependency.
command -v jq >/dev/null 2>&1 || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
AUDIT_DIR="$PROJECT_DIR/docs/spec/audit"
mkdir -p "$AUDIT_DIR" 2>/dev/null || exit 0

MONTH="$(date -u +%Y-%m)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
AUDIT_FILE="$AUDIT_DIR/$MONTH.jsonl"

# Capture stdin once.
EVENT_JSON="$(cat 2>/dev/null || printf '{}')"

# Best-effort field extraction. `// empty` keeps the JSON valid when a
# field is absent (jq emits nothing, the field stays as "" / [] below).
EVENT_NAME="$(printf '%s' "$EVENT_JSON" | jq -r '.hook_event_name // .event // empty' 2>/dev/null)"
TOOL_NAME="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_name // .tool // empty' 2>/dev/null)"
AGENT_ID="$(printf '%s' "$EVENT_JSON" | jq -r '.agent_id // .session_id // empty' 2>/dev/null)"
SUBAGENT_TYPE="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_input.subagent_type // .subagent_type // empty' 2>/dev/null)"
REASON="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_response.stop_reason // .stop_reason // .reason // empty' 2>/dev/null)"
DURATION_MS="$(printf '%s' "$EVENT_JSON" | jq -r '.duration_ms // .tool_response.duration_ms // empty' 2>/dev/null)"

# Extract task ID from the dispatched prompt — pattern: any
# UPPERCASE-PREFIX with an optional sprint segment, e.g. PROJ-S03.04 or
# IDIP-042. Best-effort; empty if not found.
PROMPT_TEXT="$(printf '%s' "$EVENT_JSON" | jq -r '.tool_input.prompt // empty' 2>/dev/null)"
TASK_ID="$(printf '%s' "$PROMPT_TEXT" | grep -oE '[A-Z][A-Z0-9]+-(S[0-9]+\.[0-9]+|[0-9]+)' | head -1 || true)"

# files_touched: harness convention varies. Try a few common shapes.
FILES_JSON="$(printf '%s' "$EVENT_JSON" | jq -c '
  ( .tool_response.files
  // .tool_response.touched_files
  // .files_touched
  // [] )
' 2>/dev/null)"
[[ -z "$FILES_JSON" || "$FILES_JSON" == "null" ]] && FILES_JSON="[]"

# Git SHAs — best-effort, fail-open in non-git contexts.
SHA="$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || true)"

PROJECT_BASENAME="$(basename "$PROJECT_DIR")"

# Assemble + append. jq -c -n with --arg keeps strings safe (no shell
# quoting bugs). Redirect failures fail open.
RECORD="$(jq -c -n \
  --arg ts "$TS" \
  --arg event "$EVENT_NAME" \
  --arg tool "$TOOL_NAME" \
  --arg agent_id "$AGENT_ID" \
  --arg subagent_type "$SUBAGENT_TYPE" \
  --arg task_id "$TASK_ID" \
  --argjson files "$FILES_JSON" \
  --arg reason "$REASON" \
  --arg duration_ms "$DURATION_MS" \
  --arg sha "$SHA" \
  --arg project "$PROJECT_BASENAME" \
  '{ts:$ts, event:$event, tool:$tool, agent_id:$agent_id,
    subagent_type:$subagent_type, task_id:$task_id,
    files_touched:$files, reason:$reason,
    duration_ms:(if $duration_ms=="" then null else ($duration_ms|tonumber? // null) end),
    sha:$sha, project:$project}' 2>/dev/null)" || exit 0

printf '%s\n' "$RECORD" >> "$AUDIT_FILE" 2>/dev/null || exit 0
exit 0
