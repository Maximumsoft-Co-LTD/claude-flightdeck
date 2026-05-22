# Sprint S03 — Analytics

> **Theme:** click tracking, daily rollup, admin reporting
> **Window:** 2026-05-04 → 2026-05-22
> **Status:** 🟢 Active (1 done, 1 in progress, 3 not started)
> **Live retro:** [`../retros/sprint-S03-tasks.md`](../retros/sprint-S03-tasks.md) (mini-retros appended per task; full retro at sprint close)

## Goal

Turn the shortener into a data product: record every redirect to a
`clicks` table without blocking the hot path, aggregate to
`clicks_daily` via a scheduled worker, and expose a minimal admin
reporting endpoint so the marketing team can self-serve campaign
performance. Side-mission: get the Redis hot-cache read path
(carried over as F0004 from S02) finally landed.

## Tasks

| ID | Title | Type | Size | Owner | Design doc | AC short | Status |
|----|-------|------|------|-------|------------|----------------------------------------------------------|--------|
| URLSH-S03.01 | Click-tracking middleware + `clicks` table | feat | M | @alice | [`D007`](../../designs/sprint-S03/D007-click-tracking.md) | Every `GET /{code}` writes a row; hot-path latency p99 ≤ +1ms vs baseline | [x] Done |
| URLSH-S03.02 | Redis hot cache for resolver (read path) | feat | M | @bob | [`D008`](../../designs/sprint-S03/D008-redis-hot-cache.md) | `GET /{code}` cache-aside; hit-rate metric exposed; invalidation on shorten/delete/regenerate | [~] In Progress — branch `feat/urlsh-s03.02-redis-cache`; awaiting hexagonal-reviewer gate |
| URLSH-S03.03 | Daily rollup worker — `cmd/rollup-worker` | feat | M | @alice | (rolled into D007 §4) | Cron at 00:15 UTC; aggregates last 24h `clicks` → `clicks_daily`; idempotent if re-run | [ ] Not Started |
| URLSH-S03.04 | Admin reporting endpoint — `GET /admin/v1/links/{code}/stats` | feat | M | @alice | — (design doc to be drafted; ticketed) | Returns daily series for `{from,to}`; admin-only (403 for others); pagination via `next_cursor` | [ ] Not Started |
| URLSH-S03.05 | **docs** Typo fix — admin page title | docs | XS | @bob | [`D009`](../../designs/sprint-S03/D009-typo-fix-admin-page-title.md) | Page title reads "URL Shortener" everywhere | [ ] Not Started |

## Plus (carryover, not counted toward sprint completion %)

- URLSH-S03.06 — alerting threshold tuning for `urlsh_cache_hit_rate{}` (will land once URLSH-S03.02 has produced 48h of baseline data; deferred from this sprint per [`../retros/sprint-S03-tasks.md`](../retros/sprint-S03-tasks.md) live entry)

## Acceptance gate (sprint close — anticipated)

- [ ] All 5 primary tasks Done or explicitly Partial-with-followup
- [ ] `make smoke` extended to include analytics happy-path (shorten → click → rollup → query stats)
- [ ] Hex boundary scan clean
- [ ] Backlog audit clean
- [ ] FOLLOWUPS.md: F0004 closed (consumed by URLSH-S03.02); F0006, F0007, F0008 reviewed; new follow-ups appended

## Notes during sprint

- URLSH-S03.01 surfaced two new follow-ups: F0006 (allocator pool) and F0008 (route table in README). F0007 (design doc lagged impl on `tenant_id`) was opened and closed in-sprint when D007 was updated.
- URLSH-S03.02 explicitly consumes F0004 (the deferred-from-S02 hot-cache read path).
- URLSH-S03.05 is the canonical XS example for this sample — see [`D009`](../../designs/sprint-S03/D009-typo-fix-admin-page-title.md) for what an XS design doc actually looks like.
