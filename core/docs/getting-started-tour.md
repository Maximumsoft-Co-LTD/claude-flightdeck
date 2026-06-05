# Getting Started — A Day in the Life

> Monday-Friday walkthrough of one real sprint, end-to-end. Each step
> names: **what the user types**, **what happens**, **what gets
> written**, and **where to look if something goes wrong**.
>
> Every step cross-links to the relevant A### / N### rule, the skill
> driving it, and the agent that executes the work. Use this as your
> map until the cadence is muscle memory — most teams need 2-3 sprints
> before the workflow runs without consulting it.

## Step 0 — Run `/onboard` (one-time setup wizard)

After `install.sh` lays down the templates, the next step is to make
Claude Code **understand your project**. Don't try to fill in
`CLAUDE.md` / A-rules / the active sprint board by hand — open Claude Code and
run:

```
/onboard
```

The 8-stage hybrid wizard takes ~4-6 hours interactive (most stages
auto-do mechanical work — codebase scan, git history mining, draft
documentation; you only intervene for the team interview, A-rule
ratification, and first-sprint state). Full operator doc:
[`./setup/onboarding-guide.md`](./setup/onboarding-guide.md).

After it finishes you'll have:
- `CLAUDE.md` filled from real evidence (not placeholders)
- Per-area `CLAUDE.md` for monorepos
- `.claude/rules/brain-hot.md` with project-local A011+ rules drafted
  from git history (you choose which to keep)
- `docs/setup/codebase-orientation.md` + `team-conventions.md`
- `docs/project/sprints/S<N>/tasks.md` + `backlog.md` seeded (backlog includes the `## Follow-ups` section)

## Pre-flight (one-time, before the sprint starts)

You've already run:

```bash
./install.sh ~/code/{{PROJECT_SLUG}} --preset <yours> --profile standard
```

…and `/onboard` (above). Open the project in Claude Code. Confirm:

