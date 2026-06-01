# Test Discipline — intent over theater, and a legacy-safe path

> The depth behind the **TDD pre-flight** in
> [`../../.claude/rules/programming-fundamentals.md`](../../.claude/rules/programming-fundamentals.md)
> and the test-theater check in
> [`../playbooks/post-delegation-review.md`](../playbooks/post-delegation-review.md)
> Gate 4b. Read on demand — when you (or a dispatched agent) are about to
> write tests, especially on a codebase that has few or none.
>
> **Why this exists:** AI is very good at producing tests that *pass* and
> *look* thorough but assert nothing meaningful — "test theater." A001 (TDD)
> already requires a failing test first; this doc defines *what makes the test
> worth writing* and, critically, **how to apply the discipline safely to
> legacy code that has no tests yet** so the guard never becomes a reason to
> avoid touching old code (or to bulldoze it).

## The one principle

**A test encodes INTENT, not just current output.** It should fail for a
*reason you can name* ("returns 422 when the email is malformed"), not merely
because a string changed. If you can delete the assertion and the test still
"tests something," it tests nothing.

This is the dividing line behind everything below: a **new-behavior** test
asserts what the code *should* do (you write it first, red, per A001); a
**characterization** test asserts what legacy code *currently* does (you write
it first to make change *visible*). Both are intent-bearing — one pins desired
behavior, the other pins observed behavior as a safety net. Neither is theater.

## Test theater — the anti-patterns (auto-reject in Gate 4b)

| Smell | Why it's theater | Fix |
|---|---|---|
| **Asserting the mock** | `expect(mock).toHaveBeenCalled()` with no real outcome checked — proves the test wired its own mock, nothing about the code. | Assert the observable result / state, not the interaction with your own double. |
| **Tautology** | `expect(add(2,2)).toBe(add(2,2))` or asserting a literal the code just returned. | Assert against an *independently-derived* expected value. |
| **Snapshot-everything** | A giant auto-snapshot that "passes" on any change once re-blessed — pins formatting, not behavior. | Snapshot small, intentional surfaces; assert the fields that carry meaning. |
| **No red phase** | Written after the code, never seen to fail — may pass for the wrong reason. | Show it red first (A001). For a fix: the regression test must fail on the pre-fix code. |
| **Behavior-as-intent on legacy** | Pinning current output of code you *haven't verified is correct* and calling it a spec. | Label it a **characterization** test (it locks behavior, not intent) — see below. Don't dress it up as a requirement test. |
| **Happy-path only** | One golden input, no error/empty/boundary case. | Add the failure modes the code actually has (the error branch you wrote IS a behavior to test). |

> The deeper framing: tests that "validate current behavior (including its
> bugs) rather than intended behavior" are the dominant AI-generated test
> failure mode (ben3d.ca, "The rise of test theater"). The review gate exists
> to catch exactly this.

## Greenfield / changing-tested-code: the bar

1. **Red → green → refactor** (A001). The failing test comes first and you
   watch it fail.
2. **Assert outcomes, not implementation.** Behavior the caller can observe.
3. **Cover the failure modes**, not just the happy path — every error branch
   you wrote is a behavior worth a test.
