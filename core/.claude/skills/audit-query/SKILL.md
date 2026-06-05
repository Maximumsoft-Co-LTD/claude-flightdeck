---
name: audit-query
description: "Aggregate docs/project/audit/*.jsonl into a human-readable digest — dispatches per agent, gate failures, slowest tasks, recurring task IDs, file-touch hotspots. Use when the user asks '/audit-query', 'show audit summary', 'where did time go last week', 'which agent is slowest', 'audit dashboard', or wants weekly / sprint-end insights from the audit log."
user_invocable: true
---

# /audit-query — Audit-log digest

Aggregate `docs/project/audit/*.jsonl` (written by `.claude/hooks/audit.sh`) into an opinionated markdown digest — dispatches per agent with p50/p95 latency, slowest individual dispatches, file-touch hotspots, task-ID retry counts, and gate-failure indicators.

## Why this skill exists

The audit hook produces a high-fidelity but raw JSONL stream. Operators want fast answers — "which agent ate the sprint?", "what file is everyone touching?", "did anything fail last week?". This skill is the opinionated digest on top; the raw `jq` recipes live in [`references/jq-recipes.md`](references/jq-recipes.md) for ad-hoc work.

## Token budget

- The skill **delegates to a shell script** — `scripts/query.sh` does all aggregation in `jq` + bash. The skill body only invokes it and presents output.
- Do NOT `Read` audit JSONL files into the model context — they can be megabytes per month. Always pipe through the script.
- The script emits markdown directly to stdout; surface that, do not summarize further unless the user asks.

## Invocation forms

| Form | Effect |
|---|---|
| `/audit-query` | Default — last 7 days, top agents + top files + slowest |
| `/audit-query --since 2026-05-01` | From a specific date through today |
| `/audit-query --since 2026-05-01 --until 2026-05-15` | Closed window |
| `/audit-query --sprint S03` | Only dispatches whose `task_id` matches `*-S03.*` |
| `/audit-query --agent backend-engineer` | Filter by `subagent_type` |
| `/audit-query --task URLSH-S03.04` | All dispatches against one task ID |
| `/audit-query --top files` | Emphasize the file-touch hotspot section |
| `/audit-query --top tasks` | Emphasize recurring / multi-dispatch task IDs |

Flags are additive — combine `--sprint S03 --agent backend-engineer` to slice both ways.

## Steps

1. **Detect time window.**
   - Default: `--since` = today minus 7 days, `--until` = today (UTC).
   - If `--since` / `--until` provided, parse them as ISO dates (`YYYY-MM-DD`).
   - If `--sprint S<N>` provided, expand to a task-ID filter (`*-S<N>.*`) and use lifetime window unless `--since` is also set.
