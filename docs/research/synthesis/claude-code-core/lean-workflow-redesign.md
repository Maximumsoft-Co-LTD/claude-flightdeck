---
topic: lean-workflow-redesign
sources:
  - sources/2026-06-05-spec-driven-command-surface.md
  - sources/2026-06-05-autonomous-fanout-orchestration.md
date: 2026-06-05
confidence: high
---

## Pattern observed

The template had grown to **22 skills** and **5 scattered state files**, forcing
users to choose between near-identical commands (`/next-task` vs `/assign`,
`/discover`+`/promote`, `/retro`→`/ratify-rules`). Two independent evidence
streams point the same way:

1. **Command-surface:** spec-driven leaders run a *small* core command set
   (spec-kit's 5-command spine; Kiro's 3-doc spine) with optional validation
   layered on, and keep state in *one self-contained numbered folder per unit*.
   Rigor is tiered by task size, not always-on.
2. **Fan-out:** an orchestrator should *decide* parallel-vs-serial itself —
   parallelize only disjoint/read-heavy/write-isolated work, keep shared-surface
   writes single-threaded, brief each agent, and handle partial failure.

## Why it matters for our SDLC

Fewer, more powerful verbs lower the cost of *driving* the workflow without
lowering its rigor. Design-first + the 6-gate stay — research confirms a hard
review-gate is a deliberate edge spec-kit/Kiro don't have. Putting the
fan-out decision (and the Conflict Radar) *inside* `/work` removes a whole class
of user error (when/how to parallelize safely).

## Proposed template change → SHIPPED

- **6 verbs + 4 niche** (from 22): `/idea /work /review /ship /retro /status`
  (+ `/onboard /recover /document /flightdeck-feedback`). Each old skill → a
  mode/flag. `/work` absorbs design-first + auto-fanout + the 6-gate.
- **Hybrid sprint-folder state** under `docs/project/` (renamed from `docs/spec/`):
  `sprints/S<N>/{tasks.md, designs/, retro.md}` + a cross-sprint `backlog.md`
  (with a `## Follow-ups` section). STATUS / STATUS-archive / FOLLOWUPS eliminated.
- Reference-on-demand detail: `/tdd` + the 6-gate live as playbooks; size-tiered
  design templates; per-folder READMEs + a `NAMING.md` cheat-sheet.

## Counter-evidence / risks

- Aggressive consolidation is higher migration cost (mitigated: 6 commits, each
  validator-green, legacy `docs/spec/**` upgrade globs retained for old installs).
- `/onboard` (337L) + `/work` density remain above the lean ideal — deferred
  follow-up (split onboard; reconsider folding `/flightdeck-feedback`).

## Status

- [x] In `apply/shipped/lean-workflow-redesign.md`
- [x] Shipped (local `main` via `refactor/lean-workflow-6-verbs`, upgrade-eligible)
