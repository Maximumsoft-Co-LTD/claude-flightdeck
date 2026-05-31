---
topic: agents-md-cross-tool-interop-via-pointer
track: adjacent-tools
sources:
  - ../../sources/2026-05-31-agents-md-open-standard.md
supporting:
  - https://arxiv.org/abs/2601.20404
  - https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals
  - https://blog.modelcontextprotocol.io/posts/2025-12-09-mcp-joins-agentic-ai-foundation/
  - https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
date: 2026-05-31
confidence: high
---

## Pattern observed
`AGENTS.md` is now the **de-facto cross-tool standard** for repo-level agent
instructions: ~21 tools read it, 60,000+ repos use it, and it's governed by
the Linux Foundation (stable to build on). Two independent results show it's
not just interop theater — an empirical study found its presence cuts agent
runtime ~28.6% and output tokens ~16.6%, and Vercel found "passive" (always
present) context beats "active retrieval" because the agent has no decision
point at which to skip it.

Our template centers on `CLAUDE.md`, which **only Claude Code reads**. A team
that opens the same repo with Codex / Cursor / Copilot / Gemini CLI gets
*none* of our rules — they're invisible to those tools. That's a real gap:
the control plane's whole value is "consistent process," and it silently
doesn't apply the moment someone uses a non-Claude agent.

## Why it matters for our SDLC
This is **interop + consistency across the whole team's toolchain**, touching
every stage (the rules that govern design → build → review only bind agents
that can see them). Closing it means the template's discipline follows the
*repo*, not the *tool*.

## Proposed template change
- **Type:** new file (core) + installer wiring + doc
- **Target file(s):**
  - NEW `core/AGENTS.md` — thin pointer to `CLAUDE.md` + the stable
    non-negotiables (design-first, test-first, review-gated, conform,
    agent-config-is-executable). No rule duplication.
  - `core/.flightdeck-upgrade.json` — classify `AGENTS.md` as
    `seed_then_user_extends` (never clobbered on upgrade).
  - `install.sh` — add `AGENTS.md` to the re-install backup loop (preserve a
    user's customized copy, like `CLAUDE.md`).
  - `core/CLAUDE.md.tmpl` + `README.md` — one-line note that AGENTS.md is a
    pointer and CLAUDE.md is the single source of truth.
- **Design decision (pointer vs inline):** **pointer** wins — a single source
  of truth (CLAUDE.md) that can't drift beats duplicated rules. We restate
  only the *stable* non-negotiables (A-rule-level, rarely change) so a tool
  that reads only AGENTS.md still gets the headlines, then routes to
  CLAUDE.md for detail.
- **Friction-or-quality:** **quality** — the template's rules now bind every
  agent on the repo, not only Claude Code. Zero friction (one extra file).

## Counter-evidence / risks
- A pure pointer relies on the agent following the reference. Mitigated by
  restating the stable non-negotiables inline + a strong "read CLAUDE.md
  first" directive.
- Two files *could* drift — mitigated by keeping AGENTS.md content
  stable/minimal and stating (in both files + a maintainer comment) that
  CLAUDE.md is canonical and rules never go in AGENTS.md.
- Must not clobber a project's existing AGENTS.md → handled by
  `seed_then_user_extends` + the backup loop.

## Status
- [x] Proposed (this note)
- [x] Promoted to `apply/proposed/` → [agents-md-interop.md](../../apply/proposed/agents-md-interop.md)
- [x] Shipped → [../../apply/shipped/agents-md-interop.md](../../apply/shipped/agents-md-interop.md)