- `CLAUDE.md` non-negotiables (N1-N6) read sensible
- `docs/project/sprints/S<N>/tasks.md` shows your first sprint (or you're about to author it)
- `docs/project/backlog.md` has at least one row
- `.claude/settings.json` exists and matches the profile you chose
  ([`./setup/permission-profiles.md`](./setup/permission-profiles.md))

If any of those are wrong → re-run `/onboard refresh`, OR re-run the
installer with `--force` after backing up, or hand-fix.

---

## Monday morning — capture & promote

### Step 1 — `/discover` a new idea

**You type**: `/discover the operator dashboard needs a status filter`

**What happens**: the [`/discover`](../.claude/skills/discover/SKILL.md)
skill walks you through a 3-stage interview (Core → Scope →
Context) sized to the idea's complexity. It allocates `D###`, scans
for duplicates against the backlog and other discovery items, and
writes the detail file.

**Written**:
- `docs/project/ideas/D007-operator-status-filter.md` (the detail)
- new row in `docs/project/ideas.md` (the index)

**Cross-links**: A008 (discovery → backlog state), workflow stage S1
([`./setup/workflow-master.md`](./setup/workflow-master.md))

**If it goes wrong**:
- Duplicate flagged but you want to refine instead → `/discover refine D###`
- File didn't land → check `docs/project/ideas/` exists and is writable

### Step 2 — `/promote` to backlog

**You type**: `/promote D007`

**What happens**: the [`/promote`](../.claude/skills/promote/SKILL.md)
skill runs the Definition-of-Ready gate (≥1 user story, ≥3 AC,
dependencies declared, no blocking questions, complexity estimate, no
duplicate, affected components, cross-cutting concerns). If it
passes, an enriched row lands on the backlog.

**Written**:
- new row in `docs/project/backlog.md` referencing `D007`
- D007's state → `promoted` in `docs/project/ideas.md`

**Cross-links**: A008; backlog index ([`./setup/index-discipline.md`](./setup/index-discipline.md))

**If it goes wrong**:
- DoR gate fails → `/discover refine D007` to fill the missing slot,
  then retry `/promote`

---

## Monday afternoon — sprint planning + start

Sprint planning is **manual** — open the new
`docs/project/sprints/S<N>/tasks.md`, copy the backlog rows into the
task table, pick fanout waves, write the cross-task contracts
section. The orchestrator agent can help if you ask; there's no
dedicated skill because planning rewards human deliberation.

Once the sprint file exists, mark it the active sprint by updating
`docs/project/sprints/S<N>/tasks.md` (this is the A008 source-of-truth move).

### Step 3 — `/next-task`

**You type**: `/next-task`

**What happens**: the [`/next-task`](../.claude/skills/next-task/SKILL.md)
skill reads the active sprint board (`docs/project/sprints/S<N>/tasks.md`), applies the Phase
Matrix (type × phase lookup), finds the first un-started, un-blocked
row, and confirms with you. It then either runs the design-doc gate
(A005) or dispatches the implementation agent.

**Written**: nothing yet (this is the read + decide step).

**Cross-links**: A005 (design-doc-first), A008 (STATUS source-of-truth),
A008 (sprint state via STATUS), Phase Matrix
([`../.claude/rules/phase-matrix.md`](../.claude/rules/phase-matrix.md))

**If it goes wrong**:
- "no eligible tasks" → check the sprint file for unblocked `[ ] Not
  Started` rows; verify dependencies are met
- "no eligible tasks" in the sprint board → verify the board's Glance header names the active sprint and has unblocked `[ ] Not Started` rows (per A008)

---

## Tuesday — design + implement

### Step 4 — `design-doc-writer` agent

**You type**: nothing — `/next-task` dispatches this automatically
when the task has no D-doc.

**What happens**: the
[`design-doc-writer`](../.claude/agents/design-doc-writer.md) agent
runs its pre-task ritual (CLAUDE.md + brain-hot.md + the area
CLAUDE.md), reads the backlog row, LSP-hovers every type the AC
mentions (L149), and writes a ≥500-line zero-fix D-doc using
[`./designs/_templates/DESIGN_TEMPLATE.md`](./designs/_templates/DESIGN_TEMPLATE.md)
(or `DESIGN_LIGHT_TEMPLATE.md` for surgical sweeps — see Phase Matrix).

**Written**: `docs/project/sprints/S<N>/designs/D###-<slug>.md` (the design doc).

**Cross-links**: A005 (design-doc-first), L076 (≥500L threshold), L149 + L156
(type verification), agent pre-task ritual
([`../.claude/rules/agent-pre-task-ritual.md`](../.claude/rules/agent-pre-task-ritual.md))

**If it goes wrong**:
- D-doc < 200 lines for a non-trivial task → agent emits a warning;
  decide whether to expand or accept (it's your call but the gate
  flags it)
- Type contradiction surfaces in AC → the agent stops and asks you
  to clarify (L149) — answer in the discovery doc or sprint file,
  re-dispatch

### Step 5 — Implement (the preset engineer)

**You type**: nothing — `/next-task` dispatches this once the D-doc
exists.

**What happens**: the engineer (`backend-engineer` or
`frontend-engineer`) runs its pre-task ritual, reads `code-style.md` +
samples the codebase to match its style, reads the D-doc, invokes
`superpowers:test-driven-development`, writes the failing test first
(A001), then implements to green. It commits and returns a summary.

**Written**:
- test file(s) — committed before any impl (A001)
- impl file(s) — committed after green
- branch `<type>/<task-id>-<slug>` pushed to origin

**Cross-links**: A001 (TDD), A002 (zero-bug), A010 (LSP-first),
programming-fundamentals
([`../.claude/rules/programming-fundamentals.md`](../.claude/rules/programming-fundamentals.md)),
git-workflow ([`../.claude/rules/git-workflow.md`](../.claude/rules/git-workflow.md))

**If it goes wrong**:
- agent claims "tests pass" but the diff has no test file → flag at
  Gate 1; the 6-gate review catches this
- branch name doesn't match `<type>/<task-id>-<slug>` → flag at
  Gate 1; the agent re-branches

---

## Wednesday — the 6-gate review

### Step 6 — `/post-delegation-gate`

**You type**: `/post-delegation-gate`

**What happens**: the
[`/post-delegation-gate`](../.claude/skills/post-delegation-gate/SKILL.md)
skill walks the 6-gate playbook
([`./playbooks/post-delegation-review.md`](./playbooks/post-delegation-review.md)):

1. **Inspect** — `git diff --stat` + read the diff yourself.
2. **Build + Test** — `make build && make test` (and `docker-build`
   per Gate 2).
3. **Boundary** — `senior-tech-lead` checks the diff against the
   project's own conventions (`code-style.md`); +`helm lint` if k8s-helm.
4. **Quality** (parallel, one message) —
   `pr-review-toolkit:code-reviewer`, `:silent-failure-hunter`,
   `:type-design-analyzer` (+ `:pr-test-analyzer` if tests touched,
   `:comment-analyzer` if comments touched).
5. **Wiring** (L116) — composition root has the new code; migrations
   applied; observability emits; topics created; contracts in sync.
6. **Integration smoke** — `make docker-up && make smoke` end-to-end
   golden path. If UI changed → also `/design-review` (L182).

**Written**:
- review log on the PR (or attached at
  `docs/project/reviews/sprint-S<N>-<task-id>.md`)
- audit JSONL records in `docs/project/audit/YYYY-MM.jsonl` for every
  dispatched reviewer

**Cross-links**: A004 / N3 (6-gate), L116 (wiring), L182 (visual
fidelity), playbook
([`./playbooks/post-delegation-review.md`](./playbooks/post-delegation-review.md))

**If it goes wrong**:
- any gate red → **fix, re-run THAT gate, continue**. Never skip a
  gate. Never merge on red.
- Gate 4 finding is too costly to fix in-session → log to the backlog's Follow-ups section (`docs/project/backlog.md` `## Follow-ups`)
  with severity (P1 blocks; P2/P3 can defer with `PR-APPROVER` ack
  per N6)
- preset-specific reviewer missing → use `senior-tech-lead` as the
  fallback for Gate 3

### Step 7 — Live mini-retro (A009 / L036)

**You type**: append manually to
`docs/project/sprints/S<N>/tasks.md` — or invoke
`/retro --task <id>`.

**What happens**: 5 minutes while the context is still hot, you fill
in the 6-field mini-retro template (what worked / what bit / time
spent vs estimate / lessons / followups / done state).

**Written**: append-only block in `docs/project/sprints/S<N>/tasks.md`

**Cross-links**: A009, L036, A008 (sprint close aggregates these)

**If it goes wrong**:
- you defer the retro to "Friday" → DON'T. The learning evaporates.
  The retro must land before the next `/next-task`.

---

## Thursday — mid-sprint check + more tasks

### Step 8 — `/progress`

**You type**: `/progress`

**What happens**: the
[`/progress`](../.claude/skills/progress/SKILL.md) skill prints a
read-only dashboard: tasks done / in-progress / blocked, completion
rate, per-component breakdown, blocking links. It does NOT write.

**Written**: nothing — read-only.

**Cross-links**: A008 (STATUS source-of-truth), workflow stage S5

**If it goes wrong**:
- "blocked" tasks pile up → run a triage session; surface in
  Friday's retro; possibly re-plan the rest of the sprint

Repeat **Steps 3-7** for each task until the sprint file's task
table is all `[x] Done` or `[B] Blocked`. Use `/dispatch-parallel`
for waves of independent tasks (run the Conflict Radar first —
[`./playbooks/parallel-conflict-prevention.md`](./playbooks/parallel-conflict-prevention.md)).

---

## Friday — close the sprint

### Step 9 — `/retro`

**You type**: `/retro`

**What happens**: the [`/retro`](../.claude/skills/retro/SKILL.md)
skill dispatches the
[`sprint-retro-author`](../.claude/agents/sprint-retro-author.md)
agent. It aggregates the live mini-retros, runs the **backlog audit**
(HARD gate — mismatch ≠ 0 is blocker per A008), classifies findings
into fix-now vs defer, fixes the process bugs immediately, and writes
the full retro file.

**Written**:
- `docs/project/sprints/S<N>/retro.md` (the closing retro)
- updates to `docs/project/backlog.md` (deferred items + their
  severity + `PR-APPROVER` ack per N6 if any; `## Follow-ups` section updated)
- closing Glance prose moved from `docs/project/sprints/S<N>/tasks.md` into `docs/project/sprints/S<N>/retro.md` **in the same
  commit** (per A008)

**Cross-links**: A009 / L036 (live retros aggregated here),
A008 (backlog audit + STATUS lifecycle), workflow stage S7
([`./setup/workflow-master.md`](./setup/workflow-master.md))

**If it goes wrong**:
- backlog audit shows mismatch ≠ 0 → STOP. Reconcile the rows
  before closing. A008 is non-negotiable.
- mini-retros missing for some tasks → write them retroactively
  (best effort; the lesson is "don't defer next time")

### Step 10 — Lessons → brain-hot promotion

**You type**: manually edit `.claude/rules/brain-hot.md` OR your
external brain (if `BRAIN_PATH` set) to promote any L### that emerged
from this sprint.

**What happens**: lessons identified in the retro that **fire often**
become L### entries cited from `brain-hot.md`. Lessons that are
project-local become new A011+ entries in the "Project-specific
rules" section.

**Written**:
- `.claude/rules/brain-hot.md` — new L### or A### entry
- the brain (if external) — full lesson detail

**Cross-links**: lesson-trigger-map
([`./setup/lesson-trigger-map.md`](./setup/lesson-trigger-map.md))

**If it goes wrong**:
- brain-hot.md > 200 lines → factor into a separate file under
  `.claude/rules/` and link from brain-hot

---

## Where each step leaves audit evidence

| Step | Audit trail |
|---|---|
| 1 (`/discover`) | `docs/project/ideas/D###.md`; index row |
| 2 (`/promote`) | `docs/project/backlog.md` row |
| 3 (`/next-task`) | dispatch in `docs/project/audit/YYYY-MM.jsonl` |
| 4 (`design-doc-writer`) | `docs/project/sprints/S<N>/designs/D###.md`; dispatch in audit JSONL |
| 5 (engineer agent) | git commits + branch; audit JSONL |
| 6 (`/post-delegation-gate`) | review log on PR; reviewer dispatches in audit JSONL |
| 7 (live mini-retro) | `docs/project/sprints/S<N>/tasks.md` append |
| 8 (`/progress`) | none (read-only) |
| 9 (`/retro`) | `docs/project/sprints/S<N>/retro.md`; Glance prose moved from `tasks.md` into `retro.md` |
| 10 (brain promotion) | `.claude/rules/brain-hot.md` diff |

An auditor walking this chain end-to-end can answer: who/when
authored, who reviewed, what was deferred, who acked the deferral,
and what changed in the rules. Cross-link to
[`./setup/compliance-mapping.md`](./setup/compliance-mapping.md) for
the framework-by-framework mapping.

---

## See also

- [`./INDEX.md`](./INDEX.md) — the master cross-reference matrix
- [`../CLAUDE.md`](../CLAUDE.md) — non-negotiables (N1-N6)
- [`../.claude/rules/brain-hot.md`](../.claude/rules/brain-hot.md) — A001-A010
- [`./setup/workflow-master.md`](./setup/workflow-master.md) — the S1-S7 pipeline
- [`./setup/lesson-trigger-map.md`](./setup/lesson-trigger-map.md) — "if touching X → apply Y"
- [`./playbooks/post-delegation-review.md`](./playbooks/post-delegation-review.md) — the 6-gate playbook
- [`./playbooks/failure-recovery.md`](./playbooks/failure-recovery.md) — when a dispatch goes sideways
