# url-shortener — AI-Workflows sample (artifact tour)

You are looking at what an AI-Workflows-driven project looks like
**after 3 sprints of real adoption**. There is no Go code in this
directory — the leverage is the *control-plane artifacts* — but
everything is internally consistent: a task ID in
`sprints/sprint-S02.md` matches a row in `backlog.md`, a design doc
in `docs/designs/sprint-S02/`, a follow-up in `FOLLOWUPS.md`, and a
per-task summary in `retros/sprint-S02.md`.

The fictional project is an internal URL shortener for marketing
campaigns. Go (hex layout), Postgres for storage, Redis for hot
cache. Three sprints in: bootstrap (S01), persistence (S02), now
in-flight on analytics (S03).

## The 3 sprints at a glance

| Sprint | Theme | Status | What you'll see in the artifacts |
|--------|-------|--------|----------------------------------|
| S01 | Bootstrap (hex skeleton, healthz, first redirect, smoke) | ✅ Closed (5/5) | Closed prose archived; M-tier + L-tier design docs; first retro with a candidate A-rule |
| S02 | Persistence (Postgres, migrations, idempotency, Redis cache wiring) | ✅ Closed (5/6 + 1 partial) | A real "partial" task — `URLSH-S02.05` shipped wiring but the read path moved to S03; L-tier persistence design doc; A012 formally promoted; an S-tier `fix` design that shows the regression-first pattern |
| S03 | Analytics (click tracking, daily rollup, admin reporting) | 🟢 Active | Live mini-retros for the 2 completed tasks; in-progress design docs; an XS design doc; the active task `URLSH-S03.02` (Redis hot cache) explicitly consumes the S02 follow-up F0004 |

## Suggested reading order (≈20 min)

Walk these in order — each one references the next, and the chain
builds the mental model of the AI-Workflows discipline.

### 1. [`docs/project/STATUS.md`](./docs/project/STATUS.md) (~30 lines, ~1 min)

The **single-pane glance**. One row per active track. Today it says
S03 is active, the in-flight task is `URLSH-S03.02`, branch is
`feat/urlsh-s03.02-redis-cache`. **Notice what's NOT here:** no
historical prose, no sprint logs, no commentary on S01 or S02 —
just current-sprint pointer. That discipline is A008.

### 2. [`docs/project/sprints/sprint-S03.md`](./docs/project/sprints/sprint-S03.md) (~80 lines, ~3 min)

The current sprint's task table. Notice the mix of statuses:
`[x] Done`, `[~] In Progress`, `[ ] Not Started`. Each row points
to a design doc by ID. URLSH-S03.02 (active) points to D008.
URLSH-S03.05 is XS — single `docs` task — and still has a design
doc (D009) so you can see what XS looks like in practice.

### 3. [`docs/designs/sprint-S03/D008-redis-hot-cache.md`](./docs/designs/sprint-S03/D008-redis-hot-cache.md) (~220 lines, ~5 min)

The **active task's design doc**. M-tier, in-progress. Notice:
- it explicitly consumes follow-up F0004 (from S02)
- it cites A012 (cache layer rule) and L201 (clock-mock lesson) —
  rules promoted at the S02 retro
- AC7 (hexagonal-reviewer gate) is unchecked because the task is
  still mid-flight

### 4. [`docs/project/retros/sprint-S02.md`](./docs/project/retros/sprint-S02.md) (~120 lines, ~5 min)

The **closed-sprint retro** — the most-information-dense file in
the tour. Notice:
- the **per-task summary** table (one row per task, six fields)
- the "what didn't go well" items have **root causes + fix-now
  actions that landed in this commit** — not deferred
- L201 is captured as a recurring lesson and **A012 is formally
  promoted** because it's the 2nd occurrence
- the **backlog audit (HARD gate)** shows 4/4 matches, 0 mismatches
- the FOLLOWUPS table shows the deltas (1 consumed, 4 new, 0
  sprint-touched rows left open) — the gate that protects the
  audit trail

### 5. [`docs/project/FOLLOWUPS.md`](./docs/project/FOLLOWUPS.md) (~80 lines, ~3 min)

