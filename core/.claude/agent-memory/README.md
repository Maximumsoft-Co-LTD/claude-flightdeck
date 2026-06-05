# Agent Memory

Per-agent persistent memory. Each specialized agent gets a folder here
with its own `MEMORY.md` (index) + topic files. The agent reads its own
folder at the start of every task; humans append findings after
post-delegation review.

## Layout

```
agent-memory/
├── <prefix>-orchestrator/
│   ├── MEMORY.md
│   └── decisions/<short-slug>.md
├── design-doc-writer/
│   ├── MEMORY.md
│   └── patterns/<short-slug>.md
├── senior-tech-lead/
│   ├── MEMORY.md
│   └── feedback/sprint-S<N>-<task-id>.md
└── sprint-retro-author/
    └── MEMORY.md
```

Preset-installed agents create their own folders the first time they
write feedback.

## What goes here

- **Decisions made and why** — architectural choices, rejected
  alternatives, cost / latency tradeoffs the agent learned through
  prior work
- **Recurring feedback patterns** — "this reviewer keeps flagging X;
  preempt it next time"
- **Stack-specific gotchas** the agent has hit and resolved

## What does NOT go here

- File paths or symbol names from the current codebase (those rot fast
   — grep / LSP instead)
- Ephemeral task state (use `TaskCreate` / `docs/project/` instead)
- Specs, plans, or design docs (those live in `docs/`)
- Anything `.git`-tracked elsewhere (don't duplicate)

## Lifetime

Memory persists across sessions. When a memory becomes stale (claim no
longer holds), remove the line instead of marking it deprecated —
deprecated entries train the agent to ignore the file.

## Index discipline

Each `<agent>/MEMORY.md` is a flat index (~1 line per entry):

```markdown
- [Topic title](./feedback/2026-05-task-PROJ-S03.04.md) — one-line hook
```

Keep MEMORY.md ≤ 200 lines. If it grows beyond that, factor into
sub-folders (e.g. `decisions/`, `feedback/`, `patterns/`).
