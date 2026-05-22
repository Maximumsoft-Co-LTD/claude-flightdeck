# Design: D006 — Fix cache stale TTL on shortcode reuse (Light)

> **Sprint:** S02 — Persistence
> **Task:** URLSH-S02.06
> **Repo:** backend
> **Status:** Done
> **Type:** fix
> **Size:** S  (per [`SIZE_TIERS.md`](../../_templates/SIZE_TIERS.md) — single bug fix, 2 files, regression test first per phase-matrix `fix` row)
> **Author:** design-doc-writer (refined by @bob)
> **Date:** 2026-04-29

## Overview

`urlcache.Redis` invalidation hook didn't fire on the `Regenerate`
branch — after a user marked a code `wont-do` and re-created a new
mapping for the same code via the admin path, the cache served the
old long URL for up to the TTL window (5 min). Manual test caught it
(F0003); no automated coverage.

This task is the canonical **regression-first fix** pattern per the
phase matrix: Step 1 is a failing test that proves the bug; Step 2 is
the minimal fix.

## Approach

The bug lives in two places:

- `internal/adapters/idempotencyrepo/redis.go` — wait, no. The bug is
  in `internal/adapters/cache/redis.go` (`urlcache.Redis`) — the
  `Invalidate(ctx, code)` method is implemented, but the *caller* in
  `internal/app/regenerate.go` doesn't call it on the regenerate
  branch (only on `Save` and `Delete`).

Fix: add the missing call in `app.Regenerate` and add a regression
test that proves a regenerate-after-wont-do returns the new long URL
(not the cached old one).

## Data Flow & Side-Effects (L023)

```
[Regenerate(code) — NEW correct flow]:
  1. urlrepo.Store.Save(ctx, code, newLongURL)
  2. → [Side-effect] urlcache.Redis.Invalidate(ctx, code)   ← the missing call
  3. Return new mapping
```

Compare with the **broken** flow before fix:

```
[Regenerate(code) — BROKEN]:
  1. urlrepo.Store.Save(ctx, code, newLongURL)
  2. (no invalidation — cache returns stale long URL for up to TTL)
  3. Return new mapping
```

## API Body Schema (L008/L020)

Unchanged — no public-surface change. `POST /admin/v1/links/{code}/regenerate`
still takes `{long_url}` and returns `{code, short_url, long_url}`.

## Test Plan

| Test | File | Expected | What it verifies |
|------|------|----------|------------------|
| `TestApp_Regenerate_InvalidatesCache` (NEW — regression) | `internal/app/regenerate_test.go` | RED before fix, GREEN after | After Save, mock cache receives Invalidate(code) with the right key |
| `TestApp_Regenerate_E2E_StaleReadGone` (NEW — integration) | `e2e/regenerate_test.go` | RED before fix, GREEN after | Full flow: Shorten → Resolve (warms cache) → Regenerate → Resolve again → returns NEW long URL within 1s |
| existing tests | `internal/app/*_test.go` | unchanged | no behavior change in Save / Delete paths |

## Tasks

> Ordered for regression-first per phase matrix `fix` row.

| # | Task | Status |
|---|------|--------|
| 1 | **Write the failing regression tests FIRST** — both unit + e2e (red on pre-fix branch); commit as a separate test-only commit so the gate can verify red-then-green | [x] |
| 2 | Add `urlcache.Redis.Invalidate(ctx, code)` call in `app.Regenerate` — one-line fix | [x] |
| 3 | Run both tests; both green | [x] |
| 4 | Run full test suite; no other tests changed | [x] |
| 5 | Verify F0003 row in [`../../spec/FOLLOWUPS.md`](../../spec/FOLLOWUPS.md) moves Open → Closed with `consumed-by:URLSH-S02.06` | [x] |

## Acceptance Criteria

- [x] Regression test `TestApp_Regenerate_InvalidatesCache` was red on the pre-fix commit and is green after the fix commit (gate verified by running on both SHAs)
- [x] Integration test `TestApp_Regenerate_E2E_StaleReadGone` passes
- [x] No other tests changed
- [x] F0003 closed with `consumed-by:URLSH-S02.06`
- [x] Live mini-retro row appended to `sprint-S02-tasks.md`

## Rollback

`git revert <merge-sha>` — single-commit fix, no schema / contract change. The regression test stays in the repo as a future safety net even after revert.

## Why this stays S-tier (not XS)

The fix is one line, but:
- it consumes an Open follow-up (F0003)
- the regression-test-first pattern (phase matrix `fix` row) requires deliberate sequencing
- the integration test crosses adapter + app boundary

XS work would be: bumping the TTL constant, fixing a typo in a metric
label, or renaming an internal variable. This is one tier up.