The **follow-up registry**. 8 rows total: 4 open, 4 closed. Trace
F0004 backwards: it was opened by URLSH-S02.05 partial decision in
S02, planned for S03 consumption, and is being closed right now by
URLSH-S03.02 (the active task). Cross-reference with D008 §1 ("In
scope: consume F0004 ✓"). This is the **audit trail** working as
designed.

### 6. [`docs/project/STATUS-archive.md`](./docs/project/STATUS-archive.md) (~80 lines, ~2 min)

The **closed-sprint prose**, newest first. The S02 + S01 closing
notes that used to live in STATUS.md have been moved here verbatim,
each in their own commit (per the STATUS update protocol). This is
where you read the project's narrative arc — the row in STATUS.md
is just a pointer.

### 7. Optional — pick one to round out the depth

- [`docs/designs/sprint-S02/D004-postgres-persistence.md`](./docs/designs/sprint-S02/D004-postgres-persistence.md) (~280 lines) — what a **zero-fix L-tier** design doc looks like at full depth: before/after architecture, key decisions with alternatives, files-touched matrix, step-by-step with verify clauses + AC tags, risks table, rollback runbook, observability table.
- [`docs/designs/sprint-S02/D006-fix-cache-stale-ttl.md`](./docs/designs/sprint-S02/D006-fix-cache-stale-ttl.md) (~100 lines) — what an **S-tier `fix`** looks like with the regression-test-first pattern (Step 1 = failing test that proves the bug).
- [`docs/designs/sprint-S03/D009-typo-fix-admin-page-title.md`](./docs/designs/sprint-S03/D009-typo-fix-admin-page-title.md) (~30 lines) — what an **XS** design doc actually looks like (most sections deleted, not stubbed).

## What you should take away

After the tour you should be able to answer:

1. **Where does current state live?** `STATUS.md` (single row), `sprints/sprint-S<N>.md` (active task table), `retros/sprint-S<N>-tasks.md` (live mini-retros).
2. **How does work move from "I noticed a thing" to "we shipped it"?** Follow-up appended at retro → reviewed at next sprint open → consumed by a sprint task → marked `consumed-by:` and moved to Closed at sprint close.
3. **Why three different design-doc tiers (XS / S / M / L)?** Same template, deleted sections at smaller tiers — see [`SIZE_TIERS.md`](../../core/docs/designs/_templates/SIZE_TIERS.md). XS = no logic, no behaviour change. L = breaking contract OR multi-subsystem.
4. **How does a lesson become a rule?** Surface in retro → captured as `L###` in brain-hot.md → on 2nd occurrence, promoted to `A0##` project rule (see A012 promotion in [`retros/sprint-S02.md`](./docs/project/retros/sprint-S02.md)).
5. **What's the audit trail?** Every claim in this tour is checkable by `grep` — task IDs, design IDs, follow-up IDs, A-rule IDs, branch names — they all resolve.

## File map

```
url-shortener-go-hex/
├── README.md                           ← you are here
└── docs/
    ├── project/
    │   ├── STATUS.md                   ← live single-pane glance (current sprint only)
    │   ├── STATUS-archive.md           ← closed-sprint prose (newest first)
    │   ├── backlog.md                  ← all work, ever
    │   ├── FOLLOWUPS.md                ← follow-up registry (4 open, 4 closed)
    │   ├── sprints/
    │   │   ├── sprint-S01.md           ← 5 tasks, all done
    │   │   ├── sprint-S02.md           ← 5 done + 1 partial
    │   │   └── sprint-S03.md           ← 1 done + 1 in-progress + 3 not-started
    │   └── retros/
    │       ├── sprint-S01.md           ← first retro; A011 candidate proposed
    │       ├── sprint-S02.md           ← A012 promoted; L201, L202 captured
    │       └── sprint-S03-tasks.md     ← live mini-retros (S03 ongoing)
    └── designs/
        ├── sprint-S01/
        │   ├── D001-hex-skeleton.md                       (M)
        │   └── D003-first-redirect-handler.md             (L)
        ├── sprint-S02/
        │   ├── D004-postgres-persistence.md               (L)
        │   └── D006-fix-cache-stale-ttl.md                (S, light template)
        └── sprint-S03/
            ├── D007-click-tracking.md                     (M)
            ├── D008-redis-hot-cache.md                    (M, active)
            └── D009-typo-fix-admin-page-title.md          (XS)
```

## Out of scope (deliberately)

This sample contains zero Go source code. The point is to show the
**process artifacts** — what STATUS.md, FOLLOWUPS.md, sprint files,
retros, and design docs look like *after* the workflow has been
applied for three sprints. If you want to see the workflow being
applied to actual code in a real codebase, the AI-Workflows template
is what you install — this sample is what you should expect to look
like in 8–12 weeks of using it.
