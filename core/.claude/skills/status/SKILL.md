---
name: status
description: "Use when the user says '/status', 'where are we', 'sprint status', 'dashboard', 'what's blocked', 'show status', 'how's the sprint going', or wants a mid-sprint check-in. Also use for '/status audit', 'audit summary', 'where did time go', 'which agent is slowest', or weekly / sprint-end insights from the audit log. Two read-only modes: `/status` prints a sprint progress dashboard (completion %, blockers, per-component breakdown); `/status audit [week|sprint]` aggregates docs/project/audit/*.jsonl into a digest. Never writes."
user_invocable: true
---

# /status — Sprint Dashboard + Audit Digest

Read-only. Never writes, never edits any file.

**Announce:** Using /status — [sprint dashboard / audit digest].

## Token budget

**Dashboard** (`/status`):
- One `Read` of the active board (`limit: 200`) — header + task table.
- All other queries via `Grep` (status counts, blockers, per-component rollup).
- Scope any `git log` to the sprint window only (stale-task detection).

**Audit** (`/status audit`):
- Delegate to `scripts/query.sh` — all JSONL aggregation happens in `jq` + bash.
- Do NOT `Read` audit JSONL into model context (can be megabytes/month); always
  pipe through the script, which emits markdown to stdout — surface it verbatim.

---

## Mode 1 — `/status` (sprint progress dashboard)

Reads `docs/project/sprints/S<N>/tasks.md` + `docs/project/backlog.md`.

1. **Find the active board** — `Glob docs/project/sprints/*/tasks.md`, pick the
   one whose Glance header marks it active.
2. **Read the task table** (`limit: 200`).
3. **Compute metrics** — Total / Done `[x]` / In-progress `[~]` / Not-started
   `[ ]` / Blocked `[B]` / completion %.
4. **Print the dashboard:**
   ```
   ## Sprint S<N>: <theme>
   Progress: [======>   ] X/Y (Z%)

   | Task ID | Component | State | Owner | Blocker |
   |---|---|---|---|---|
   ```
5. **Per-component / per-repo rollup:** `| Component | Done | In progress | Remaining |`.
6. **Flag stale tasks** — `[~]` for >2 days (board `Last update` or `git log -1`
   on the task's design doc).
7. **Scan `docs/project/backlog.md` `## Follow-ups`** for open items relevant to
   the sprint and list them.

**Rules:** read-only — never mutate. No active board → suggest `/work` to start
one or `/recover` if state is unclear.

---

## Mode 2 — `/status audit [week|sprint]` (audit digest)

Aggregates `docs/project/audit/*.jsonl` (written by `.claude/hooks/audit.sh`)
into a digest: dispatches per agent with p50/p95 latency, slowest dispatches,
file-touch hotspots, task-ID retry counts, gate-failure indicators. Raw `jq`
recipes for ad-hoc work: [`references/jq-recipes.md`](references/jq-recipes.md).

| Form | Effect |
|---|---|
| `/status audit` | default — last 7 days |
| `/status audit week` | last 7 days |
| `/status audit sprint` | dispatches whose `task_id` matches the active sprint (`*-S<N>.*`) |
| `/status audit --since 2026-05-01 [--until …]` | explicit window |
| `/status audit --agent backend-engineer` | filter by `subagent_type` |
| `/status audit --task {{TASK_ID_PREFIX}}-S03.04` | one task ID |
| `/status audit --top files\|tasks` | emphasize that section |

Flags are additive.

**Steps:** detect window → `Glob docs/project/audit/*.jsonl` (overlapping
`YYYY-MM` only) → run `scripts/query.sh` with the parsed flags (it streams the
matching lines through `jq`: group by `subagent_type` for counts + p50/p95
`duration_ms`; sort `duration_ms` desc for slowest-5; flatten `files_touched[]`
for the top-10 hotspot; group by `task_id` for retry indicators; count non-empty
`reason` as gate-failure signals) → surface the script output verbatim.

**Pre-flight:**
```bash
command -v jq >/dev/null || echo "install jq: brew install jq / apt install jq"
test -d docs/project/audit || echo "audit hook not enabled — see docs/setup/audit-trail.md"
```
Missing `jq` → install message. No `docs/project/audit/` → enable the hook. No
lines in window → suggest widening `--since`. Empty dir → normal on a fresh
install. **Never edit audit JSONL** (append-only ground truth); don't invent
numbers — drop null-`duration_ms` rows from p50/p95.

---

## See also

- [`../work/SKILL.md`](../work/SKILL.md) — drives the tasks this board tracks
- [`../retro/SKILL.md`](../retro/SKILL.md) — sprint close; reads the same board
- [`../../hooks/audit.sh`](../../hooks/audit.sh) — the hook that writes the JSONL
- [`../../../docs/setup/audit-trail.md`](../../../docs/setup/audit-trail.md) — schema, retention, SIEM ingestion
- [`references/jq-recipes.md`](references/jq-recipes.md) — ad-hoc `jq` one-liners
