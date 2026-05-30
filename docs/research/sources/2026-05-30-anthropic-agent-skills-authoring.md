---
url: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
title: Equipping agents for the real world with Agent Skills
type: blog
author: Anthropic (Engineering)
date_found: 2026-05-30
date_processed: 2026-05-30
topics: [claude-code-core, sdlc-with-ai]
quality: 5
status: distilled
---

## TL;DR
- A skill's `name` + `description` are preloaded into the system prompt and are the **first filter** Claude uses to decide whether to trigger — so they must signal *when* to use the skill, not just what it does.
- **Progressive disclosure** is the core mechanism: structure a skill "like a well-organized manual" — table of contents → chapters → appendix — and load only what's needed, with extra files referenced from `SKILL.md` and pulled on demand.
- Build skills from **observed gaps**, not predicted ones: run agents on representative tasks, watch where they struggle, encode that.
- Skills should be **iterated with Claude in the loop** — ask it to capture successful approaches and common mistakes into the skill during real work.

## Key takeaways
- **Trigger quality is description quality.** Since metadata is the always-loaded part, a vague description = a skill that never fires (or fires wrong). This is exactly the CSO / trigger-symptom-based `description` rule our template already enforces — now with a primary-source rationale.
- **Split a `SKILL.md` once it gets unwieldy**, especially for content that is "mutually exclusive or rarely used together" — moving rarely-co-used paths into separate files directly cuts token usage.
- **Be explicit about code intent:** state whether Claude should *execute* a script (deterministic ops) or *read* it as reference. Ambiguity wastes context.
- **Monitor real usage:** watch for unexpected execution paths or overreliance on certain context; tune `name`/`description` when activation is off.
- **Eval-driven:** "Identify specific gaps in your agents' capabilities by running them on representative tasks and observing where they struggle."

## Quotes / evidence
> "a well-organized manual that starts with a table of contents, then specific chapters, and finally a detailed appendix"

> "Ask Claude to capture its successful approaches and common mistakes into reusable context and code within a skill."

## Relevance to our template
- **Could affect:** `CONTRIBUTING.md` ("Improving a skill" section), the `core/` SKILL.md header rules (`name`/`description`/`## Token budget`), and any skill-authoring guidance in `docs/`.
- **Connects to:** [[2026-05-30-anthropic-context-engineering]] (progressive disclosure is context engineering applied to skills); the `agent-skills/overview` spec doc in the inbox (frontmatter schema).
- **Open questions:** Does our current CONTRIBUTING guidance explicitly tell authors to *split* unwieldy SKILL.md files and to distinguish execute-vs-read scripts? If not, that's a concrete gap to close.
