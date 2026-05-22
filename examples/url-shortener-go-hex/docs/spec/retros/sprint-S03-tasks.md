# Live mini-retros — Sprint S03 (Analytics)

> One row per completed (or partially completed) task. Append immediately
> after task complete or partial-decision — do NOT batch at sprint
> close. This file feeds the full retro at S03 close
> (`sprint-S03.md`).
>
> Schema (6 fields): **task · what happened · blockers · time (est → actual) · quality signal · next**

---

## URLSH-S03.01 — Click-tracking middleware + `clicks` table

- **What happened:** Middleware wraps the redirect handler; emits async to a buffered channel + drain goroutine that batch-inserts into `clicks` (batch=200, flush=500ms). Hot path stayed flat: p99 measured 11.2ms vs 10.9ms baseline (+0.3ms — well under the +1ms AC). `tenant_id` column added to the migration during impl; design doc D007 updated to match (closed F0007).
- **Blockers:** Initial design (D007 v1) used a synchronous insert — caught at hexagonal-reviewer gate ("adapter blocks the hot path"). Rewrote to async with the drain pattern; cost ~0.5d.
- **Time (est → actual):** 3d → 3.5d
- **Quality signal:** 1 gate fix (boundary), 0 silent-failure-hunter findings, 2 new follow-ups (F0006 — pool the buffer; F0008 — README route table), 1 follow-up consumed in-sprint (F0007 — D007 lagged impl on `tenant_id`)
- **Next:** Daily rollup (URLSH-S03.03) consumes the `clicks` table; admin reporting (URLSH-S03.04) consumes the rollup output. F0006 stays open as low-priority refactor — not blocking S03.

---

## URLSH-S03.02 — Redis hot cache for resolver (read path) — _IN PROGRESS_

- **What happened (so far):** Wiring + interface from URLSH-S02.05 carried over (consumed F0004). Handler-side cache-aside read implemented; cache populate on miss; invalidation hook plumbed through `Save` / `Delete` / `Regenerate`. Hit-rate metric `urlsh_cache_hits_total{result="hit|miss"}` exposed on `/metrics`. Branch `feat/urlsh-s03.02-redis-cache` open; PR #47 pending hexagonal-reviewer gate.
- **Blockers:** Mid-task the cleanup goroutine from L201 (S02 lesson) needed the same clock-mock pattern from D004; cost ~0.5d but the determinism test caught a tick-drift bug at write-time, not gate. A012 rule saved a cycle here.
- **Time (est → actual):** 3d → 3d so far (gate not yet run)
- **Quality signal:** TBD — pending gate. Self-review checklist clean; 0 silent-failure-hunter findings on local pass.
- **Next:** Run hexagonal-reviewer + 6-gate post-delegation review. Mark Done once green. Will defer alerting threshold tuning (URLSH-S03.06) to S04 since we need 48h of cache-hit-rate baseline before tuning is meaningful — captured as a sprint-S03 plus-row in the sprint file.

---

<!-- Append future mini-retros below this line in the order tasks complete: -->
<!-- URLSH-S03.03, URLSH-S03.04, URLSH-S03.05 -->
