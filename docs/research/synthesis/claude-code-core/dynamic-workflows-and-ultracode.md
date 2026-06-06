---
topic: dynamic-workflows-and-ultracode
sources:
  - sources/2026-06-06-dynamic-workflows-ultracode.md
  - sources/2026-06-05-autonomous-fanout-orchestration.md
date: 2026-06-06
confidence: high
---

## Pattern observed

Claude Code's **dynamic workflows** (`Workflow` tool) + **ultracode** give a new
orchestration substrate: deterministic, off-context, budget-scaled fan-out that
can run dozens-to-hundreds of subagents and *adversarially verify* their output
before anything returns to the session. ultracode makes that the standing default.

This **collides with our template's philosophy of restraint** — `sub-agent-workflow.md
§1.0` says "default to ONE agent; parallel costs ~15×; context fragmentation is the
top failure." Both can be true at once only with an explicit **seam**.

## Why it matters for our SDLC

The seam is *what kind of work*:

- **READ-heavy · VERIFY-heavy · BREADTH** (review, audit, research, understand a
  codebase) → exactly where fan-out + adversarial verification earns its cost.
  The Workflow tool's own canonical example is a review-across-dimensions →
  verify-each-finding pipeline.
- **WRITES** (implement, ship, recover) → the [[autonomous-fanout-orchestration]]
  finding still holds: single-threaded unless paths are provably disjoint +
  worktree-isolated; parallel writes carry conflicting implicit decisions.

The load-bearing invariant: a **Workflow returns conclusions, not a merge-ready
diff.** So it can *augment* the 6-gate (produce high-confidence findings) but must
never *replace* it — the orchestrator still re-runs build/test (Gate 2) and owns
the merge decision. And ultracode is **user-opt-in, session-level** — a subagent
must never self-enable it.

## Proposed template change → SHIPPED

- **`/review ultra`** — a 5th mode on the existing `/review` skill that invokes a
  shipped Workflow (`fd-review-changes`): dimensions → find → adversarial verify
  (3-vote, perspective-diverse) → CONFIRMED only. Explicitly *augments*, never
  replaces, the 6-gate.
- **`core/.claude/workflows/` library** — reusable, `fd-`-namespaced, placeholder-free
  scripts shipped to every install (`fd-review-changes.js`,
  `fd-understand-codebase.js`, README). Users add their own under
  `.claude/workflows/local/` (upgrade-safe).
- **`§1.6 Dynamic workflows & ultracode`** in `sub-agent-workflow.md` — reconciles
  the default-flip with the unchanged safety invariants (writes single-threaded,
  6-gate orchestrator-verified, no subagent self-enable), + Workflow-vs-N×Agent
  decision, budget directives, dynamic `/loop` caveat.

## Expected improvement

At-scale review/audit gets parallel breadth + adversarial verification (fewer
plausible-but-wrong findings surviving) **without** weakening the human-verified
merge gate, and the rules stop contradicting ultracode's default.

## Counter-evidence / risks

- ultracode's "fan out everything" can tempt erosion of the 6-gate human-verify →
  mitigated by stating the augment-not-replace seam in §5, §1.6, and the README.
- Secondary blog sources are unverified → the change rests only on the live tool
  contract (primary); blogs are corroboration.

## Status

- [x] In `apply/shipped/dynamic-workflows-ultracode.md`
- [x] Shipped (local, branch `feat/dynamic-workflows-ultracode`, upgrade-eligible)
