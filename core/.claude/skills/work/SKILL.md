---
name: work
description: "Use when the user says '/work', 'what's next', 'next task', 'pick the next thing', 'continue the sprint', 'work on {{TASK_ID_PREFIX}}-S<N>.<NN>', 'do task NN', 'run these in parallel', or names one-or-more task IDs to execute. The single driver that turns a sprint task into shipped, reviewed code: it picks (or takes) the task, ensures a design doc exists (design-first), auto-decides serial-vs-parallel and fans out safely, then runs the 6-gate review on every result. Absorbs the old /next-task + /assign + /dispatch-parallel + /post-delegation-gate."
user_invocable: true
---

# /work — Pick · Design-First · Auto-Fanout · 6-Gate

**Announce:** Using /work to [pick the next task / execute {{TASK_ID_PREFIX}}-S<N>.<NN> / fan out N tasks].

One command from "a task exists" to "reviewed, ready to merge". It runs the
discipline for you — design-first (A005), the cost-aware fan-out decision
([`../../rules/sub-agent-workflow.md`](../../rules/sub-agent-workflow.md) §1.0/§1.5),
the 4-layer Conflict Radar
([`../../../docs/playbooks/parallel-conflict-prevention.md`](../../../docs/playbooks/parallel-conflict-prevention.md)),
and the mandatory 6-gate review
([`../../../docs/playbooks/post-delegation-review.md`](../../../docs/playbooks/post-delegation-review.md)).

## Token budget

- Read only the active board (`limit: 200`) + the candidate task's design doc.
  Everything else via `Grep` (frontier scan, path-overlap, contract scan).
- Dispatch implementation to a sub-agent via a **brief file**, never a long
  inline prompt (see `../../rules/sub-agent-workflow.md` §3).
- Don't re-Read what a returning agent reported; trust its summary, verify via
  the gates.

## Forms

| Form | Behaviour |
|---|---|
| `/work` | pick the next eligible task from the active board (old `/next-task`) |
| `/work {{TASK_ID_PREFIX}}-S<N>.<NN>` | execute that specific task (old `/assign`) |
| `/work A B C` | execute several — auto-fan-out the disjoint frontier (old `/dispatch-parallel`) |
| `/work --serial` | force one-at-a-time even if the frontier looks disjoint |

---

## Step A — Classify the work

0. **Ensure a sprint board exists.** If `docs/project/sprints/` has no active
   sprint folder (or its `tasks.md` is missing), scaffold one before picking a
   task: `mkdir -p docs/project/sprints/S<N>/designs/_briefs`, copy
   `docs/project/_templates/tasks.md` → `sprints/S<N>/tasks.md`, fill the Glance
   header, and pull in the backlog rows scheduled for this sprint
   (`Grep docs/project/backlog.md` for `scheduled S<N>`). This is how a sprint
   starts — there is no separate "new sprint" command.
1. **Identify the task(s).** No arg → scan `docs/project/sprints/S<N>/tasks.md`
   for the unblocked frontier (lowest priority-number first, dependencies met).
   Task ID(s) given → take those rows.
2. **Read the Type** of each → look up
   [`../../rules/phase-matrix.md`](../../rules/phase-matrix.md) for the phase list
   (which gates run / run-light / skip / trigger). **Quote the phase list back
   to the user before dispatch.**
3. **Readiness gate** — confirm dependencies done, acceptance criteria present,
   not already in flight. Block + report if not ready.

## Step A′ — Design-first (A005, folds in the old `/plan`)

A design doc must exist at `docs/project/sprints/S<N>/designs/D<NNN>-<slug>.md`
before any code.

- **Missing?** Dispatch `design-doc-writer` FIRST via a brief file
  (`designs/_briefs/<TASK_ID>-design.md`), size-tiered per
  [`../../../docs/designs/_templates/SIZE_TIERS.md`](../../../docs/designs/_templates/SIZE_TIERS.md)
  (XS/S → LIGHT, M/L → FULL). Surface its open questions / knowledge gaps and
  get approval before implementation.
- **Present?** Confirm its AC list + touched-files matrix, then continue.

> `chore` / `docs` skip the design doc per the phase matrix — don't force one.

## Step B — Width decision (before the Radar)

