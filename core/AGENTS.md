# AGENTS.md

> **The authoritative instructions for this project live in
> [`CLAUDE.md`](./CLAUDE.md). Read it first.**
>
> This file exists so coding agents that follow the open
> [AGENTS.md](https://agents.md) standard — Codex, Cursor, GitHub Copilot,
> Gemini CLI, Aider, Amp, Jules, Zed, Windsurf, and others — find the same
> source of truth that Claude Code reads from `CLAUDE.md`. **One source of
> truth, every agent.** Do not duplicate rules here; extend `CLAUDE.md`.

## How to work in this repo (all agents)

This project runs a **design-first, test-first, review-gated** workflow.
Before changing code, read `CLAUDE.md` for the full rules. The
non-negotiables that apply to every agent:

- **Design-first** — no production code without an agreed design/spec for
  non-trivial work.
- **Test-first** — a failing test precedes the implementation; bug fixes
  start with a failing regression test + a named root cause.
- **Review-gated** — changes pass the project's post-delegation review
  (inspect diff → build+test → boundary → spec-compliance → quality →
  wiring → smoke) before they are considered done.
- **Conform to the codebase** — match the project's existing structure and
  conventions (see `.claude/rules/code-style.md`); don't impose an
  architecture it doesn't use.
- **Committed agent config is executable** — treat changes to
  `.claude/settings*.json`, `.mcp.json`, and `.claude/hooks/*` as a
  security surface (see `docs/setup/agent-config-security.md`).

For everything else — area boundaries, commands, the dispatch map, the full
rule set — **`CLAUDE.md` is canonical.** In a monorepo, the closest
`CLAUDE.md`/`AGENTS.md` to the file you're editing wins; an explicit user
prompt overrides any file.

<!--
Maintainer note (not shipped guidance): keep this file a thin pointer.
The whole point is a single source of truth in CLAUDE.md so the two files
can't drift. If you must add project-specific agent guidance, add it to
CLAUDE.md (or the relevant area CLAUDE.md), not here.
-->
