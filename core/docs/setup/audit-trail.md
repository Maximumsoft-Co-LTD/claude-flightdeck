# Audit Trail — JSONL agent dispatch log

> Append-only audit log of every agent dispatch + completion. Designed
> for compliance / forensics / retro: who did what, when, against
> which code, and how it ended.
>
> Written by `.claude/hooks/audit.sh` (PostToolUse on `Agent`,
> SubagentStop). Fail-open: a missing `jq` or write failure exits 0
> rather than blocking dispatch.

## Where it lives

```
docs/spec/audit/
├── 2026-05.jsonl          # current month
├── 2026-04.jsonl          # previous month
└── …
```

One file per calendar month (UTC). JSONL = newline-delimited JSON =
ndjson, friendly to Splunk / Datadog / ELK / Loki ingestion as-is.

## Schema

Every line is a single JSON object:

| Field | Type | Notes |
|---|---|---|
| `ts` | string (ISO8601 UTC) | Event-side timestamp (hook-entry) |
| `event` | string | `"PostToolUse"` or `"SubagentStop"` |
| `tool` | string | Tool name — typically `"Agent"` |
| `agent_id` | string | Harness-assigned ID for the dispatched agent (may be empty) |
| `subagent_type` | string | E.g. `"general-purpose"`, `"<prefix>-orchestrator"`, `"hexagonal-reviewer"` |
| `task_id` | string | Extracted from dispatched prompt (regex: `[A-Z][A-Z0-9]+-(S\d+\.\d+\|\d+)`). Empty if not found |
| `files_touched` | array of strings | Best-effort; harness convention varies |
| `reason` | string | Exit / stop / return reason if present |
| `duration_ms` | number\|null | Wall-clock duration if reported |
| `sha` | string | `git rev-parse HEAD` of `$CLAUDE_PROJECT_DIR` (empty if non-git) |
| `project` | string | Basename of `$CLAUDE_PROJECT_DIR` |

### Example line

```json
{"ts":"2026-05-22T13:31:23Z","event":"PostToolUse","tool":"Agent","agent_id":"a-7f3","subagent_type":"go-hexagonal-engineer","task_id":"PROJ-S03.04","files_touched":["internal/usecase/x.go","internal/usecase/x_test.go"],"reason":"complete","duration_ms":18432,"sha":"abc1234","project":"my-service"}
```

## Retention

Short summary below. **Full retention policy across all artifacts (sprints, retros, design docs, audit logs) lives in [`retention-policy.md`](./retention-policy.md).**

| Tier | Default | Why |
|---|---|---|
| Operational (default) | 12 months | Sprint retros + quarterly review window |
| SOC2 / compliance | 24-36 months | Common SOC2 audit scope is 12 months + buffer |
| HIPAA | 6+ years | Statutory minimum where applicable |
| Greenfield / pre-prod | 1-3 months OK | Disk is cheap; default to operational anyway |

Cron the rotation (example, monthly — full GitHub Actions recipe in [`retention-policy.md`](./retention-policy.md)):

```bash
find docs/spec/audit -name '*.jsonl' -type f -mtime +365 -delete
```

## PII / redaction guidance

- The hook only captures **metadata** from the harness event:
  `task_id`, file paths, subagent type, timing. It does NOT capture
  prompt bodies, file contents, or tool outputs.
- Audit lines may include **file paths** that themselves contain
  sensitive names (e.g. `secrets/`, `staging-creds/`). If your
  project conventions encode secrets in paths, add a redaction step
  before SIEM forwarding.
- `agent_id` is harness-generated and not PII. The `project` field is
  the directory basename — fine in normal usage; redact if you mount
  audit logs into a multi-tenant dashboard with leaky naming.

## Tracking vs ignoring in git

Audit logs are project-policy. Two valid choices:

1. **Track** (default) — `git add docs/spec/audit/*.jsonl`. Lets PR
   reviewers see the agent-dispatch history alongside the diff.
   Recommended for solo / small-team work, retros, and learning.
2. **Ignore** — add to `.gitignore`:

   ```gitignore
   docs/spec/audit/
   ```

   Choose this if (a) you ship audit logs to an external SIEM and
   want the in-repo copy ephemeral, or (b) compliance requires the
   log to live only in the central SIEM.

