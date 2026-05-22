# url-shortener — Status Archive

Closed-sprint prose lives here. **Move from `STATUS.md` in the SAME
commit that closes the sprint** — never append to a live `STATUS.md`
row, never delete prose from this file once it lands. The file is
append-only (newest at the top).

This file is the **historical narrative**. `STATUS.md` is the live
single-pane glance. `docs/spec/sprints/sprint-S<N>.md` is the per-task
detail. `docs/spec/retros/sprint-S<N>.md` is the per-sprint retro.
Together they form the audit trail.

## Conventions

- One H2 (`## Sprint S<N> — <theme>`) per closed sprint.
- Below the H2: the exact prose that was in the live `STATUS.md` row
  at sprint close. Verbatim move — do not summarize or rewrite.
- Optional: a 1-2 sentence post-mortem note added during the retro.
- Links to `docs/spec/sprints/sprint-S<N>.md` and
  `docs/spec/retros/sprint-S<N>.md` for detail.

## Closed sprints (newest first)

<!-- /retro appends new sprint blocks above this line. -->

## Sprint S02 — Persistence

_Closed 2026-05-01. Theme: Postgres adapter, migrations, Idempotency-Key, Redis cache wiring. Completion: 5/6 tasks done (83%); URLSH-S02.05 partial — Redis wiring landed but hot-path retrieval moved to S03._

**Verbatim from STATUS.md at sprint close (2026-05-01):**

> **S02 CLOSING ✅** — Persistence sprint. URLSH-S02.01 (schema + golang-migrate runner), URLSH-S02.02 (sqlx adapter implementing `urlrepo.Store`), URLSH-S02.03 (Idempotency-Key middleware with the conflict-replay semantic), and URLSH-S02.04 (TTL + invalidation hook on `urlcache.Redis`) all shipped clean through the 6-gate review. URLSH-S02.05 (Redis hot-path retrieval) landed only the wiring + interface; the actual cache-aside read path was pulled into S03 once we realised the analytics work needed the same code path. Branch `feat/urlsh-s02.04-redis-cache` merged into `main` 2026-04-30; S02 retro tomorrow.

- See [`sprints/sprint-S02.md`](./sprints/sprint-S02.md) for the task table.
- See [`retros/sprint-S02.md`](./retros/sprint-S02.md) for the retro (Aged-L201 lesson, A012 promoted, 1 follow-up consumed, 2 new opened).

---

## Sprint S01 — Bootstrap

_Closed 2026-04-17. Theme: hex skeleton, first feature end-to-end, smoke test. Completion: 5/5 tasks done (100%)._

**Verbatim from STATUS.md at sprint close (2026-04-17):**

> **S01 CLOSING ✅** — Bootstrap sprint. URLSH-S01.01 (cmd/server + ports & adapters skeleton, M-tier D001), URLSH-S01.02 (`GET /healthz`), URLSH-S01.03 (in-memory `urlrepo.Store` for tests + dev), URLSH-S01.04 (L-tier D003 — `GET /{code}` redirect + `POST /shorten`), URLSH-S01.05 (compose-up + curl-driven smoke test in `make smoke`) all landed clean. 5/5 tasks. Tag `v0.1.0` cut on `main`. Branch `feat/urlsh-s01.05-smoke-test` merged 2026-04-16; S01 retro tomorrow.

- See [`sprints/sprint-S01.md`](./sprints/sprint-S01.md) for the task table.
- See [`retros/sprint-S01.md`](./retros/sprint-S01.md) for the retro (proposed A011 "every endpoint commits with a smoke test in the same PR" — formally promoted at the close of S02).

---

## See also

- [`STATUS.md`](./STATUS.md) — live single-pane glance (current sprint only)
- [`backlog.md`](./backlog.md) — all work, ever
- [`FOLLOWUPS.md`](./FOLLOWUPS.md) — follow-up registry across sprints
- [`sprints/`](./sprints/) — per-sprint task tables
- [`retros/`](./retros/) — per-sprint retros
