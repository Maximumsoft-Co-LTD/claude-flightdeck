---
url: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
title: Effective context engineering for AI agents
type: blog
author: Anthropic (Applied AI / Engineering)
date_found: 2026-05-30
date_processed: 2026-05-30
topics: [sdlc-with-ai, complex-systems, claude-code-core]
quality: 5
status: distilled
---

## TL;DR
- **Context engineering** = "curating and maintaining the optimal set of tokens during LLM inference" — the successor framing to prompt engineering, spanning system prompt, tools, external data, and message history across turns.
- The context window is a **finite resource**: models suffer "context rot" (degraded performance as tokens grow) and have an "attention budget" with diminishing returns. More context ≠ better.
- The guiding principle: find **"the smallest set of high-signal tokens that maximize the likelihood of your desired outcome"** at each step.

## Key takeaways
- **System-prompt altitude — the "Goldilocks zone":** specific enough to steer behavior, flexible enough to avoid brittle hardcoded logic. (Our lean `CLAUDE.md.tmpl` + 30-rule `brain-hot.md` cap is this principle in practice.)
- **Tool efficiency:** non-overlapping toolsets. "If engineers can't definitively say which tool should be used," the agent won't either — a sharp test for any MCP/tool surface we ship.
- **Just-in-time retrieval:** keep lightweight identifiers (paths, refs), load full data at runtime — "we generally don't memorize entire corpuses of information." Maps onto our LSP-first / Explore-then-read navigation.
- **Compaction:** near the limit, summarize — preserve "architectural decisions, unresolved bugs, and implementation details while discarding redundant tool outputs."
- **Structured note-taking:** persist progress *outside* the window so coherence survives "dozens of tool calls." This is the rationale for `brain-hot.md` and design-doc artifacts.
- **Sub-agent isolation:** specialized subagents with clean contexts as a scaling lever for long-horizon work — our orchestrator/subagent contract.

## Quotes / evidence
> "the smallest set of high-signal tokens that maximize the likelihood of your desired outcome"

> Tools should be such that engineers can "definitively say which tool should be used" in a given situation.

## Relevance to our template
- **Could affect:** `METHODOLOGY.md` (cite as the rationale for token discipline), the skill `## Token budget` requirement, the agent pre-task ritual (note-taking), and a potential "context-bloat" review gate.
- **Connects to:** [[2026-05-30-anthropic-agent-skills-authoring]] (progressive disclosure), the multi-agent-research-system and large-codebases links in the inbox.
- **Open questions:** Could we add an explicit review-gate check for CLAUDE.md / skill context bloat ("is every loaded token high-signal?") rather than leaving it implicit?
