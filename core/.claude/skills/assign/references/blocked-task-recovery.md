# Blocked Task Recovery

> Loaded by `/assign` Step 3 when the task readiness check finds a
> blocker. The goal is to never dispatch a task that will silently
> stall — but also never refuse a task when the blocker has a clean
> recovery path.

## Block reasons + decision tree

### Reason 1 — `blockedBy` is open (cited task is not Done)

```
Task TG-S04.12 has blockedBy: TG-S04.08
Current TG-S04.08 status: [~] Partial
```

**Decision:**

- If `blockedBy` is `[~] Partial` and the partial is on a separate
  concern (e.g. tests pending) → **proceed with caution**. Warn the
  user, mention the partial state, ask for explicit go-ahead.
- If `blockedBy` is `[ ] Not Started` → **refuse**. Suggest the user
  pick the blocker first (`/assign <blocker>` or `/next-task`).
- If `blockedBy` is `[!] Blocked` → **refuse**. Surface the upstream
  blocker; the user has to unblock that first.
- If `blockedBy` is `[x] Done` → not actually blocked; the sprint
  file is stale. Update the sprint row to remove the blocker and
  proceed.

**Recovery script:**
```bash
# Confirm the blocker's true status
grep "TG-S04.08" docs/project/sprints/S04/tasks.md
# Read the blocker's design doc for context
ls docs/project/sprints/S04/designs/*S04.08*.md
```

### Reason 2 — Design doc does not exist

```
Task TG-S04.12 has no design doc at docs/project/sprints/S04/designs/D012-*.md
```

**Decision:** **refuse dispatch.** A005 (design-doc-first) is
non-negotiable. The recovery is to dispatch `design-doc-writer`
FIRST, then resume `/assign` after the doc lands.

**Recovery sequence:**
```
1. Agent(subagent_type="design-doc-writer",
         prompt="Author the design doc for TG-S04.12 (see sprint row
                 + relevant CLAUDE.md)")
2. Wait for the design doc to commit.
3. Resume /assign TG-S04.12.
```

If the user insists "skip the design doc, just do it" — politely
refuse and cite A005. The cost of an under-spec'd dispatch is higher
than the time to write the doc.

### Reason 3 — Design doc exists but is <200 lines (under-specified)

```
docs/project/sprints/S04/designs/D012-add-tenant-invites.md: 87 lines
```

**Decision:** **proceed with a WARN.** The dispatched agent's
pre-task ritual (Step 11) emits the same warning. If the task is
non-trivial, the user should consider:

- A back-and-forth with `design-doc-writer` to expand it.
- Or proceed knowing the agent may need clarification mid-task.

**Recovery option:**
```
SendMessage(to: "design-doc-writer-running-agent",
            message: "Expand §Approach and §Tests to ≥200 lines total
                      for TG-S04.12")
```

### Reason 4 — Design doc says `Status: Draft` (not approved)

```
docs/project/sprints/S04/designs/D012-*.md:
> **Status:** Draft
```

**Decision:** **refuse dispatch.** A Draft doc is not the contract
yet — it can change while the agent is working, leading to wasted
work.

**Recovery:**
1. Surface the Draft status to the user.
2. Ask: "Approve the design doc as-is? (changes Status to `Approved`)
   Or send back to `design-doc-writer` for revisions?"
3. After Approved, resume `/assign`.

### Reason 5 — Dependency is `[~] Partial`

```
Task TG-S04.12 depends on TG-S04.08 contract
TG-S04.08 status: [~] Partial — contract committed, but consumer
                  integration tests pending
```

**Decision:** depends on what's partial.

- If the partial-piece is the **contract surface** the new task
  consumes → **safe to proceed**. The contract is locked; the
  partial-piece is downstream.
- If the partial-piece is the **producer behavior** the new task
  depends on → **refuse**. The partial producer might still ship
  bugs that block this task's tests.

**Recovery:**
```bash
# Check which part of the partial is missing
grep "TG-S04.08" docs/project/sprints/S04/tasks.md | head -20

# Or read the partial task's design doc §Status section
```

### Reason 6 — `Touched Files` matrix overlaps with an open PR

```
Task TG-S04.12 declares: internal/app/tenant/create_invite.go
Open PR #142 already modifies: internal/app/tenant/create_invite.go
```

**Decision:** **refuse parallel dispatch.** This is the Conflict
Radar Layer 1 territory (see `/dispatch-parallel`). Two
simultaneous edits to the same file will conflict on merge.

**Recovery:**
- Wait for PR #142 to merge.
- Or pick a different task that doesn't overlap.
- Or split the new task so it touches different files.

### Reason 7 — A custom-preset agent is referenced but not installed

```
Task TG-S04.12 maps to `<custom-preset-engineer>` per repo-to-agent-mapping.md
But .claude/agents/<custom-preset-engineer>.md does not exist
```

**Decision:** the custom preset isn't installed. (The core engineers —
`backend-engineer` / `frontend-engineer` — are always present, so this only
happens when a task is mapped to a preset agent that wasn't installed.)

**Recovery:**
1. Surface the missing agent to the user.
2. Suggest re-running the installer with the preset added:
   `install.sh <this-project> --preset <name> --force`.
3. Or, as a fallback, dispatch the matching **core** engineer
   (`backend-engineer` / `frontend-engineer`) — it reads
   `.claude/rules/code-style.md` and conforms to the codebase anyway.
   Flag the substitution in the dispatch report.

### Reason 8 — Migration referenced but not committed

```
Task TG-S04.12 mentions migration 20260520_create_tenant_invites.sql
No such file exists in migrations/
```

**Decision:** **refuse — design doc references non-existent state.**

**Recovery:** the design-doc-writer must commit the migration file
(or stub it) before dispatch. Same flow as Reason 2 / 4.

## General principle

> Refuse early, fix once. A blocked dispatch that proceeds anyway
> wastes more agent time than fixing the blocker first.

When in doubt, refuse + surface the blocker + suggest the recovery
path. Never proceed silently past a block.

## See also

- `dispatch-prompt-template.md` — the prompt the dispatch finally
  uses
- `../SKILL.md` Step 3 — where this file is consulted
- `../../next-task/SKILL.md` — sister skill that picks tasks and
  applies the same blocker checks
