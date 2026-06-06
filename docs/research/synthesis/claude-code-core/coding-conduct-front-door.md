---
topic: coding-conduct-front-door
sources:
  - sources/2026-06-06-karpathy-coding-conduct.md
date: 2026-06-06
confidence: high
---

## Pattern observed

Our rule set is strong on **enforcement** (the 6-gate, A001-A010, phase-matrix) but
had no single, always-read statement of the *behavioral posture* an agent should
hold **before** the rigor engages. The Karpathy-style behavioral-guidelines CLAUDE.md
names exactly that gap in four memorable principles — and the gap matters because most
LLM coding failures are behavioral (assume / over-build / scope-creep / unverified
done), not knowledge gaps the A-rules already cover.

## Why it matters for our SDLC

A front-door conduct layer is **cheap leverage**: it's read once per task by every
agent (via the pre-task ritual), it frames the A-rules ("these are the habit, the
A-rules are how we enforce them under the 6-gate"), and — critically for a *multi-repo*
orchestrator — it gives the orchestrator AND every service / area repo it controls the
*same* four guidelines, so behavior is consistent no matter which repo an agent lands in.

## Proposed template change → SHIPPED

- New canonical rule `core/.claude/rules/coding-conduct.md` — the four guidelines in
  the source's format (bold principle + imperative bullets + a "test" line + the
  tradeoff header + the "working if" footer), de-domain-specified and cross-linked to
  the A-rules they map onto.
- Root `core/CLAUDE.md.tmpl` gains a compact "Behavioral guidelines (every agent,
  every repo)" section (4 one-liners + pointer).
- Per-area `CLAUDE.md` draft template gains a fixed `## Coding conduct` pointer so
  every generated service repo carries it.
- Wired into the pre-task ritual (Step 2) + brain-hot "Where to look next" so every
  dispatched agent reads it.

## Expected improvement

Fewer unnecessary diff lines, fewer over-engineered rewrites, and clarifying questions
that land *before* implementation — the source's own falsifiable success metric, now
applied uniformly across the orchestrator and the repos it controls.

## Counter-evidence / risks

- Could read as redundant with the A-rules → mitigated by framing it as the *posture*
  (habit) vs the A-rules as *enforcement* (gate), with explicit ties, not a restatement.
- "Simplicity / no error handling for impossible scenarios" could be misread as
  license to swallow errors → explicitly reconciled with `programming-fundamentals.md`
  #4 (real, reachable errors are still handled deliberately).

## Status

- [x] In `apply/shipped/coding-conduct-rules.md`
- [x] Shipped (local, branch `feat/coding-conduct-rules`, upgrade-eligible)
