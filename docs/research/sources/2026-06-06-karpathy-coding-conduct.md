---
url: https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md
type: artifact
date_found: 2026-06-06
date_processed: 2026-06-06
topics: [claude-code-core]
quality: 4
status: distilled
artifact_kind: claude-md
adoptability: adapt
---

## TL;DR

A compact, widely-shared **CLAUDE.md of behavioral guidelines** that target the
*behavioral* class of LLM coding mistakes (assuming, over-building, scope creep,
unverified "done") rather than knowledge gaps. Four numbered sections, each a bold
principle + imperative bullets + a "test"/verify line, bracketed by a "caution over
speed" tradeoff note and a "these are working if…" success-metric footer.

## The four guidelines (verbatim principle statements)

1. **Think Before Coding** — "Don't assume. Don't hide confusion. Surface tradeoffs."
2. **Simplicity First** — "Minimum code that solves the problem. Nothing speculative."
3. **Surgical Changes** — "Touch only what you must. Clean up only your own mess."
4. **Goal-Driven Execution** — "Define success criteria. Loop until verified."

Format notes worth keeping: imperative voice; per-section "test" (e.g. *"every
changed line traces to the request"*, *"would a senior engineer call this
overcomplicated?"*); the explicit tradeoff header ("bias toward caution over speed;
for trivial tasks use judgment"); the closing falsifiable success metric.

## Why it's relevant to our template

These are the **front-door posture** our A-rules already enforce *downstream* but
never named as a standalone, always-read habit:
- "Think before" ≈ A005 design-first + the `NEEDS_CONTEXT` escalation path.
- "Simplicity / surgical" ≈ Gate-4a over/under-build + conform-to-codebase + atomic
  commits (git-workflow #2-3).
- "Goal-driven / loop until verified" ≈ A001 TDD + A003 verification-before-completion.

The user asked to adopt this **format** across both the orchestrator (root CLAUDE.md)
and every service / area repo it controls. → drives [[coding-conduct-front-door]].

## Adoption note

De-domain-specified (no tech-stack opinions) and reconciled with our existing rules
(esp. "no error handling for impossible scenarios" clarified against
`programming-fundamentals.md` #4 "errors are values — handle real ones deliberately").
