---
url: https://agents.md/
title: "AGENTS.md — a simple, open format for guiding coding agents"
type: doc
author: Agentic AI Foundation (Linux Foundation)
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [adjacent-tools, claude-code-core]
quality: 5
status: distilled
---

## TL;DR
- **AGENTS.md is an open, plain-Markdown standard** for telling any coding
  agent how to work in a repo — a "README for agents." No required fields;
  use any headings.
- **Read by ~21 named tools** — Codex, Cursor, GitHub Copilot, Gemini CLI,
  Aider, Amp, Jules, Zed, Windsurf, goose, opencode, Devin, Warp, VS Code,
  and more. Adopted by **60,000+ open-source projects**.
- **Stewarded by the Agentic AI Foundation under the Linux Foundation** —
  not a single-vendor convention.

## Key takeaways
- **Monorepo precedence:** the **closest** `AGENTS.md` to the edited file
  wins; an **explicit user prompt overrides** all file-based instructions.
- **Test commands listed in it are executed** by agents to validate changes
  before completing a task.
- Claude Code reads `CLAUDE.md`, not `AGENTS.md` — so a repo that wants both
  Claude Code *and* other agents to follow one rule set needs both files,
  pointing at one source of truth.

## Quotes / evidence
> "use any headings you like; the agent simply parses the text you provide."
> — agents.md (plain Markdown, no required frontmatter)

## Relevance to our template
- **Could affect:** ship a `core/AGENTS.md` (thin pointer → `CLAUDE.md`) so
  every installed project is legible to non-Claude agents without
  duplicating rules. Supporting evidence in inbox: `arxiv.org/abs/2601.20404`
  (AGENTS.md present → ~28.6% lower runtime / ~16.6% fewer output tokens),
  `vercel.com/blog/agents-md-outperforms-skills-...` (passive always-present
  context beats active retrieval), `blog.modelcontextprotocol.io/...mcp-joins-agentic-ai-foundation`
  (governance / stability).
- **Connects to:** [[agents-md-cross-tool-interop-via-pointer]] (synthesis).
- **Open questions:** pointer vs inline — a pure pointer guarantees single
  source of truth but relies on the agent following the reference; resolved
  in synthesis by keeping a pointer + the stable non-negotiables restated.
