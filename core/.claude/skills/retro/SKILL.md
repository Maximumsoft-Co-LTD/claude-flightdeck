---
name: retro
description: "Run sprint close — aggregate per-task mini-retros, audit the backlog (HARD gate), classify findings into fix-now vs defer, fix process bugs immediately, write the full retro file, and move STATUS prose to STATUS-archive. Use when the user says '/retro', 'close the sprint', 'sprint retrospective', 'wrap up sprint XX'."
user_invocable: true
---

# /retro — Sprint Retrospective (Reflect + Act)

**The retro fixes problems immediately — it does not just document them.**

The live per-task mini-retros at `docs/project/retros/sprint-S<N>-tasks.md` are the PRIMARY input. The full retro file aggregates + classifies + acts on them. The backlog audit at Step 8 is a **HARD GATE** — mismatch ≠ 0 blocks the retro close.

## Token budget (MANDATORY)

- One `Read` of the live mini-retro file with `limit: 400` is the budget for the primary input.
- One `Read` of the sprint file with `limit: 200` for the task table.
- All other inputs via `Grep` (backlog audit, lesson recurrence, etc.).
- Never full-Read every design doc — quote at most a handful of lines per task.

## Steps

1. **Read the live mini-retro file** — `docs/project/retros/sprint-S<N>-tasks.md`. If this file is empty or missing, the sprint failed the per-task retro discipline; flag it as a process loss in the full retro.
1b. **Read `docs/project/FOLLOWUPS.md`** — open rows are candidates for "consumed this sprint?" reconciliation in Step 8b. Note the highest existing `F####` ID so you can pick the next free one if you append.
2. **Read the sprint file** + `git log` since the sprint open date for each touched repo.
3. **Cross-cutting drift detection** — for whatever invariants apply to {{PROJECT_NAME}} (contract drift, schema drift, multi-tenancy bypass, observability gaps), grep + flag any drift. Each drift = a finding.
4. **Ask the user** (or "auto" to generate from data) for top wins + top issues.
5. **Create the retro file** `docs/project/retros/sprint-S<N>.md`.
6. **Classify each action item** — `fix NOW (this commit)` vs `defer (new backlog row or sprint follow-up)`.
7. **Execute every "Fix Now" item immediately** — do NOT commit the retro until they land. Update affected skills + rules in the same commit.
8. **Backlog audit (HARD GATE — mismatch ≠ 0 blocks retro close)**:
   ```bash
   SPRINT=S<N>
   grep -nE "$SPRINT\b" docs/project/backlog.md | grep -vE "done $SPRINT|\[~\] Partial|moved to S"
   ```
   Any returned line = mismatch (row mentions the sprint but is NOT marked done / partial / moved). Resolve each before continuing:
   - Task was done → update row to `done S<N>`
   - Task was NOT done → reopen the sprint OR move the row out with a `moved to S<M>` note
   - Cite the final result in the retro: `Backlog audit: <N>/<N> rows matched · 0 mismatches`
8b. **FOLLOWUPS.md verification (HARD GATE)** — this step **verifies** the writes performed by the `sprint-retro-author` agent (Step 5 of its body). It does NOT write follow-ups itself; the agent is the writer.

   - **Block the retro close** if `Grep docs/project/FOLLOWUPS.md '## Open'` returns any row whose `From task / sprint` cell references this sprint AND whose `Status` is still `open`. Every sprint-touched follow-up must end the sprint in `in-progress`, `consumed-by:<task-id>`, or `wont-do (reason)` — open is process loss.
   - Verify the schema headers exist (`## Open` table with `ID | From task / sprint | Item | Type | Priority | Date opened | Owner | Status`; `## Closed` is a superset with `Consumed by | Date consumed`).
   - Assert at least one row was inspected; cite count: `Follow-ups scanned: N` (or `Follow-ups scanned: 0 — FOLLOWUPS.md empty, no follow-up from prior sprints`).
   - If any check fails → return to `sprint-retro-author` with the specific gap; do not patch the table inline.
   - On pass, cite the result in the retro: `Follow-ups: X consumed · Y new · Z still open · 0 sprint-touched rows left as open`.
9. **Recurring-lesson promotion** — if a finding shows up for the 2nd+ time in the project's lessons log, it earns a permanent rule. `sprint-retro-author` drafts it under the retro's `## Candidate A-rules` (it proposes; it never edits `brain-hot.md`). Landing it is **operator-gated**: run **`/ratify-rules`** to walk each candidate through ratify / defer / drop and append the approved ones to `brain-hot.md` (`A011+`) + the lesson-trigger map. Don't hand-edit `brain-hot.md` here.
10. **Update affected skills + rules** — same commit. If a skill caused the problem, update it before closing the retro.
11. **Mark sprint Done in `docs/project/STATUS.md`** + MOVE prose to `docs/project/STATUS-archive.md` in the SAME commit (the STATUS update protocol — keep STATUS.md a single-row pointer, not a journal).
12. **Refresh slim indexes** — `/index-refresh` for `docs/project/sprints/INDEX.md` + `docs/project/backlog-index.md` + `docs/project/sprints/sprint-S<N>-index.md`.
13. **Commit all retro changes** — `docs(retro): close sprint S<N>; backlog audit clean; fix-now items shipped`.

## What goes into the retro file (template)

- Sprint header — number, theme, dates, completion %.
- **Per-task summary** — aggregated from the mini-retros.
- **What went well** (top 3-5, with cites).
- **What didn't go well** (top 3-5, with cites + root cause).
- **Drift findings** (per Step 3).
- **Follow-ups touched** — table: `F#### · status change · consumed by (if any)`.
- **Action items** — table: `id | item | classification | owner | landed-this-commit?`
- **Recurring lessons** promoted to rules this retro.
- **Backlog audit** result (per Step 8).
- **Lessons learned** added to `brain-hot.md`.

## Rules

- "Didn't go well" items = process bugs — fix them NOW, in this commit.
- Every lesson → `brain-hot.md` immediately (do not defer).
- Skills that caused problems → update before the retro ends, same commit.
- Recurring lessons (2+ occurrences) → promote to a project rule.
- The backlog audit is a hard gate. No exceptions.