This template does NOT add the `.gitignore` rule for you — it's a
deliberate choice per project.

## Query recipes (`jq`)

See also: [`/audit-query` skill](../../.claude/skills/audit-query/SKILL.md) — opinionated digest (by-agent counts + p50 / p95, slowest dispatches, file hotspots, recurring task IDs). Use it for weekly / sprint-end pulls; the raw `jq` recipes below are for ad-hoc work the digest doesn't cover.

### All dispatches by a specific subagent

```bash
jq -c 'select(.subagent_type=="go-hexagonal-engineer")' \
  docs/spec/audit/2026-*.jsonl
```

### Dispatches against a specific task

```bash
jq -c 'select(.task_id=="PROJ-S03.04")' docs/spec/audit/*.jsonl
```

### All dispatches in the last 7 days

```bash
SEVEN_DAYS_AGO=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)
jq -c --arg cut "$SEVEN_DAYS_AGO" \
  'select(.ts >= $cut)' docs/spec/audit/*.jsonl
```

### Average duration per subagent type (this month)

```bash
jq -s '
  group_by(.subagent_type)
  | map({type: .[0].subagent_type,
         n: length,
         avg_ms: (map(.duration_ms // 0) | add / length | floor)})
' docs/spec/audit/$(date -u +%Y-%m).jsonl
```

### Gate failures (events where reason isn't 'complete' / 'success')

```bash
jq -c 'select(.reason and (.reason | test("error|fail|abort"; "i")))' \
  docs/spec/audit/*.jsonl
```

### Touched-file frequency (files most agent-touched this month)

```bash
jq -r '.files_touched[]?' docs/spec/audit/$(date -u +%Y-%m).jsonl \
  | sort | uniq -c | sort -rn | head -20
```

## SIEM ingestion

### Splunk

```conf
# inputs.conf
[monitor:///path/to/repo/docs/spec/audit/*.jsonl]
sourcetype = ai_workflows_audit
index = ai_workflows

# props.conf
[ai_workflows_audit]
KV_MODE = json
SHOULD_LINEMERGE = false
TIME_PREFIX = "ts":"
TIME_FORMAT = %Y-%m-%dT%H:%M:%SZ
```

### Datadog (Vector / Fluent Bit)

JSONL parses out-of-the-box as `parsing.format: json` with one
record per line. Point your agent at `docs/spec/audit/*.jsonl`.

### Loki / Promtail

```yaml
scrape_configs:
  - job_name: ai_workflows_audit
    static_configs:
      - targets: [localhost]
        labels:
          job: ai_workflows_audit
          __path__: /path/to/repo/docs/spec/audit/*.jsonl
    pipeline_stages:
      - json:
          expressions:
            ts: ts
            subagent_type: subagent_type
            task_id: task_id
      - timestamp:
          source: ts
          format: RFC3339
      - labels:
          subagent_type:
```

### Elastic / OpenSearch

Filebeat with `json.keys_under_root: true, json.add_error_key: true`
on the audit glob.

## Hook configuration

The audit hook is wired in `.claude/settings.json` with two matchers:

```jsonc
"PostToolUse": [
  { "matcher": "Write|Edit|MultiEdit", "hooks": [{ "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/lint.sh" }] },
  { "matcher": "Agent",                "hooks": [{ "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/audit.sh" }] }
],
"SubagentStop": [
  { "matcher": "Agent",                "hooks": [{ "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/audit.sh" }] }
]
```

If your Claude Code version doesn't yet support the `SubagentStop`
event, the `PostToolUse` line alone still captures every dispatch —
you'll be missing the completion-side record but the dispatch side
remains intact.

## Related

- `.claude/hooks/audit.sh` — the hook (inline-documented schema)
- `.claude/hooks/lint.sh` — sibling PostToolUse hook (file lint)
- `docs/playbooks/post-delegation-review.md` — what to do after a
  dispatch lands (the 6 gates)
- `docs/setup/settings-merge.md` — how to merge new hook entries into
  an existing `settings.json`
- `CHANGELOG.md` (template root) — version history (audit hook added
  in v0.2.0)
