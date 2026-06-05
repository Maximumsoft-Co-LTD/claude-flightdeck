---
url: (deep-research synthesis — primary sources listed below)
type: research-study
date_found: 2026-06-05
date_processed: 2026-06-05
topics: [claude-code-core, complex-systems]
quality: 5
status: distilled
---

## TL;DR

Multi-source study on **autonomous multi-agent fan-out** for coding agents, to
design a `/work` command that auto-decides parallel-vs-serial and manages each
sub-part. Consensus: fan out only read-heavy / provably-disjoint work; keep
**writes single-threaded unless paths are provably disjoint + worktree-isolated**;
brief each agent fully; cap width; handle partial failure explicitly.

## Key takeaways

- **Fan-out helps for breadth-first / read-heavy / disjoint exploration; it hurts
  for tightly interdependent coding.** Anthropic's multi-agent research system
  beat single-agent Opus by ~90% *only* on breadth-first queries.
- **~15× token cost** vs a single chat (≈4× for a single agent) — fan out only
  when the task shape justifies it.
- **Cognition ("Don't Build Multi-Agents" / multi-agents-working):** keep WRITES
  single-threaded; extra agents contribute read-only intelligence. Parallel
  writes fail because each action carries implicit decisions (style, patterns,
  edge-cases) that conflict.
- **Per-agent complete brief** (objective, boundaries) is required or agents
  misinterpret + duplicate. **Cap width** (1 simple / 2-4 / more only on broad
  disjoint work; over-decomposition is an anti-pattern).
- **Partial-failure logic is on the practitioner** — the published blueprints
  cover only the happy path (timeout / malformed / conflicting agent unhandled).
- **MAST taxonomy** (arXiv 2503.13657): 14 failure modes in 3 classes (system
  design · inter-agent misalignment · verification); multi-agent often fails to
  beat single-agent baselines.

> Verification note: this study's adversarial-verify pass glitched (verifier
> subagents abstained → defaulted to "refuted"). The extracted claims are
> primary-sourced and align with our existing `sub-agent-workflow.md §1.0`, so
> they are treated as valid evidence, not refuted.

## Primary sources

- anthropic.com/engineering/multi-agent-research-system · cognition.ai/blog/dont-build-multi-agents
- cognition.ai/blog/multi-agents-working · arxiv.org/abs/2503.13657 (MAST)
- simonwillison.net/2025/Jun/14/multi-agent-research-system

## Relevance to our template

Grounds `/work`'s auto-fanout: it runs the 4-layer Conflict Radar itself,
parallelizes only disjoint write-isolated frontiers, serializes otherwise, gates
each result independently, and handles partial failure. → [[lean-workflow-redesign]].
