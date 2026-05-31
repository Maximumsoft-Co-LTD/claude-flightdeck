---
url: https://www.augmentcode.com/guides/ai-model-routing-guide
title: "AI model routing guide"
type: blog
author: Augment Code
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [claude-code-core]
quality: 4
status: distilled
---

## TL;DR
- Practitioner routing playbook: **Opus = planning**, **Sonnet =
  implementation**, **Haiku = navigation / cheap lookups**.
- Match the model to the *judgment density* of the step, not to the project.

## Key takeaways
- Independent practitioner convergence on the same tiering Anthropic's pricing
  implies — strong corroboration for a default routing table.
- "Planning/synthesis = top tier; implementation-with-a-spec = mid tier;
  mechanical = cheap tier" is the shape to encode.

## Relevance to our template
- **Could affect:** the per-agent default column — orchestrator/design-doc
  (planning/synthesis) → Opus; engineers (implementation) → Sonnet; mechanical
  navigation → Haiku. Maps cleanly onto our agent roster.
- Supporting evidence: RouteLLM (arXiv 2406.18665) — learned hard→strong,
  easy→cheap routing from preference data — the academic backbone for the same
  idea.
