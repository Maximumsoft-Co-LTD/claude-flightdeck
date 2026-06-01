---
name: tdd
description: "Write a test that encodes INTENT, not theater — and apply TDD safely to code that has NO tests yet. Use when about to write or change a test, when the user says '/tdd', 'write a test for this', 'TDD this', 'add tests'; when touching legacy / untested code where a naive 'failing test first' rule would otherwise block work (→ characterization-first, never a blocked commit); or when a test 'passes but asserts nothing' (test theater). Operationalizes phase-4 (test-first) of the phase matrix and feeds Gate 4b of /post-delegation-gate."
user_invocable: true
---

# /tdd — Test Discipline (intent over theater · legacy-safe)

> **Announce on start:** open your reply with "Using /tdd to write an intent-bearing test (mode: greenfield | characterization)." — naming the mode signals which path you took.

The operational front-end to [`docs/setup/test-discipline.md`](../../../docs/setup/test-discipline.md). This is the lean checklist; that doc is the depth.

## Why this exists (the lesson, baked in)

- **Test theater is the dominant AI-generated test failure mode** — tests that *pass* and *look* thorough but assert nothing meaningful. A001 already mandates a failing test first; it never defined *what makes the test worth writing*. This skill does.
- **The adoption blocker this answers:** a project that installs this template may be **legacy with no tests**. A naive "failing test first" rule would block all work on it. This skill **switches modes** instead of blocking — characterization-first on untested code. The cost is *one* test around the change site, **never a blocked commit**. Make change safe; don't make it forbidden.

## Token budget (MANDATORY)

- This skill is the checklist. The deep material — full theater anti-pattern table, approval / golden-master mechanics, seams, fitness functions, mutation testing — lives in [`docs/setup/test-discipline.md`](../../../docs/setup/test-discipline.md). **Read it on demand**, only when you hit that specific case. Do not inline it.
- Read only the **change-site file + one sibling test** (to learn the project's assertion style). Do not read the whole suite.
- **Ships no scripts** — this is discipline, not automation. (Mechanical enforcement is opt-in only; see Step 3.)

## Step 0 — Classify the change site (the fork that keeps this legacy-safe)

Ask one question: **does a test already cover the lines I'm about to add or change?** (grep/glob for a sibling test next to the change site; check the suite for the symbol.)

- **New code, or the change site is already tested** → **Path A** (greenfield bar).
- **Untested — legacy code with no test around the change site** → **Path B** (characterization-first). Do **not** skip the discipline, and do **not** write a from-scratch spec for code you didn't write and haven't verified. **Switch modes.**

State the mode in your announce line.

## Path A — Greenfield / changing tested code (red → green → refactor)

1. **Write the failing test FIRST; watch it red.** A test never seen red may pass for the wrong reason. (For a fix: the regression test must fail on the *pre-fix* code, pass after.)
2. **Assert the observable OUTCOME** — the result/state a caller can see. Never assert your own mock was called; never assert the implementation.
3. **Encode INTENT.** The test must fail for a reason you can *name* ("returns 422 when the email is malformed"), not merely because a string changed.
4. **Cover the failure modes**, not just the happy path — every error branch you wrote is a behavior worth a test.
5. **Large input space → reach for a property / invariant test.** State what must hold for *all* inputs ("round-trip `decode∘encode == identity`") and let a generator hunt counter-examples, instead of three hand-picked examples.
6. **Green with the minimum, then refactor** with the test as the safety net.

## Path B — Legacy / untested change site (characterization-first · SAFE)

> The point: make the change **safe**, not forbidden. The discipline costs *one* test around the change site.

1. **Bug fix? Root-cause first** with `superpowers:systematic-debugging` — don't pin a symptom.
2. **Write a CHARACTERIZATION test FIRST.** Run the code, capture what it *actually* returns for representative inputs, assert exactly that. This pins **current observed behavior** — a safety net, **not** a correctness claim. Label it clearly as characterization.
3. **Output large / structured → approval / golden-master.** Capture an approved snapshot of current output; diff future runs against it.
4. **Change site untestable** (hard-wired dependency, global state)? Introduce the **minimal seam** to get it under test *before* changing logic. Don't rewrite the module to test it.
5. **Then change.** Any behavioral drift now shows up as a **visible test diff**. If a characterization test you didn't intend to touch goes red, you changed something you didn't mean to — that's the net working.
6. For architecture-level legacy constraints (no new layer-X→Y dependency, a latency budget), encode a **fitness function** rather than relying on review memory.

## Step 2 — Theater self-check (run before you call the test done)

Quick reject list — the full table + the *why* is in [`test-discipline.md`](../../../docs/setup/test-discipline.md):

- [ ] **Not** asserting your own mock was called with no real outcome checked.
- [ ] **Not** a tautology (`expect(f(x)).toBe(f(x))`, or asserting a literal the code just returned).
- [ ] **Not** a giant re-bless-on-any-change snapshot that pins formatting instead of behavior.
- [ ] **Was seen red** first (or, for a fix, failed on the pre-fix code).
- [ ] Legacy behavior pinned is **labeled characterization** — not dressed up as an intended-behavior spec.
- [ ] Has the **failure modes**, not just one golden input.

> If you can delete the assertion and the test still "tests something," it tests nothing — rewrite it.

## Step 3 — Meta-check & handoff

- **Mutation testing** is the objective answer to "is my coverage real?" — inject small faults into the code and confirm the tests *catch* them; surviving mutants are gaps. Run it periodically (or LLM-targeted) on a suite you suspect is theatrical.
- When tests were added/changed, **Gate 4b of `/post-delegation-gate`** runs `pr-review-toolkit:pr-test-analyzer` to reject theater. Write the test to genuinely survive that gate, not to pass it superficially.
- **Mechanical enforcement** (a hook that blocks a Write adding production code with no failing test) is **opt-in only** and explicitly cautioned for legacy repos — see the doc's "enforcement hook" section. The template's default posture is **rule + review-gate**, never a hard write-blocker.

## What to NEVER do

- ❌ **Block or refuse to touch legacy code** because it has no tests. Switch to characterization mode instead.
- ❌ **Bulldoze** — rewrite the module to make it "testable" *before* pinning current behavior.
- ❌ **Pin possibly-buggy current output and call it a spec.** Characterization locks behavior, not correctness — label it as such.
- ❌ Write the test after the code and never see it red.
- ❌ Assert the mock / a tautology / a happy-path-only case and call it covered.

## Related

- [`docs/setup/test-discipline.md`](../../../docs/setup/test-discipline.md) — the canonical depth (anti-pattern table, characterization recipe, mutation, the opt-in hook). Read on demand.
- [`.claude/rules/programming-fundamentals.md`](../../rules/programming-fundamentals.md) — the always-loaded TDD pre-flight summary.
- [`.claude/rules/phase-matrix.md`](../../rules/phase-matrix.md) — phase 4 (test-first); legacy `refactor`/`fix` → characterization.
- [`docs/playbooks/post-delegation-review.md`](../../../docs/playbooks/post-delegation-review.md) — Gate 4b catches theater on touched tests.
- `superpowers:test-driven-development` / `superpowers:systematic-debugging` — the red→green and RCA mechanics this skill assumes.