Default to **one** agent (`sub-agent-workflow.md` §1.0 — parallel costs ~15× and
its top failure is context fragmentation). Fan out only when work is **provably
disjoint AND write-isolated**. Force single when:

- frontier size = 1, or `--serial`, or
- the work is write-heavy on a **shared** surface (parallel writes carry
  conflicting implicit decisions — keep them serial), or
- you can't prove disjointness in under a minute.

Cap width: 1 simple · 2-4 typical · more only on genuinely broad disjoint work.

## Step C — Conflict Radar (run silently, in order)

Per [`../../../docs/playbooks/parallel-conflict-prevention.md`](../../../docs/playbooks/parallel-conflict-prevention.md):

1. **Path overlap** — any two tasks touch the same path (declared matrix +
   `git status -s`)? → **auto-serialize.**
2. **Worktree isolation** — each parallel agent gets `isolation: "worktree"` +
   its own brief `designs/_briefs/<TASK_ID>-impl.md`.
3. **Contract-first (A003)** — a shared event / API / schema change lands as its
   own commit FIRST, then the consuming agents run.
4. **Dependency graph** — dispatch only the unblocked frontier; defer blocked
   tasks. Any check fails → serialize that lane; never "coordinate" two writers
   on one path.

## Step D — Dispatch

Pick the right agent via
[`references/repo-to-agent-mapping.md`](references/repo-to-agent-mapping.md) and
the cheapest model tier that fits (`sub-agent-workflow.md` §1.5).

- **Parallel:** one message, N `Agent(isolation:"worktree")` calls, each pointing
  at its own brief (template:
  [`references/dispatch-prompt-template.md`](references/dispatch-prompt-template.md)).
- **Serial:** one foreground `Agent` per task.

## Step E — Per-result 6-gate (verify EACH independently)

After every coding agent returns, run the full chain — **never batch-trust N
results**. Canonical procedure:
[`../../../docs/playbooks/post-delegation-review.md`](../../../docs/playbooks/post-delegation-review.md)
(re-run standalone any time with `/review gates <TASK_ID>`).

1. Inspect diff → 2. Build + test → 3. Boundary (`senior-tech-lead`) →
4a. Spec-compliance → 4b. Quality reviewers → 5. Wiring (L116) → 6. Smoke.
- UI touched (phase-matrix Phase 9) → auto-run `/review design`.
- Phase-7 triggers fired → auto-run `/review security`.
- TDD (phase 4 ✓) is part of implement; the gate verifies it — recipe:
  [`../../../docs/playbooks/tdd.md`](../../../docs/playbooks/tdd.md).

Any gate fails → fix → re-run that gate only. Don't mark done until all pass.

## Step F — Partial-failure handling + close

- Agent returns `BLOCKED` / `NEEDS_CONTEXT` → add the missing context to its
  brief and `SendMessage` re-dispatch (don't blindly re-`Agent` the same prompt).
- Timeout / malformed return → re-serialize that lane.
- Two lanes conflict on merge → stop, run `/recover`
  ([`../../../docs/playbooks/failure-recovery.md`](../../../docs/playbooks/failure-recovery.md)).
- All lanes green → update each task's state in
  `docs/project/sprints/S<N>/tasks.md` (`[x]`/`[~]`), append its **live
  mini-retro** (A009) to the board, and report what's next.

## What to NEVER do

- Skip Step A′ (design-first) on a `feat`/`fix`/`refactor` task.
- Fan out writes on a shared surface, or parallelize without the Radar.
- Skip or batch the 6-gate. Each returned result is verified on its own.
- Trust an agent's "tests pass" without re-running them (Gate 2).
- Mark a task done before its mini-retro is appended.

## See also

- [`../review/SKILL.md`](../review/SKILL.md) — the gates + design/security lenses `/work` invokes
- [`../idea/SKILL.md`](../idea/SKILL.md) — where backlog items come from
- [`../retro/SKILL.md`](../retro/SKILL.md) — sprint close (aggregates the mini-retros `/work` appends)
- [`../../rules/sub-agent-workflow.md`](../../rules/sub-agent-workflow.md) · [`../../rules/phase-matrix.md`](../../rules/phase-matrix.md)
- [`../../../docs/project/NAMING.md`](../../../docs/project/NAMING.md) — task / design / sprint id formats
