---
url: https://arxiv.org/abs/2506.18315
title: "Property-Generated Solver (property-based feedback for code generation)"
type: paper
author: arXiv 2506.18315
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [sdlc-with-ai]
quality: 5
status: distilled
---

## TL;DR
- Driving code generation with **property-based** feedback (invariants that
  must hold for all inputs) beats example-based TDD by **+13.4% pass@1**.
- Properties catch counter-examples that a handful of example tests miss.

## Key takeaways
- Where the input space is large, a property ("encode∘decode == identity",
  "output always sorted") constrains behavior far more than three examples —
  and a generator actively hunts for the failing case.
- Pairs with Anthropic Frontier Red Team's Hypothesis-based invariant agent
  and Meta ACH's mutation testing as the "are the tests real?" toolkit.

## Relevance to our template
- **Could affect:** the "raise the bar" part of `test-discipline.md` — once a
  test isn't theater, property/invariant testing is the next rung, and mutation
  testing is the meta-check that the suite actually constrains behavior.
- Supporting: TDFlow (arXiv 2510.23761) — agentic TDD that minimizes
  test-hacking; Meta ACH (LLM mutation testing, 73% fault-targeted tests
  accepted).
