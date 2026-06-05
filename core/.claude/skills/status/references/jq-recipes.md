# jq Recipes — ad-hoc audit-log queries

> Companion to the `/status audit` skill. The skill emits an opinionated
> markdown digest; these recipes are the escape hatch for one-off
> investigations where the digest doesn't fit.
>
> All recipes assume `cwd` is the project root and audit files live at
> `docs/project/audit/YYYY-MM.jsonl` (see `docs/setup/audit-trail.md` for
> schema).

## All dispatches today

**When:** quick "what happened so far today" pulse during an active sprint.

```bash
jq -c 'select(.ts | startswith("'$(date -u +%Y-%m-%d)'"))' \
  docs/project/audit/*.jsonl
```

## All dispatches for a specific task

**When:** forensics on a single task — every dispatch, every reviewer touch.

```bash
jq -c 'select(.task_id == "URLSH-S03.04")' docs/project/audit/*.jsonl
```

## Slowest 10 dispatches lifetime

**When:** root-cause a perf regression — "which dispatches were anomalously slow ever"?

```bash
jq -s 'map(select(.duration_ms != null))
       | sort_by(-.duration_ms)
       | .[:10]
       | map({agent: .subagent_type, task: .task_id, ms: .duration_ms, ts})' \
  docs/project/audit/*.jsonl
```

## Files most edited

**When:** identify hot files that may need refactor / better tests / clearer boundary.

```bash
jq -r '.files_touched[]?' docs/project/audit/*.jsonl \
  | sort | uniq -c | sort -rn | head -20
```

## Average duration by agent

**When:** benchmark per-agent latency; compare a new preset agent against an existing one.

```bash
jq -s '
  group_by(.subagent_type)
  | map({
      agent: .[0].subagent_type,
      n: length,
      avg_ms: (map(.duration_ms // 0) | add / length | floor)
    })
  | sort_by(-.avg_ms)
' docs/project/audit/*.jsonl
```

## Cycle counts per task (gate retries)

**When:** find tasks that took multiple dispatches — usually means a 6-gate failure caused rework.

```bash
jq -s '
  map(select(.task_id != null and .task_id != ""))
  | group_by(.task_id)
  | map({task: .[0].task_id, dispatches: length})
  | sort_by(-.dispatches)
  | .[:10]
' docs/project/audit/*.jsonl
```

## Dispatches in a date range

**When:** weekly / monthly retro — pre-`/status audit` exploration when you want the raw rows.

```bash
jq -c --arg lo "2026-05-01T00:00:00Z" --arg hi "2026-05-15T23:59:59Z" \
  'select(.ts >= $lo and .ts <= $hi)' \
  docs/project/audit/2026-05.jsonl
```

## Subagent_type distribution this month

**When:** answer "who's doing the heavy lifting this sprint" in one glance.

```bash
jq -r '.subagent_type // "(unknown)"' \
  "docs/project/audit/$(date -u +%Y-%m).jsonl" \
  | sort | uniq -c | sort -rn
```

## Events with a non-empty reason (gate-failure indicator)

**When:** "did anything fail?" — `reason` is filled by the hook on SubagentStop when a stop reason / exit code is non-trivial.

```bash
jq -c 'select(.reason != null and .reason != "")' \
  docs/project/audit/*.jsonl
```

## Reconstruct one agent's history

**When:** trace exactly what one specialist did across a sprint, in order.

```bash
jq -c 'select(.subagent_type == "backend-engineer")' \
  docs/project/audit/*.jsonl \
  | jq -s 'sort_by(.ts) | .[] | {ts, task_id, ms: .duration_ms, files: (.files_touched // [] | length)}'
```

## Co-touched files (which files travel together)

**When:** find implicit module boundaries — files repeatedly touched in the same dispatch are likely one logical unit.

```bash
jq -c 'select((.files_touched // [] | length) > 1) | .files_touched' \
  docs/project/audit/*.jsonl \
  | sort | uniq -c | sort -rn | head -20
```

## See also

- `core/.claude/skills/status/SKILL.md` — the opinionated digest
- `core/docs/setup/audit-trail.md` — schema + retention + SIEM ingestion
- `core/.claude/hooks/audit.sh` — the hook that writes these JSONL files
