---
name: progress
description: "Print a sprint progress dashboard — task status, completion rate, blockers, per-repo / per-component breakdown. Read-only: never writes. Use when the user says '/progress', 'where are we', 'what's blocked', 'dashboard', 'sprint status', 'how's the sprint going', 'show status', or wants a mid-sprint check-in."
user_invocable: true
---

# /progress — Sprint Dashboard

A read-only mid-sprint snapshot. Never writes.

## Token budget (MANDATORY)

- One `Read` of the active sprint file with `limit: 200` is the budget — header + table.
- All other queries via `Grep` (status counts, blockers, per-repo rollup).
- If `git log` is needed for stale-task detection, scope it to the sprint window.

## Steps

1. **Find the active sprint file** — `Glob` `docs/project/sprints/sprint-*.md`, pick the one whose header marks it active (or the one referenced by `docs/project/STATUS.md`).
2. **Read the task table** with `limit: 200`.
3. **Calculate metrics** — Total / Done / In Progress / Not Started / Blocked / Completion %.
4. **Display the dashboard**:
   ```
   ## Sprint S<N>: <theme>
   Progress: [======>   ] X/Y (Z%)

   | Task ID | Component | Status | Owner | Blocker |
   |---|---|---|---|---|
   ```
5. **Per-component / per-repo summary**:
   ```
   | Component | Done | In Progress | Remaining |
   ```
6. **Cross-cutting coverage** (if applicable to {{PROJECT_NAME}}) — e.g. contract / event-schema / observability coverage rollup.
7. **Flag stale tasks** — In Progress for >2 days (use the sprint file's `Last Update` column or a `git log -1` on the task's design doc).

## Rules

- **Read-only.** Never modify files.
- If no active sprint → suggest creating one or running `/index-refresh`.
- If the sprint file is missing the task table → print a one-line error pointing to `docs/setup/index-discipline.md`.
