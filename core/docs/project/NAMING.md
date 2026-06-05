# Naming & ID Cheat-Sheet — {{PROJECT_NAME}}

> The one place that defines every identifier the workflow uses. When a skill,
> rule, or doc needs "what's the format for X", it links here.

## Identifiers

| ID | Format | What it names | Lives in |
|---|---|---|---|
| **Sprint** | `S<N>` (e.g. `S01`, `S12`) | a sprint | folder `sprints/S<N>/` |
| **Task** | `{{TASK_ID_PREFIX}}-S<N>.<NN>` (e.g. `{{TASK_ID_PREFIX}}-S03.04`) | a task in a sprint | row in `sprints/S<N>/tasks.md` |
| **Design** | `D<NNN>-<slug>` (e.g. `D012-add-notifications`) | a per-task design doc | `sprints/S<N>/designs/D<NNN>-<slug>.md` |
| **Backlog** | `B###` (e.g. `B042`) | a backlog item | row in `backlog.md` |
| **Follow-up** | `F####` (e.g. `F0007`) | deferred work surfaced by a retro | `backlog.md` `## Follow-ups` |
| **Idea** | `D###-<slug>` | a pre-backlog captured idea | `ideas/D###-<slug>.md` |
| **Brief** | `<TASK_ID>-<role>.md` | a dispatch brief (role: `design\|impl\|review\|retro`) | `sprints/S<N>/designs/_briefs/` |

## Enums (match the phase matrix)

- **Type** — `feat | fix | refactor | chore | docs | spike | release`
- **Priority** — `P0 | P1 | P2 | P3` (backlog) · `low | med | high` (follow-ups)
- **Size** — `S | M | L | XL` (see `../designs/_templates/SIZE_TIERS.md`)
- **Task state** (board) — `[ ]` not started · `[~]` in progress/partial · `[x]` done · `[B]` blocked
- **Backlog status** — `new | scheduled S## | done S## | deferred | wontfix`
- **Follow-up status** — `open | in-progress | consumed-by:<task-id> | wont-do (reason)`

## Counters serialize through the integration base

`F####` (and `B###`, `D<NNN>`) ID assignment is monotonic — the next free number
is read from the tail of the relevant file. **Never assign a new `F####`/`B###`
from a parallel worktree**: two concurrent writers grab the same number and
collide on merge. At sprint close the integration session is the sole writer.
See [`../playbooks/parallel-conflict-prevention.md`](../playbooks/parallel-conflict-prevention.md).

## See also

- [`README.md`](./README.md) — the folder model these IDs live in
- [`../designs/_templates/BACKLOG_ENTRY_TEMPLATE.md`](../designs/_templates/BACKLOG_ENTRY_TEMPLATE.md) — the backlog row format
