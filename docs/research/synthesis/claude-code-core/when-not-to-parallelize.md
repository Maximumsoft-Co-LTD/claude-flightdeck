---
topic: when-not-to-parallelize
track: claude-code-core
sources:
  - ../../sources/2026-05-31-cognition-dont-build-multi-agents.md
supporting:
  - https://www.anthropic.com/engineering/multi-agent-research-system
  - https://arxiv.org/abs/2503.13657
  - https://arxiv.org/abs/2602.07150
date: 2026-05-31
confidence: high
---

## Pattern observed
The strongest practitioner + research signal of 2025-26 is **not** "parallelize
more" — it's "parallelize only when you must." Three independent sources
converge:
- **Cognition ("Don't Build Multi-Agents"):** parallel subagents make
  conflicting assumptions that can't be reconciled; default to a
  single-threaded agent with continuous context, compress rather than split.
- **Anthropic (multi-agent research system):** the orchestrator-worker pattern
  works for genuinely parallel read-heavy research but costs **~15× the tokens**
  of a single chat, and has real failure modes (spawning 50 subagents for a
  trivial query, agents distracting each other).
- **MAST (NeurIPS 2025):** an empirical taxonomy of **14 multi-agent failure
  modes** across 1600+ traces — most are specification / inter-agent
  misalignment, i.e. exactly the context-fragmentation Cognition describes.

Our control plane is strong on the *mechanics* of safe parallelism
(`parallel-conflict-prevention.md`'s 4 layers; `sub-agent-workflow.md`'s
decision tree already says "default to inline when in doubt"). What's missing
is an explicit, evidence-backed **"is multi-agent even the right call?"** gate
*before* the how-to-parallelize machinery — so the cost (~15×) and the named
failure mode (context fragmentation) are a conscious decision, not an
afterthought.

## Why it matters for our SDLC
This is the **dispatch decision** that precedes every fan-out. Getting it
wrong is expensive twice: 15× tokens *and* fragile, hard-to-reconcile output.
Making "default to one agent with good context; parallelize only when work is
provably disjoint AND read-heavy/independent" an explicit gate reduces both
cost and rework — pure quality/efficiency, no new friction (it only adds a
30-second check the orchestrator already half-does).

## Proposed template change
- **Type:** rule-update + playbook-update
- **Target file(s):**
  - `core/.claude/rules/sub-agent-workflow.md` — add **§1.0 "When NOT to use
    multi-agent"** *before* the §1 decision tree, citing ~15× cost +
    context-fragmentation + MAST, reinforcing "default to one well-briefed
    agent."
  - `core/docs/playbooks/parallel-conflict-prevention.md` — add a short
    **"First question: is multi-agent even right?"** note before the 4 layers.
- **Friction-or-quality:** **quality + cost** — prevents needless 15× spends
  and the fragmentation failure mode; reinforces (doesn't reverse) the
  existing "serialize / default-to-inline" stance.

## Counter-evidence / risks
- Multi-agent genuinely wins for read-heavy, provably-disjoint work (parallel
  Explore, independent file reviews) — the gate must *guide*, not ban. Keep
  the "when it IS right" path intact.
- Must stay de-domain-specified (process content only).

## Status
- [x] Proposed (this note)
- [x] Shipped → [../../apply/shipped/when-not-to-parallelize.md](../../apply/shipped/when-not-to-parallelize.md)
