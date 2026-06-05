# Retro — Sprint S02 (Persistence)

> **Sprint:** S02
> **Theme:** Postgres adapter, migrations, Idempotency-Key, Redis cache wiring
> **Window:** 2026-04-20 → 2026-05-01
> **Completion:** 5/6 tasks done + 1 partial (83%)
> **Closed:** 2026-05-02

## Per-task summary

> Aggregated from `sprint-S02-tasks.md` (live mini-retros, written per task during the sprint).

| Task | Outcome | Time (est → actual) | Quality signal | Notes |
|------|---------|---------------------|----------------|-------|
| URLSH-S02.01 | Done clean | 1d → 1d | 0 gate fixes | golang-migrate runner reused from `aggegator` retro template |
| URLSH-S02.02 | Done clean | 4d → 4.5d | 2 gate fixes (code-reviewer flagged `*sql.Tx` leaking through the port; refactor lifted it behind `Store`) | testcontainers cold-start was the long tail; pre-warmed in `make ci-setup` |
| URLSH-S02.03 | Done clean | 2d → 2d | 1 gate fix (silent-failure-hunter: replay path swallowed Redis error on prior-response lookup) | Consumed F0001 from S01 (duplicate-body 409 semantic) |
| URLSH-S02.04 | Done with drift | 2d → 3d | 1 gate fix (hexagonal-reviewer flagged config struct in `cmd/server` referencing adapter directly) | **No design doc** — see drift finding below. Filed F0005 (refactor) for the duplication. |
| URLSH-S02.05 | Partial | 2d → 1d done, then deferred | n/a (deferred mid-sprint) | Read path lifted out — see L201 + F0004 |
| URLSH-S02.06 | Done clean | 0.5d → 0.5d | 0 gate fixes | Canonical fix-with-regression-test path; design [`D006`](../../project/sprints/S02/designs/D006-fix-cache-stale-ttl.md); consumed F0003 |

## What went well

1. **Idempotency-Key middleware shipped clean against fuzz.** Property-based tests covered same-key/same-body, same-key/different-body, and the 64KB-body upper bound. Caught one bug at write-time (not gate). _(cite: `internal/middleware/idempotency_test.go` table-test list)._
2. **L201 was caught mid-sprint, not at retro.** When the read-path adapter started ballooning, @bob stopped, raised the partial flag, opened F0004, and rolled URLSH-S02.05 into S03. Saved ~3 days of "almost done" thrash. _(cite: live mini-retro for URLSH-S02.05)._
3. **D004 paid for itself.** L-tier design doc was 280 lines; impl took 4.5 days with only 2 small gate fixes. Compare with URLSH-S02.04 (no design doc) — 1 gate fix + 1 drift finding. _(cite: gate logs)._

## What didn't go well

1. **URLSH-S02.04 shipped without a design doc.** The cache wiring "felt small enough" to skip the doc.
   - _Root cause:_ A005 sentence-test passed superficially ("add Redis adapter") but the actual work (config struct, TTL handling, invalidation hook contract) was M-tier and deserved a doc.
   - _Fix-now:_ tightened the A005 sentence-test wording in `brain-hot.md` to require the sentence to cover the *contract*, not just the *change*. Promoted A012 (see below). Committed in `docs(rules): A005 sentence-test now contract-aware` alongside this retro.
2. **L201 — Redis cache invalidation needed a cleanup goroutine; timer drift wasn't caught until staging.**
   - _Root cause:_ Cache invalidation tests asserted on the invalidation call, not on actual eviction; the cleanup goroutine started 30s late under load, causing stale reads for the first 30s after a regen. Found by the manual staging check that produced F0003.
   - _Fix-now:_ added a deterministic cleanup-tick test using `clock.Mock`. Updated `D004` §6 test plan to require a determinism check for any background goroutine. Updated `brain-hot.md` with L201. Committed in `fix(test): D004 test plan requires clock-mock for background ticks`.
3. **Partial-task communication was ad-hoc.** URLSH-S02.05's partial status was noted in mini-retro but not surfaced to the sprint file until the close.
   - _Root cause:_ no rule forced sprint-file update at partial-decision time.
   - _Fix-now:_ `agent-pre-task-ritual.md` Step 6 cleanup now requires immediate sprint-file row update on partial / deferred decision — not just at task complete. Committed in `chore(rules): update sprint file at partial-decision time`.

