# Follow-ups — url-shortener

> Sometimes called "carry-overs" in older docs — same thing.

Items surfaced by past retros that didn't fit their original scope.
`sprint-retro-author` (and `/retro` at sprint close) **appends** here.
Before kicking off a new sprint or design doc, the orchestrator
**reads this file** and asks whether any open item is now in scope.
When a sprint or task consumes a follow-up, mark its status
`consumed-by:<task-id>` and **move the row to `## Closed` at sprint
close** — Closed is the audit trail; Open stays scannable.

## Open

| ID | From task / sprint | Item | Type | Priority | Date opened | Owner | Status |
|----|--------------------|------|------|----------|-------------|-------|--------|
| F0002 | URLSH-S02.03 / S02 | Idempotency-Key middleware accepts any string — should reject keys >128 chars and non-ASCII; surfaced when fuzz tests crashed sqlx parameter binding | fix | high | 2026-04-29 | @alice | open |
| F0005 | URLSH-S02.04 / S02 | `urlcache.Redis` config struct duplicated across `cmd/server` and `cmd/rollup-worker` — extract to `internal/config/cache.go` | refactor | med | 2026-04-30 | unassigned | open |
| F0006 | URLSH-S03.01 / S03 | Click-tracking middleware allocates a new `bytes.Buffer` per request; pool it once we see allocs in pprof | refactor | med | 2026-05-12 | unassigned | open |
| F0008 | URLSH-S03.01 / S03 | README still says "POST /api/v1/shorten" — the actual route is `POST /shorten`; update + add a route table | chore | low | 2026-05-14 | unassigned | open |

## Closed

Items consumed by a later task or marked `wont-do`. Schema is a
**superset** of `## Open` (same eight columns plus `Consumed by` and
`Date consumed`) so a row moves Open → Closed by appending two cells
without rewriting the row.

| ID | From task / sprint | Item | Type | Priority | Date opened | Owner | Status | Consumed by | Date consumed |
|----|--------------------|------|------|----------|-------------|-------|--------|-------------|---------------|
| F0001 | URLSH-S01.04 / S01 | `POST /shorten` returns 200 on conflict (existing code); should be 200 OR 409 depending on whether body matches existing row | fix | high | 2026-04-15 | @alice | consumed-by:URLSH-S02.03 | URLSH-S02.03 | 2026-04-27 |
| F0003 | URLSH-S02.04 / S02 | Cache invalidation hook missing on the "regenerate after wont-do" branch — found by manual test, no automated coverage yet | fix | high | 2026-04-29 | @bob | consumed-by:URLSH-S02.06 | URLSH-S02.06 | 2026-04-30 |
| F0004 | URLSH-S02.05 / S02 | The Redis read path was deferred mid-sprint; track as a hot-cache follow-up so it lands cleanly in S03 | feat | high | 2026-04-30 | @bob | consumed-by:URLSH-S03.02 | URLSH-S03.02 | 2026-05-04 |
| F0007 | URLSH-S03.01 / S03 | Daily rollup design doc D007 missed the `tenant_id` column in `clicks_daily` — added during impl, but doc lagged | docs | low | 2026-05-12 | @alice | consumed-by:URLSH-S03.01 | URLSH-S03.01 | 2026-05-13 |

## Conventions

- **ID** — `F` + 4-digit counter, monotonically increasing across all retros. The next retro picks the next free number by looking at the tail of this file. **Next free ID: F0009.**
- **From task / sprint** — the task or sprint ID where the follow-up surfaced (e.g. `URLSH-S03.04`).
- **Type** — what *kind* of work would consume this. Not binding; `design-doc-writer` can override after the interview / discovery step. Values match the phase matrix: `feat | fix | refactor | chore | docs | spike | release`.
- **Priority** — `low | med | high`. Reserve `high` for known-broken behaviour, security follow-up, or items blocking another track.
- **Date opened** — ISO date (`YYYY-MM-DD`) the row was first appended. Lets `/next-task` age out stale follow-ups.
- **Owner** — assignee handle if known; default `unassigned`.
- **Status** — `open | in-progress | consumed-by:<task-id> | wont-do (reason)`.

## Concurrency note (parallel-worktree safety)

`F####` ID assignment **serializes through the integration base**.
Never edit `FOLLOWUPS.md` from a parallel worktree — two concurrent
retros will both grab the same next ID and silently collide on merge.
At sprint close the integration session is the only writer; live
mini-retros append to the per-sprint task-retro file (no F### needed
until aggregation).

## See also

- `.claude/skills/retro/SKILL.md` — sprint close runner; touches this file
- `.claude/agents/sprint-retro-author.md` — the agent doing the append
- `docs/playbooks/parallel-conflict-prevention.md` — why ID assignment must serialize
