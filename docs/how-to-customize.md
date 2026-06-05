# How to customize the installed template

The installer gives you a working control plane; this doc covers the
common edits projects need on day 1.

## Day 1 — wire it to your project

### 1. Fill in `CLAUDE.md` (root)

The installer rendered placeholders but left guidance comments. Walk
through it once:

- **"What this repo is"** — replace the 2-3 sentence overview.
- **N1-N5** — keep the ones that apply; delete or rename the rest.
  Add N6 / N7 if your project has unique constraints (e.g. PII
  handling, FedRAMP boundary). Cap at 7.
- **Quick start** — replace example commands with your bootstrap
  (`make bootstrap`, `npm install`, `docker compose up`, …).
- **Subagent dispatch routing** — add a row per preset agent installed
  and per project-specific agent you create later.

### 2. Append project-local rules to `.claude/rules/brain-hot.md`

The core ships A001-A010 (universal: TDD, zero-bug, verification,
6-gate, design-first, no-claude-p, parallel safety, source-of-truth,
live retro, LSP-first). Append A011+ under the
`## Project-specific rules` section. Keep each rule to **one line**;
push detail into a separate file if needed.

Common project rules to consider:

- A011 — "Every write endpoint accepts `Idempotency-Key`" if you have
  retry-prone callers
- A012 — "Background services must be wired in `cmd/<svc>/main.go`"
  (L116) — preempts a common omission
- A013 — "Migrations are idempotent (`IF NOT EXISTS`)" so a re-run can't
  break a bootstrap
- A014 — your auth / RBAC policy (every protected route declares
  required roles, …)
- A015 — your i18n discipline (every user-facing string via `t()`)

### 3. Create the first sprint file

```bash
cp docs/designs/_templates/BACKLOG_ENTRY_TEMPLATE.md /tmp/_template-ref.md  # for reference
# Edit docs/project/sprints/S<N>/tasks.md — fill in your project's active sprint pointer
# Create docs/project/sprints/S01/tasks.md from scratch (use BACKLOG_ENTRY rows)
```

Then in Claude Code:

```
/idea           # turn a free-text feature idea into a discovery doc
/idea promote   # promote a backlog row into the sprint file
/work           # pick the first task to work on
```

### 4. (Optional) Point the Brain at your Obsidian vault

If `BRAIN_PATH` was blank at install, you're using the in-repo
`.claude/memory/`. To switch later:

```bash
# Edit .claude/rules/brain-hot.md — replace the BRAIN footer path with the absolute path
# Edit CLAUDE.md — update the "External Brain" line at the bottom
```

Migration: move your accumulated `lessons/` and `patterns/` from
`.claude/memory/` to the vault.

---

## Adding a per-area CLAUDE.md

If your project is a monorepo (backend/, frontend/, k8s/, run-local/),
each area benefits from its own CLAUDE.md.

```bash
# Template
mkdir -p backend
cat > backend/CLAUDE.md <<'EOF'
# CLAUDE.md — backend

> Operating manual for the Go service. Defers to root CLAUDE.md for
> cross-area rules. See root for non-negotiables N1-N5.

## Tech Stack
... (your specifics) ...

## Project Structure
cmd/{server,migrate,seed}, internal/{config,handler,middleware,...}

## Common Commands
- go test ./...
- go build -o /tmp/svc ./cmd/server
- make migrate-up
- make seed-dev

## Local rules (B-rules — backend specific)
- B001 — _your first backend rule_
EOF
```

The orchestrator + every specialized agent will read this on dispatch
via the pre-task ritual.

---

## Adding a per-project agent

For project-specific roles not covered by core or any preset.

```bash
# Example: an agent specialized in your domain-specific feature flag system
cat > .claude/agents/flag-engineer.md <<'EOF'
---
name: flag-engineer
description: Implement / audit feature flag changes. Reads the flag
  registry, ensures every flag has a default, expiry date, and metrics
  tag, then dispatches the right test for runtime evaluation.
model: opus
tools:
  - Glob
  - Grep
  - LS
  - Read
  - Bash
  - Edit
  - Write
  - TodoWrite
---

# flag-engineer

## Pre-task ritual

Read: `.claude/rules/agent-pre-task-ritual.md`, `.claude/rules/brain-hot.md`,
the area CLAUDE.md, and the relevant flag-registry file.

## What you do
... (specifics)
EOF
```

Then add a row to the dispatch routing table in root CLAUDE.md.

---

## Adding a project skill (slash command)

```bash
mkdir -p .claude/skills/my-skill
cat > .claude/skills/my-skill/SKILL.md <<'EOF'
---
name: my-skill
description: "What this skill does. Use when: '/my-skill', 'do the thing'."
user_invocable: true
---

# /my-skill

## Token budget (MANDATORY)
- Steps 1-N use Grep + offset Reads; do not full-Read files >200 lines.
- Do not re-read CLAUDE.md (harness auto-loads it).

## Steps
1. ...
2. ...
EOF
```

Every skill must have the `## Token budget` section — that's the
contract.

---

## Editing per-agent memory

Per-agent memory lives in `.claude/agent-memory/<agent>/MEMORY.md` and
optionally sub-folders. After a sub-agent finishes a task, append
findings:

```markdown
# .claude/agent-memory/senior-tech-lead/MEMORY.md

- [Sprint S03 - missing migration wiring](./feedback/sprint-S03-T08.md) —
  L116 fires when service has scheduler not wired in main.go
- [Sprint S04 - i18n key parity](./feedback/sprint-S04-T11.md) —
  hardcoded user-facing strings sneak in via toast components
```

Each linked file has the full context (1-2 paragraphs) so the agent can
recall the situation cold.

---

## When to lift back into the template

If you write a project-local rule, agent, or skill that's clearly
universal (not tied to your specific stack), consider lifting it back
into `AI-Workflows/core/` (or a new preset). The recipe:

1. Test it in your project for at least 2 sprints (proves it's real).
2. Strip project-specifics → genericize with placeholders.
3. Open a PR in `AI-Workflows` (or just edit your local copy).
4. Re-install into other projects that should get it (with `--force`
   after backing up — `install.sh` does this automatically).

There is no `install.sh upgrade` yet — diff manually.

---

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Bloating CLAUDE.md > 200 lines | Sessions slow to start; agents miss the bottom half | Push detail into `docs/setup/<topic>.md`; CLAUDE.md links to it |
| Adding A### rules without a `## Token budget` section in derived skills | Skills blow out context | Audit `grep -L 'Token budget' .claude/skills/*/SKILL.md` |
| Skipping the live mini-retro | Sprint close retro has nothing to aggregate | Make it part of `/review gates` — fail the gate if no retro row added |
| Letting the active sprint board grow past 1 screen | "Single-pane glance" stops being a glance | At sprint close, move the board's Glance prose into `docs/project/sprints/S<N>/retro.md` in the SAME commit |
| Mocking the database in integration tests | Tests pass; prod migration fails | Use real DB (testcontainers or shared dev DB); reserve mocks for unit tests only |
| Allowing self-summaries to replace the diff read | "Done" claims mask broken code | Make Gate 1 of `/review gates` blocking — no merge without diff inspection |
