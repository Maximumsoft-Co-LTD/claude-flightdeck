---
topic: test-theater-and-legacy-safe-tdd
track: sdlc-with-ai
sources:
  - ../../sources/2026-05-31-ben3d-test-theater.md
  - ../../sources/2026-05-31-understandlegacycode-characterization-tests.md
  - ../../sources/2026-05-31-property-generated-solver.md
supporting:
  - https://www.isaqb.org/blog/ai-agents-dont-modernize-legacy-code-on-their-own/
  - https://understandlegacycode.com/blog/can-ai-refactor-legacy-code/
  - https://arxiv.org/abs/2510.23761   # TDFlow — minimizes test-hacking
  - https://engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/
  - https://github.com/nizos/tdd-guard
date: 2026-05-31
confidence: high
---

## Pattern observed
A001 makes TDD non-negotiable, but the 2025-26 evidence says the *quality* of
the test is the real battleground, and there are two distinct failure modes:

1. **Test theater (greenfield):** AI produces passing tests that assert
   nothing meaningful — mock-assertions, tautologies, snapshot-everything,
   happy-path-only, or pinning current (buggy) output as if it were a spec
   (ben3d.ca). Coverage rises; protection doesn't. The fix is *intent*: the
   test fails for a nameable reason and was red first. Property-based feedback
   raises the bar further (+13.4% pass@1 vs example-TDD; arXiv 2506.18315), and
   mutation testing (Meta ACH) is the meta-check that a suite actually
   constrains behavior.

2. **The legacy trap:** demanding greenfield TDD on a codebase with no tests
   either blocks work or invites bulldozing. The established answer is
   **characterization testing** (Feathers): pin current observed behavior
   *first* so any change is a visible diff, then change. Lock behavior before
   an AI refactor — silent drift is the #1 risk (understandlegacycode, isaqb).
   Cost is one test around the change site, never a project-wide suite.

These are the same discipline (tests encode intent / make change visible) in
two regimes. Our template had the terse TDD pre-flight but neither the
test-theater guard nor the legacy-safe mode.

## Why it matters for our SDLC
This is the gate between "we have tests" and "our tests protect us." It also
removes the single biggest objection to adopting the template on a **real
legacy codebase** — the exact concern raised: *"the project is legacy with no
tests, won't the TDD guard break it?"* The answer encoded here is **no**: the
guard switches to characterization mode, stays advisory (rule + review-gate,
not a hard write-blocker), and the optional enforcement hook is opt-in with a
legacy caveat. So the discipline raises test quality on greenfield work AND
makes legacy work safe — without ever blocking a commit.

## Proposed template change
- **Type:** new-doc + rule-update + playbook-update + matrix-note
- **Target file(s):**
  - `core/docs/setup/test-discipline.md` (NEW) — intent-over-theater, the
    test-theater anti-pattern table, the greenfield bar (incl. property/
    invariant + mutation), the **legacy-safe characterization path**, and the
    optional opt-in enforcement hook with its legacy caveat.
  - `core/.claude/rules/programming-fundamentals.md` — sharpen TDD pre-flight:
    intent-not-output, named theater anti-patterns, the legacy
    characterization branch, link to the doc.
  - `core/docs/playbooks/post-delegation-review.md` Gate 4b — add the
    test-theater rejection step (when tests touched) + checklist note.
  - `core/.claude/rules/phase-matrix.md` — TDD-row note: untested legacy →
    characterization-first.
  - `core/docs/INDEX.md` — add the `test-discipline` setup-doc row.
- **Friction-or-quality:** **quality** (catches theater) + **adoptability**
  (legacy-safe, never a blocker). No new mandatory step on greenfield work —
  it sharpens the test you were already writing.

## Counter-evidence / risks
- Mutation/property testing have a learning + runtime cost → presented as the
  *higher rung*, not mandated. The hard enforcement hook is **opt-in only**,
  explicitly because a write-blocking TDD hook would brick an untested legacy
  repo (the user's concern) — default posture stays rule + review-gate.

## Status
- [x] Proposed
- [x] In `apply/shipped/`
- [x] Shipped
