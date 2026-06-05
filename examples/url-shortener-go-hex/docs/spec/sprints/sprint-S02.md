# Sprint S02 — Persistence

> **Theme:** Postgres adapter, migrations, Idempotency-Key, Redis cache wiring
> **Window:** 2026-04-20 → 2026-05-01
> **Status:** ✅ Closed (5/6 done + 1 partial — 83%)
> **Retro:** [`../sprints/S02/retro.md`](../sprints/S02/retro.md)

## Goal

Replace the in-memory store with a durable Postgres adapter behind
the existing `urlrepo.Store` port, ship the migration runner, harden
`POST /shorten` against duplicate submissions via `Idempotency-Key`,
and wire Redis cache so S03's analytics workload starts on a hot
read path.

## Tasks

| ID | Title | Type | Size | Owner | Design doc | AC short | Status |
|----|-------|------|------|-------|------------|----------------------------------------------------------|--------|
| URLSH-S02.01 | Postgres schema + golang-migrate runner | feat | M | @alice | (rolled into D004) | `migrate up` clean from empty DB; idempotent re-run | [x] Done |
| URLSH-S02.02 | `urlrepo.Store` Postgres adapter (sqlx) | feat | L | @alice | [`D004`](../../project/sprints/S02/designs/D004-postgres-persistence.md) | Implements all `Store` methods; integration tests via testcontainers | [x] Done |
| URLSH-S02.03 | `Idempotency-Key` middleware on `POST /shorten` | feat | M | @alice | (rolled into D004 §3) | Same key + same body → replay 200; same key + different body → 422 | [x] Done |
| URLSH-S02.04 | Redis cache wiring — `urlcache.Redis` adapter | feat | M | @bob | [`D005-redis-cache-wiring.md`](#) (not written — see [`../sprints/S02/retro.md`](../sprints/S02/retro.md) §drift) | TTL config; invalidation hook on shorten / delete | [x] Done |
| URLSH-S02.05 | Hot-path Redis retrieval on `GET /{code}` | feat | M | @bob | — | Cache-aside read; miss → Postgres; populate on miss | [~] Partial — wiring + interface landed; the read-path adapter on the handler moved to S03 (URLSH-S03.02, design [`D008`](../../project/sprints/S03/designs/D008-redis-hot-cache.md)) because the analytics work demanded the same code path |
| URLSH-S02.06 | **fix** Cache stale TTL on shortcode reuse | fix | S | @bob | [`D006`](../../project/sprints/S02/designs/D006-fix-cache-stale-ttl.md) | Regression test red on pre-fix; green after; invalidation now fires on regenerate | [x] Done |

## Acceptance gate (sprint close)

- [x] `migrate up` runs clean on a fresh Postgres 15 container
- [x] Hex boundary scan reports 0 violations
- [x] All 6 rows have a row in [`../sprints/S02/retro.md`](../sprints/S02/retro.md) per-task summary
- [x] Backlog audit clean (mismatch = 0): URLSH-S02.05 marked `[~] Partial` + cross-ref to URLSH-S03.02; not silently dropped
- [x] [`../FOLLOWUPS.md`](../FOLLOWUPS.md): F0001 closed (consumed by URLSH-S02.03); F0002, F0003, F0004, F0005 opened; F0003 closed in-sprint (consumed by URLSH-S02.06)

## Notes during sprint

- URLSH-S02.04 originally planned for design doc D005 — the doc was never written; @bob lifted the design straight from D004 §4 (cache section) and the gate caught it. Filed as the L201 lesson + the A012 rule promoted at the S02 retro.
- URLSH-S02.06 is the canonical "fix" example for this sample — Step 1 is the failing regression test (per phase matrix). See [`D006`](../../project/sprints/S02/designs/D006-fix-cache-stale-ttl.md).
