---
url: https://cognition.ai/blog/dont-build-multi-agents
title: "Don't Build Multi-Agents"
type: blog
author: Cognition (Walden Yan)
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [claude-code-core]
quality: 5
status: distilled
---

## TL;DR
- **Parallel subagents make "conflicting assumptions not prescribed upfront"** —
  producing inconsistent outputs a final agent cannot reconcile. The vivid
  example: subagent 1 builds a Super Mario background, subagent 2 builds a
  Flappy Bird character; the merger is stuck "combining these two
  miscommunications."
- **Two principles:** (1) "Share context, and share full agent traces, not
  just individual messages"; (2) "Actions carry implicit decisions, and
  conflicting decisions carry bad results."
- **Recommended default:** a **single-threaded linear agent** with continuous
  context. For long tasks, add a dedicated model that **compresses** history
  into key decisions/events — not more parallel agents.
- Note: "In 2025, running multiple agents in collaboration only results in
  fragile systems" — dispersed decision-making + weak context-sharing.

## Key takeaways
- The bottleneck isn't raw capability, it's **context coherence**. Splitting
  work across agents splits the context that keeps decisions consistent.
- Even Claude Code spawns subtasks but "never does work in parallel" — the
  subtask agent lacks the main agent's context and parallel ones can conflict.
- This is the **counterweight** to pro-orchestration sources: multi-agent is
  a tool with a real, named failure mode, not a default.

## Quotes / evidence
> "Share context, and share full agent traces, not just individual messages."
> "Actions carry implicit decisions, and conflicting decisions carry bad results."

## Relevance to our template
- **Could affect:** our `sub-agent-workflow.md` decision tree + the
  `parallel-conflict-prevention.md` playbook are strong on *how to parallelize
  safely* but never say *when not to at all*. Add a "When NOT to use
  multi-agent" gate citing this + Anthropic's ~15x token cost + the MAST
  failure taxonomy.
- **Connects to:** [[when-not-to-parallelize]] (synthesis); inbox
  `anthropic.com/engineering/multi-agent-research-system` (~15x cost, failure
  modes), `arxiv.org/abs/2503.13657` (MAST — 14 multi-agent failure modes).
- **Open questions:** none material; this sharpens the existing "default to
  inline / serialize" stance rather than reversing it.