## Drift findings

| Invariant | Drift | Found by | Action |
|-----------|-------|----------|--------|
| Hex boundary | none in shipped code; near-miss in URLSH-S02.04 (config struct referenced `redis.Options` from `cmd/server`) | `hexagonal-reviewer` at PR gate | refactored before merge; filed F0005 for the wider config-struct duplication |
| Schema drift | none — `migrate up` clean from empty DB | grep + manual | n/a |
| Observability gap | `urlrepo` adapters had no `db_query_duration_seconds` metric | manual | filed as backlog item B016 (debt) |
| Contract drift | none — `POST /shorten` request shape unchanged | grep | n/a |

## Recurring lessons promoted to rules

**A012 — promoted (2nd occurrence).**
> *Every new cache layer ships with both TTL config and invalidation hook in the same PR. The hook MUST have a determinism test (clock-mock) for any background tick.*

- 1st occurrence: surfaced as L201 in [S01 retro](./sprint-S01.md) (purge-method gap on the in-memory store).
- 2nd occurrence: URLSH-S02.04's invalidation gap + L201 (timer drift under load).
- Cited evidence: see "What didn't go well" item 2 above + S01 retro lesson row.
- Promoted: appended to [`brain-hot.md`](../../../.claude/rules/brain-hot.md) project-rules section as A012. Committed in `docs(rules): promote A012 cache TTL+invalidation`.

## Backlog audit (HARD gate)

```
grep -nE "S02\b" docs/project/backlog.md | grep -vE "done S02|\[~\] Partial|moved to S"
```

- Result: **0 mismatches.** 4 rows tagged S02 (B004, B005, B006, B007); all four closed as `done S02`. URLSH-S02.05 partial state cross-referenced URLSH-S03.02 in sprint-S02.md row; no orphan rows.
- Backlog audit: 4/4 rows matched · 0 mismatches ✅

## Follow-ups touched

| F#### | Status change | Consumed by |
|-------|---------------|-------------|
| F0001 | open → closed | URLSH-S02.03 (idempotency middleware) |
| F0002 | new — appended | (deferred — open, priority high) |
| F0003 | new → closed in-sprint | URLSH-S02.06 (fix: cache stale TTL on regenerate) |
| F0004 | new — appended | (planned for S03 — consumed by URLSH-S03.02 at S03 open) |
| F0005 | new — appended | (unscheduled, refactor med) |

- Follow-ups scanned: 1 (F0001 carry-over from S01) → 1 consumed · 4 new · 0 sprint-touched rows left as open.

## Action items

| # | Item | Classification | Owner | Landed this commit? |
|---|------|----------------|-------|---------------------|
| 1 | Promote A012 (cache TTL + invalidation) to brain-hot rules | fix-now | @alice | ✅ |
| 2 | Tighten A005 sentence-test wording (contract-aware) | fix-now | @alice | ✅ |
| 3 | Require clock-mock determinism test for background ticks | fix-now | @bob | ✅ (D004 §6 updated) |
| 4 | Sprint file update at partial-decision time (not just at complete) | fix-now | @alice | ✅ (agent-pre-task-ritual.md Step 6) |
| 5 | Pre-warm testcontainers in `make ci-setup` (CI tail length) | defer (S03 chore) | @bob | — |

## Lessons learned (appended to brain-hot.md)

- **L201** — Cache invalidation must be tested with a clock-mock; asserting on the invalidation *call* is insufficient because background ticks can drift under load.
- **L202** — A005 sentence-test should describe the *contract* (new public surface, error semantic, side-effect), not just the *code change*. "Add Redis adapter" fails the test; "add `urlcache.Redis` with TTL config + invalidation hook on save/delete" passes.
- A012 ratified as a project rule.

## Sprint-close commits (this retro produced)

```
docs(retro): close sprint S02; A012 promoted; L201 + L202 captured
docs(rules): A005 sentence-test now contract-aware
fix(test): D004 test plan requires clock-mock for background ticks
docs(rules): promote A012 cache TTL+invalidation
chore(rules): update sprint file at partial-decision time
docs(status): url-shortener move S02 prose to STATUS-archive
```
