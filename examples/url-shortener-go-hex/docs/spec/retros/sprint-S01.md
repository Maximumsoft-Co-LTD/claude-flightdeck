# Retro — Sprint S01 (Bootstrap)

> **Sprint:** S01
> **Theme:** hex skeleton, first feature end-to-end, smoke test
> **Window:** 2026-04-06 → 2026-04-17
> **Completion:** 5/5 tasks (100%)
> **Closed:** 2026-04-18

## Per-task summary

> Aggregated from the live mini-retros in `sprint-S01-tasks.md` (archived inline below — this was our first sprint so we kept the rolled-up form).

| Task | Outcome | Time (est → actual) | Quality signal | Notes |
|------|---------|---------------------|----------------|-------|
| URLSH-S01.01 | Done clean | 1.5d → 1d | 0 gate fixes | D001 was over-spec'd for M (had API contract section); deleted at the gate |
| URLSH-S01.02 | Done clean | 0.5d → 0.25d | 0 gate fixes | Sentence-test path worked — no doc, AC inline in sprint file |
| URLSH-S01.03 | Done clean | 1d → 1d | 0 gate fixes | Race-detector caught one missing mutex in tests |
| URLSH-S01.04 | Done with 1 follow-up | 3d → 4d | 1 gate fix (silent-failure-hunter caught swallowed `err` in `Save`) | Idempotency on duplicate body deferred → F0001 → consumed by URLSH-S02.03 |
| URLSH-S01.05 | Done clean | 0.5d → 1d | 0 gate fixes | Took longer because compose-up needed a working migration runner; punted to S02 |

## What went well

1. **Hex boundary held from day 1.** `hexagonal-reviewer` ran on every PR and never flagged a violation. _(cite: gate 3 logs across 5 PRs)._
2. **Sentence test (A005) worked.** URLSH-S01.02 and URLSH-S01.05 shipped without design docs because they passed the "describe the diff in one sentence" floor. Saved roughly 1.5 days of doc writing. _(cite: sprint timing log)._
3. **`make smoke` caught the integration gap in URLSH-S01.04.** The smoke test went red on duplicate `POST /shorten` because the in-memory store didn't deduplicate — bug found in CI, not in prod. _(cite: CI run #47 on PR #12)._

## What didn't go well

1. **D001 was M-tier but contained an API contract section.** That's L-tier scope.
   - _Root cause:_ design-doc-writer agent followed the full template without consulting `SIZE_TIERS.md` first.
   - _Fix-now:_ updated agent body to read `SIZE_TIERS.md` BEFORE drafting. Committed in `chore(agents): design-doc-writer reads SIZE_TIERS first` alongside this retro.
2. **URLSH-S01.04 missed the duplicate-body case.** `POST /shorten` returned 200 on a true conflict (existing code, different long URL) — caught by manual test, not by AC.
   - _Root cause:_ AC was "shorten returns 201 + code" — it didn't constrain the conflict case.
   - _Fix-now:_ AC line in the sprint template now requires an explicit conflict / negative case per write endpoint. Filed as F0001.
3. **No live mini-retro discipline.** We wrote per-task summaries after the fact, from git logs + memory.
   - _Root cause:_ A009 (live mini-retro per task) hadn't been promoted to the brain-hot pin list yet — added in this retro.
   - _Fix-now:_ A009 promoted to brain-hot.md; orchestrator now refuses to mark a task Done without a mini-retro row.

## Drift findings

| Invariant | Drift | Found by | Action |
|-----------|-------|----------|--------|
| Hex boundary | none | `hexagonal-reviewer` | n/a |
| Contract drift | n/a (no contracts yet) | grep | n/a |
| Observability gap | `GET /healthz` returns build SHA but `GET /{code}` has no `latency_ms` metric | manual review | filed as deferred — picked up by D004 / S02 |

## Candidate A-rules (proposed → may be promoted at S02 or later)

- **A011 (candidate)** — Every new endpoint commits with a smoke-test step in the same PR. Rationale: URLSH-S01.05 caught a real issue precisely because the smoke test landed in the same PR as URLSH-S01.04. **Status: candidate.** Will be re-evaluated at S02; promoted formally only after a 2nd occurrence (per the recurring-lesson rule).

> Formal promotion of A012 (cache-layer TTL + invalidation) happens at S02 — it's the recurring-lesson cousin to A011.

## Backlog audit (HARD gate)

```
grep -nE "S01\b" docs/spec/backlog.md | grep -vE "done S01|\[~\] Partial|moved to S"
```

- Result: **0 mismatches.** 3 rows tagged S01 (B001, B002, B003); all three closed as `done S01`.
- Backlog audit: 3/3 rows matched · 0 mismatches ✅

## Follow-ups touched

> Single source-of-truth: [`../FOLLOWUPS.md`](../FOLLOWUPS.md). This table mirrors the deltas this retro made.

| F#### | Status change | Consumed by |
|-------|---------------|-------------|
| F0001 | new — appended | (planned for S02; consumed by URLSH-S02.03 at S02 close) |

- Follow-ups scanned: 0 (first sprint — FOLLOWUPS.md was empty) → 1 new appended.

## Action items

| # | Item | Classification | Owner | Landed this commit? |
|---|------|----------------|-------|---------------------|
| 1 | Add `SIZE_TIERS` read step to `design-doc-writer` body | fix-now | @alice | ✅ |
| 2 | Promote A009 (live mini-retro) to brain-hot pin list | fix-now | @alice | ✅ |
| 3 | Update sprint template AC line to require negative cases for write endpoints | fix-now | @alice | ✅ |
| 4 | Re-evaluate A011 candidate at S02 | defer | (orchestrator) | — |

## Recurring lessons promoted to rules

None this sprint — first occurrence of each lesson. A011 stays a candidate until S02 confirms recurrence.

## Lessons learned (appended to brain-hot.md)

- **L201** (proposed in S02 — drafted here): every new cache layer ships with both TTL and invalidation hook in the same PR. (Background context surfaced by the URLSH-S01.04 in-memory store work where a `purge` method was missing.)
- A009 promotion ratified.
