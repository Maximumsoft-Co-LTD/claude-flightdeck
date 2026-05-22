# url-shortener — Backlog

> **Track**: url-shortener (`urlsh-`)
> **Source-of-truth**: this file. `STATUS.md` reflects the row of the active sprint.
> **Discipline**: append-only; close items by changing status, never delete. Re-prioritize via row order.
> **Last updated**: 2026-05-21
> **Next ID**: B017

Backlog row format reference → [`../designs/_templates/BACKLOG_ENTRY_TEMPLATE.md`](../designs/_templates/BACKLOG_ENTRY_TEMPLATE.md).

## Complexity Scale

| Size | Estimate | Example |
|------|----------|---------|
| S | ~1 task group | Seed data, simple config |
| M | ~2-3 task groups | CRUD backend or frontend |
| L | ~4-6 task groups | Full feature (backend + frontend + tests) |
| XL | ~7+ task groups | Complex feature (real-time, multi-repo, etc.) |

---

## Unscheduled

> Items not yet assigned to a sprint, sorted by priority (P0 first).

| ID | Type | Title | Pri | Size | Status |
|----|------|-------|-----|------|--------|
| B013 | feat | **Per-tenant rate limit** — token bucket keyed on `tenant_id`, exposed via 429 + `Retry-After` | P1 | M | new |
| B014 | feat | **Abuse signal — malicious URL list** — block on shorten if target host matches Google Safe Browsing | P1 | L | new |
| B015 | enh | **Bulk shorten endpoint** — accept ≤500 URLs in one request, return per-row results | P2 | M | new |
| B016 | debt | **Drop the in-memory `urlrepo.Store`** — only used in tests; replace test fixtures with the Postgres adapter via testcontainers | P3 | S | new |

---

## Scheduled

> Items assigned to a sprint, grouped by sprint number.

### Sprint S03 (current)

| ID | Type | Title | Pri | Size | Status |
|----|------|-------|-----|------|--------|
| B008 | feat | **Click tracking** — record every redirect to `clicks` table with referrer/UA hash | P0 | M | done S03 |
| B009 | feat | **Redis hot cache for resolver** — cache-aside read path on `GET /{code}` with TTL + invalidation | P0 | M | scheduled S03 |
| B010 | feat | **Daily click rollup job** — cron consumer aggregates `clicks` → `clicks_daily` | P1 | M | scheduled S03 |
| B011 | feat | **Admin reporting endpoint** — `GET /admin/v1/links/{code}/stats` returns rollup | P1 | M | scheduled S03 |
| B012 | docs | **Typo fix — admin page title** — "Url Shortner" → "URL Shortener" | P3 | XS | scheduled S03 |

---

## Recently Done

> Move here once a task is closed in the sprint. Move to `## Archive` (collapsed) after a few sprints.

### Sprint S02

| ID | Type | Title | Pri | Size | Status |
|----|------|-------|-----|------|--------|
| B004 | feat | **Postgres adapter** — sqlx-based `urlrepo.Store` implementation + golang-migrate runner | P0 | L | done S02 |
| B005 | feat | **Idempotency-Key middleware** — `POST /shorten` honours header; conflict replays prior response | P0 | M | done S02 |
| B006 | feat | **Redis cache wiring** — `urlcache.Redis` adapter with TTL + invalidation hook (read path partial, completed in S03 as B009) | P1 | M | done S02 |
| B007 | fix | **Cache stale TTL on shortcode reuse** — invalidation hook missed the "regenerate after wont-do" branch | P1 | S | done S02 |

### Sprint S01

| ID | Type | Title | Pri | Size | Status |
|----|------|-------|-----|------|--------|
| B001 | feat | **Hex skeleton + healthz** — `cmd/server`, ports & adapters layout, `GET /healthz` returns build SHA | P0 | M | done S01 |
| B002 | feat | **In-memory `urlrepo.Store`** — concurrent-safe map-backed store for tests + dev | P0 | S | done S01 |
| B003 | feat | **First redirect handler** — `POST /shorten` + `GET /{code}` end-to-end with smoke test | P0 | L | done S01 |

---

## Archive

<details>
<summary>Completed items (older sprints — none yet, S01 + S02 still visible above)</summary>

| ID | Type | Title | Pri | Size | Status |
|----|------|-------|-----|------|--------|

</details>

---

## Detail blocks

<details>
<summary>B009 — Redis hot cache for resolver (active task URLSH-S03.02)</summary>

**Source:** D008 (`docs/designs/sprint-S03/D008-redis-hot-cache.md`)
**Dependencies:** B006 (related — wiring already landed in S02), B007 (related — same `urlcache.Redis` adapter; the fix exposed the missing invalidation hook on regenerate)

**Key AC:**
- Cache-aside read on `GET /{code}` — miss falls through to Postgres
- TTL configurable (default 5 min); invalidation on shorten / delete / regenerate (consumes F0003)
- Hit-rate metric `urlsh_cache_hits_total{result="hit|miss"}` exposed on `/metrics`

</details>

<details>
<summary>B011 — Admin reporting endpoint</summary>

**Source:** scheduled from S03 planning; no discovery doc
**Dependencies:** B008 (blocks — needs click tracking), B010 (blocks — reads from `clicks_daily`)

**Key AC:**
- `GET /admin/v1/links/{code}/stats?from=YYYY-MM-DD&to=YYYY-MM-DD` returns daily series
- Auth: admin role only (403 for everyone else — see future RBAC pass in S04)
- Response shape matches the contract pinned in D007 §3

</details>

<details>
<summary>B014 — Abuse signal — malicious URL list</summary>

**Source:** raised by @platform-team in S02 retro; awaiting prioritisation
**Dependencies:** B013 (related — same admin tooling will tune both)

**Key AC:**
- On shorten, look up target host against Google Safe Browsing v4
- Block + 422 if listed; log signal even when allowed (for future per-tenant scoring)
- Async refresh of local Bloom filter every 6h to keep p99 < 5ms

</details>
