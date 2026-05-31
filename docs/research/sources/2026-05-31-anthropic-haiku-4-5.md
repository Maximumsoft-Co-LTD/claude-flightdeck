---
url: https://www.anthropic.com/news/claude-haiku-4-5
title: "Claude Haiku 4.5"
type: doc
author: Anthropic
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [claude-code-core]
quality: 5
status: distilled
---

## TL;DR
- Haiku 4.5 delivers **near-frontier coding** quality at roughly **1/3 the
  cost** and **2×+ the speed** of the frontier tier.
- Positioned explicitly as the cheap, fast worker for high-throughput,
  lower-judgment work — and as a subagent tier in orchestrated systems.

## Key takeaways
- Confirms a real, ~order-of-magnitude price/latency gradient *within* the
  Claude family — so "which model" is a first-class cost lever, not a
  rounding error.
- The cheap tier is now good enough for navigation / mechanical edits that
  previously felt risky to hand to a small model.

## Relevance to our template
- **Could affect:** agent `model:` frontmatter + the delegation routing
  guidance. Our engineers defaulted to `opus`, contradicting our own
  `agent-delegation-best-practices.md` §3 (Sonnet = implementation default).
  Evidence to (a) hoist routing into the always-loaded rule and (b) align the
  engineer defaults to the cheapest tier that clears the gates.