4. **Reach for property / invariant tests** where the input space is large.
   Instead of three examples, state a property that must hold for *all* inputs
   ("round-trip encode∘decode == identity") and let a generator hunt
   counter-examples. Property-based feedback measurably outperforms
   example-only TDD on correctness (Property-Generated Solver, arXiv
   2506.18315; Anthropic Frontier Red Team's Hypothesis-based agent).

## Legacy / untested code: the SAFE path (read this before touching old code)

**The concern this answers:** "the project that adopts this template is legacy
with no tests — won't a TDD guard break it / block all work?" No. The guard
**switches modes**, it does not demand greenfield TDD on a codebase that has
none:

1. **Do NOT write a from-scratch spec test for code you didn't write and
   haven't verified.** You don't yet know what's *intended* vs *incidental*.
2. **Write a characterization test FIRST** — pin the code's *current* observed
   behavior (Michael Feathers, *Working Effectively with Legacy Code*). Run the
   code, capture what it actually returns for representative inputs, and assert
   that. This is your safety net: now any behavior change you make becomes a
   **visible** test diff instead of a silent regression. (For AI refactors this
   is essential — silent behavioral drift is the #1 risk; lock behavior before
   the agent touches it.)
3. **Use approval / golden-master testing** as the mechanic when output is
   large or structured: capture an approved snapshot of current output, diff
   future runs against it (ApprovalTests and friends are polyglot). Label it
   clearly as characterization — it locks behavior, *not* correctness.
4. **Find a seam.** If the change site is untestable (hard-wired dependency,
   global state), introduce the minimal seam to get it under test *before*
   changing logic — don't rewrite the module to test it.
5. **Then change** — with the characterization net catching any drift. Only the
   behavior you *intend* to change should move; if other characterization tests
   go red, you changed something you didn't mean to.
6. **Fitness functions for the big picture.** For architecture-level legacy
   constraints (no new dependency from layer X to Y, latency budget), encode an
   automated fitness function rather than relying on review memory.

> Guardrails before autonomy: seams + characterization tests + fitness
> functions are what let an agent modernize legacy safely (isaqb, "AI agents
> don't modernize legacy code on their own"; understandlegacycode.com). The
> phase matrix reflects this: `refactor`/`fix` on untested code → the "test
> first" phase **is** a characterization test, not a new-behavior spec.

**Net:** on a no-tests legacy repo the discipline costs you *one
characterization test around the change site* — not a project-wide test suite,
and never a blocked commit. It makes change safe; it does not make change
forbidden.

## Mutation testing — the meta-check ("are my tests real?")

Tests can pass and still be theater. **Mutation testing** introduces small
faults into the code and checks your tests *catch* them — surviving mutants are
gaps. Use it periodically (or LLM-targeted, à la Meta's ACH) to validate that a
suite actually constrains behavior, not just executes lines. This is the
objective answer to "is my coverage real coverage?"

## Optional: an enforcement hook (opt-in, NOT shipped by default)

Teams that want *mechanical* enforcement (block a Write/Edit that adds
production code with no corresponding failing test) can add a TDD-enforcement
hook such as [`nizos/tdd-guard`](https://github.com/nizos/tdd-guard) to their
own `.claude/hooks/`. The template **does not ship this on by default**, by
design:

- A write-blocking TDD hook on an **untested legacy repo** would do exactly
  what you feared — block legitimate work. If you adopt such a hook, run it in
  a **characterization-aware mode** (a characterization test satisfies the
  gate) or scope it to new modules only.
- Treat any added hook as executable, committed agent config — review it per
  [`agent-config-security.md`](./agent-config-security.md) (Phase-7 trigger).

The template's default posture is **rule + review-gate**, not a hard blocker —
advisory where the codebase can't support strict TDD, enforced by the 6-gate
review where it can.

## Tie-ins

- **`/tdd` skill** — the operational front-end that *runs* this discipline
  (Step 0 classifies greenfield vs characterization mode; self-checks theater).
  This doc is its reference depth; invoke the skill, read the doc on demand.
- **A001 (TDD)** — the non-negotiable failing-test-first rule this doc deepens.
- **`programming-fundamentals.md`** — the terse TDD pre-flight that links here.
- **`post-delegation-review.md` Gate 4b** — where test theater is caught
  (`pr-test-analyzer` when tests were touched).
- **`phase-matrix.md`** — TDD row: `refactor`/`fix` on untested legacy →
  characterization-first.
- **`agent-config-security.md`** — if you opt into an enforcement hook, it's
  reviewable executable config.

## See also

- `.claude/rules/programming-fundamentals.md` — reflex coding rules + TDD pre-flight
- `.claude/rules/brain-hot.md` — A001 (TDD), A002 (zero-bug)
- `docs/playbooks/post-delegation-review.md` — the 6-gate review
