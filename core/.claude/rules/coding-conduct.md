# Coding Conduct — behavioral guidelines (auto-loaded · every agent · every repo)

> **Why this exists.** Most LLM coding mistakes are *behavioral*, not knowledge
> gaps: assuming instead of asking, over-building, touching code that wasn't in
> scope, declaring "done" without a verifiable goal. These four guidelines are the
> **front door** every agent passes through — the orchestrator AND every service /
> area repo it controls. The `brain-hot.md` A-rules are how we *enforce* them under
> the 6-gate; these are the posture you bring *before* the rigor kicks in.
>
> Adapted from the open "behavioral guidelines to reduce LLM coding mistakes"
> CLAUDE.md (github.com/multica-ai/andrej-karpathy-skills), de-domain-specified for
> this template. → research note `docs/research/sources/2026-06-06-karpathy-coding-conduct.md`.

**Tradeoff:** these bias toward **caution over speed**. For a trivial task (typo,
one-line config, an LSP-verified rename), use judgment — don't ceremony it.

---

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

> Subagents can't call `AskUserQuestion` — surface it as `NEEDS_CONTEXT` instead
> (pre-task ritual Step 6). The orchestrator asks. This is also why A005 makes the
> **design doc come first** — it's where assumptions get named and approved.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" / "configurability" that wasn't requested.
- No error handling for *impossible* scenarios. (Real, reachable errors are still
  handled deliberately — never swallowed — per `programming-fundamentals.md` #4.)
- If you wrote 200 lines and it could be 50, rewrite it.

> The test: *"Would a senior engineer call this overcomplicated?"* If yes, simplify.
> This is the Gate-4a "nothing extra was built" check (over/under-build) stated as a
> habit, not just a gate.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match the existing style, even if you'd do it differently
  (`.claude/rules/code-style.md` + conform-to-codebase).
- Notice unrelated dead code? **Mention it — don't delete it.** (Log it to the
  backlog `## Follow-ups`.)
- Remove imports / vars / functions that *your* change orphaned. Don't remove
  pre-existing dead code unless asked.

> The test: **every changed line traces directly to the request.** This is the
> delivery cousin of git-workflow #2-3 (one purpose per branch, atomic commits) and
> what keeps Gate-1 "inspect the diff" honest.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Turn vague tasks into verifiable goals — this is just A001 (TDD) + A003
(verification-before-completion) said up front:

- "Add validation" → "write tests for invalid inputs, then make them pass"
- "Fix the bug" → "write a test that reproduces it, then make it pass"
- "Refactor X" → "ensure the suite passes before and after"

For a multi-step task, state a brief plan with a checkable verify per step:

```
1. [step] → verify: [check]
2. [step] → verify: [check]
```

> Strong success criteria let you loop independently; weak ones ("make it work")
> force constant clarification. Never claim done without pasting the real
> build/test/smoke output (A003) — evidence before assertions, always.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer
rewrites from overcomplication, and clarifying questions come *before*
implementation rather than after a mistake.

## See also

- [`./brain-hot.md`](./brain-hot.md) — the A-rules that enforce this conduct under the 6-gate
- [`./programming-fundamentals.md`](./programming-fundamentals.md) — the reflex coding rules (#4 errors, #7 read-first)
- [`./agent-pre-task-ritual.md`](./agent-pre-task-ritual.md) — every dispatched agent reads this file (Step 2)
- [`./git-workflow.md`](./git-workflow.md) — surgical changes at delivery time (atomic commits)