2. **Locate audit files.** Glob `docs/project/audit/*.jsonl` and keep only files whose `YYYY-MM` overlaps the window (cheap pre-filter — avoids `jq`'ing irrelevant months).
3. **Run aggregation.** Execute `scripts/query.sh` with the parsed flags. The script:
   - Streams matching JSONL lines through `jq` (filter by `ts`, `subagent_type`, `task_id`).
   - Groups by `subagent_type` for counts + p50 / p95 `duration_ms`.
   - Sorts `duration_ms` descending for the slowest-5 table.
   - Flattens `files_touched[]` for the top-10 file hotspot.
   - Groups by `task_id` for retry / multi-phase indicators (count > 1).
   - Counts events with non-empty `reason` as gate-failure indicators.
4. **Emit markdown digest** to stdout. The script writes the report directly; the skill body presents it without paraphrasing.
5. **Pre-flight checks**, in this order:
   - `command -v jq` → if missing, the script exits 1 with `audit-query requires jq; install jq` on stderr. Surface that.
   - `[ -d docs/project/audit ]` → if missing, the script exits 0 with `no audit log found yet (enable the audit hook to start collecting)`. Tell the user how (link to `audit-trail.md` §Hook configuration).
   - No JSONL lines in window → the script exits 0 with `no dispatches in window`. Suggest widening `--since`.

## Output format

A real example (last 7 days on a small project):

```markdown
# Audit Summary — 2026-05-15 to 2026-05-22

## Dispatches: 42 (3 with non-empty reason)

## By agent
| Agent                     | Count | p50 dur (ms) | p95 dur (ms) |
|---------------------------|-------|--------------|--------------|
| backend-engineer     | 14    | 18420        | 41200        |
| senior-tech-lead        |  9    |  6210        | 12800        |
| design-doc-writer         |  6    | 22100        | 38500        |
| pr-review-toolkit:...     |  5    |  4800        |  9100        |
| Explore                   |  4    |  2100        |  5300        |
| general-purpose           |  4    | 15400        | 29000        |

## Top 5 longest dispatches
| Agent                  | Task           | Duration (ms) | Files touched |
|------------------------|----------------|---------------|---------------|
| design-doc-writer      | URLSH-S03.04   | 51200         | 1             |
| backend-engineer  | URLSH-S03.04   | 47800         | 6             |
| backend-engineer  | URLSH-S03.05   | 41200         | 4             |
| design-doc-writer      | URLSH-S03.05   | 38500         | 1             |
| backend-engineer  | URLSH-S03.03   | 33100         | 5             |

## Top 10 most-touched files
| File                                         | Touches | Last touched         |
|----------------------------------------------|---------|----------------------|
| internal/usecase/shorten.go                  | 8       | 2026-05-22T07:21:14Z |
| internal/usecase/shorten_test.go             | 7       | 2026-05-22T07:21:14Z |
| internal/adapter/http/router.go              | 5       | 2026-05-21T14:03:09Z |
| ...                                          | ...     | ...                  |

## Recurring task IDs (multi-dispatch — retries / multi-phase)
| Task            | Dispatches |
|-----------------|------------|
| URLSH-S03.04    | 4          |
| URLSH-S03.05    | 3          |
| URLSH-S03.03    | 2          |

## Gate-failure indicator
3 events with a non-empty `reason` field. Inspect:
  jq -c 'select(.reason != "" and .reason != null)' docs/project/audit/2026-05.jsonl
```

## Common queries

| Intent | Flags | What it tells you |
|---|---|---|
| Weekly retro starter | (none — default) | Where the week went, by agent + file |
| Sprint close digest | `--sprint S03` | Sprint-wide dispatch shape + retries |
| Hot-file scan | `--top files --since 2026-05-01` | Which files have been agent-touched repeatedly (refactor candidates) |
| One agent's footprint | `--agent backend-engineer` | Latency profile + tasks owned by one specialist |
| Single-task forensics | `--task URLSH-S03.04` | Every dispatch + reviewer touch for one task ID |
| Slow-down diagnosis | (default) — read the "Top 5 longest" | Which dispatches dominated wall time |
| Multi-team comparison | `--since 2026-05-01 --until 2026-05-31` | Lifetime month roll-up; compare vs prior month manually |
| Failure audit | (default) — read the gate-failure count | Quick check: did anything stop on non-success last week? |

## Pre-flight

```bash
# Does the audit dir exist?
test -d docs/project/audit || echo "audit hook not enabled — see docs/setup/audit-trail.md §Hook configuration"

# Is jq installed?
command -v jq >/dev/null || echo "install jq: brew install jq (macOS) / apt install jq (Linux)"
```

If `docs/project/audit/` exists but is empty, the audit hook is wired but no agents have been dispatched since enablement — that's normal on a fresh template install.

## Rules

- **Never edit the audit JSONL files.** They are append-only ground truth. The skill is read-only.
- **Do not invent numbers.** If `duration_ms` is null on a row, exclude that row from p50 / p95 — do not fabricate a value.
- **Surface the script's output verbatim** unless the user asks for a follow-up. Do not paraphrase the digest into prose — the digest IS the answer.
- **Hand off to `references/jq-recipes.md`** when the user wants something the skill doesn't cover. The skill is the opinionated digest; the recipes are the escape hatch.

## See also

- [`docs/setup/audit-trail.md`](../../../docs/setup/audit-trail.md) — schema, retention, SIEM ingestion
- [`.claude/hooks/audit.sh`](../../hooks/audit.sh) — the hook that writes the JSONL
- [`docs/setup/compliance-mapping.md`](../../../docs/setup/compliance-mapping.md) — what audit fields satisfy which SOC2 / ISO controls
- [`references/jq-recipes.md`](references/jq-recipes.md) — ad-hoc `jq` one-liners for queries not covered by the skill
