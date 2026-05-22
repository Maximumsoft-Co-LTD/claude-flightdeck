# Discipline Red Flags — the excuses, and why they're wrong

> The five always-apply disciplines (A001-A005) each have an **Iron Law**
> and a set of **rationalizations** — the specific excuses an agent (or a
> tired human) reaches for under deadline pressure to skip the discipline.
> This file is the catalogue. When you catch yourself thinking one of the
> "Excuse" phrases below, that thought *is* the signal you're about to cut
> a corner that bites later.
>
> Adapted from the [superpowers](https://github.com/obra/superpowers)
> plugin's `test-driven-development`, `verification-before-completion`, and
> `systematic-debugging` skills. The A-rules themselves live in
> [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md);
> this is their "why the excuse is wrong" companion.

> **Spirit over letter.** Re-wording an excuse so it technically dodges the
> rule is still breaking the rule. "This is different because…" is itself a
> red flag.

---

## A001 — TDD by default

> **IRON LAW: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**
> Wrote code before the test? Delete it and start over. If you didn't watch
> the test fail, you don't know that it tests the right thing.

| Excuse | Reality |
|---|---|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll add tests after" | A test that passes the moment you write it proves nothing. Test-first asks *what should this do*; test-after asks *what does this do*. |
| "Already manually tested it" | Ad-hoc ≠ systematic. No record, can't re-run, doesn't cover edge cases. |
| "Deleting hours of work is wasteful" | Sunk-cost fallacy. Keeping unverified code is the debt. |
| "Keep it as reference, write tests first" | You'll adapt the reference — that's testing after. Delete means delete. |
| "Test is hard to write" | Listen to the test: hard to test = hard to use. Fix the design. |
| "TDD will slow me down" | TDD is faster than debugging. Pragmatic *is* test-first. |

**Red flags — STOP and start over:** code before test · test passes
immediately · can't explain why the test failed · "just this once" ·
"it's about spirit not ritual".

---

## A002 — Zero-bug discipline

> **IRON LAW: IT SHIPS GREEN OR IT DOESN'T SHIP.**
> No silent failures, no commented-out tests, no "I'll fix the edge case in
> a follow-up." Can't make it green? Raise the task back as blocked.

| Excuse | Reality |
|---|---|
| "I'll fix the edge case in a follow-up" | The follow-up rarely comes. The edge case becomes a prod incident. Make it a test now. |
| "It's just a warning" | Warnings are how the next regression hides. Treat the build as green-or-nothing. |
| "The happy path works" | The happy path is the part that was never going to fail. The bug lives in the other branch. |
| "Tests are flaky, I'll skip that one" | A flaky test is a real signal. Fix the flake or fix the code; don't comment it out. |
| "Merging yellow so I'm not blocking" | Yellow on main blocks *everyone* later. Raise it blocked instead. |

**Red flags:** a skipped/`xfail` test added in the same diff as the feature ·
"known issue" with no ticket · `catch {}` that swallows · "works on my machine".

---

## A003 — Verification before completion

> **IRON LAW: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**
> If you haven't run the command *in this message*, you cannot claim it
> passes. Paste the real output, not a summary.

| Excuse | Reality |
|---|---|
| "Should work now" | Then RUN it. "Should" is a hypothesis, not evidence. |
| "I'm confident" | Confidence is not evidence. |
| "The linter passed" | Linter ≠ compiler ≠ tests. Each proves a different thing. |
| "The agent said success" | A subagent's "done" is an input, not evidence — verify independently (diff + re-run). |
| "Partial check is enough" | Partial proves the part you checked, nothing else. |
| "I'm tired / just this once" | Exhaustion isn't an exception. The Iron Law has none. |

**Red flags:** the words "should / probably / seems to" · "Great! / Perfect! /
Done!" *before* running the command · about to commit/push without a fresh run.

---

## A004 — 6-gate post-delegation review

> **IRON LAW: EVERY CODING SUBAGENT PASSES ALL 6 GATES BEFORE MERGE.**
> The subagent's summary is an input, not evidence — re-derive correctness
> from the diff and re-run commands. On failure: fix → re-run *that* gate.

| Excuse | Reality |
|---|---|
| "The subagent said tests pass" | Re-run them yourself (Gate 2). Reports drift from reality. |
| "It's a tiny change, skip the gates" | Tiny changes ship the wiring bugs (Gate 5) and the silent failures (Gate 4) most often. |
| "I read the summary, the diff is fine" | Read the *diff* (Gate 1), not the prose about it. |
| "Spec compliance and quality are the same pass" | They're not: 4a asks *did it build the AC, nothing extra*; 4b asks *is it well-built*. 4a gates 4b. |
| "Smoke test takes too long" | Gate 6 is where "green tests, broken feature" gets caught. Skipping it is how it reaches prod. |

**Red flags:** merging on a subagent's word · skipping Gate 5 wiring on a
"compiles fine" change · running 4b quality before 4a spec-compliance.

---

## A005 — Design-doc-first

> **IRON LAW: NO CODE EDIT BEFORE THE DESIGN DOC IS MERGED.**
> The sprint file is the scope; the D-doc is the *how*. Skipping it is the
> single biggest cause of churn and re-delegation.

| Excuse | Reality |
|---|---|
| "The task is obvious, skip the doc" | Obvious tasks have the cheapest docs and still surface AC contradictions. |
| "It's urgent, no time for design" | Urgent tasks benefit most from a 30-minute design pass — rework on an urgent task is the expensive path. |
| "I'll write the doc after, to match the code" | A doc reverse-engineered from code documents what you built, not what was required. |
| "The AC are in my head" | Then they're not testable, not reviewable, and not in the touched-files matrix the Conflict Radar needs. |

**Red flags:** a code commit with no `D<NNN>` design doc · a D-doc under the
size threshold for a non-trivial task with no risk acknowledgment · AC that
contradict each other on a field's type/shape/nullability.

---

## See also

- [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) — the A001-A010 rules themselves
- [`../playbooks/post-delegation-review.md`](../playbooks/post-delegation-review.md) — the 6 gates (incl. the gate-skipping red flags)
- [`debugging-escalation`](#) → see `phase-matrix.md` `fix` type — RCA-first + the 3-strikes architectural escalation
