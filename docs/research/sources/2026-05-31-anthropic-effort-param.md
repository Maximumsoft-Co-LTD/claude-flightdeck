---
url: https://platform.claude.com/docs/en/build-with-claude/effort
title: "Effort parameter"
type: doc
author: Anthropic (platform docs)
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [claude-code-core]
quality: 5
status: distilled
---

## TL;DR
- The `effort` parameter (low / med / high / xhigh / max) trades intelligence
  against cost + latency **within a single model**.
- A finer-grained lever than swapping model tiers: you can dial a model down
  for cheap, bounded work before reaching for a different model.

## Key takeaways
- Cost-aware routing has two axes, not one: **model tier** (Haiku/Sonnet/Opus)
  AND **effort within a tier**. Reach for effort before jumping a whole tier.
- Pairs with prompt caching and the multi-agent token multiplier as the set of
  knobs that govern spend per dispatch.

## Relevance to our template
- **Could affect:** the routing section — should mention `effort` as the
  intermediate knob so operators don't over-escalate to Opus when a
  higher-effort Sonnet run would do.
