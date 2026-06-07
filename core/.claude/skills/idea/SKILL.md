---
name: idea
description: "Use when the user types '/idea', 'capture an idea', 'I have a feature idea', 'record a request', 'refine D###', 'promote D### to backlog', or 'add to the backlog'. Three modes: capture a raw idea with structured questioning (was /discover), fill gaps on an existing idea (was /discover refine), and graduate a ready idea into the backlog with a Definition-of-Ready gate (was /promote). Nothing reaches the backlog without the DoR gate."
user_invocable: true
---

# /idea — Structured Idea Capture & Promotion

**Announce:** Using /idea to [capture / refine / promote] …

Discovery is the staging area: ideas live in `docs/project/ideas/D###-<slug>.md`
until they pass the DoR gate; only then do they become rows in
`docs/project/backlog.md`. `/work` is where backlog items become sprint tasks.
ID rules: [`../../../docs/project/NAMING.md`](../../../docs/project/NAMING.md).

## Token budget

- Never full-Read `backlog.md` or board files — use `Grep` for duplicate scans.
- Read an existing idea detail file only when refining or promoting that D###.
- Keep the interview lean — short, targeted questions per stage; no exhaustive
  checklists. Read only the target idea file in full at promote time.

## Modes

### `/idea <text>` — Capture a raw idea

1. **Stage 1 — Core:** title, problem statement, affected user roles, source,
   affected components / services.
2. **Estimate complexity** — trivial/small → 3-4 follow-ups; medium → 5-8;
   large → 8-10. Don't over-ask small items.
3. **Stage 2 — Scope:** target behaviour, explicit non-goals, related features,
   cross-component impact (events, persistence, UI entry points).
4. **Stage 3 — Context:** urgency, technical constraints, deadlines, related ideas.
5. **Allocate the next D### ID** — `Grep docs/project/ideas/` for the highest
   existing D### and increment. Sequential, never reused.
6. **Duplicate scan** — `Grep docs/project/ideas/` + `docs/project/backlog.md`
   for title keywords. Surface any match and ask whether to merge before creating.
7. **Create the detail file** `docs/project/ideas/D###-<slug>.md` with: User
   Stories, Acceptance Criteria (≥3 aimed at), Affected Components, Cross-cutting
   Concerns (multi-tenancy / RBAC / observability as applicable), Open Questions.
   State = `raw`.
8. **Confirm** — print the D### assigned and the file path.

> Ideas can be `dropped` (state change in the file header) but the file is never
> deleted — keep the trail.

### `/idea refine D###` — Fill gaps on an existing idea

1. Read `docs/project/ideas/D###-<slug>.md` in full.
2. Identify which DoR fields are missing or thin (see the gate below).
3. Ask targeted questions — only for the gaps; don't re-interview done fields.
4. Update the file; advance state to `refined` when all required fields exist.
5. Confirm updated fields + new state.

### `/idea promote D###` — Graduate to backlog

1. Read the idea detail file in full.
2. **Validate state** — must not already be `promoted` or `dropped`.
3. **Definition-of-Ready gate** — all must pass before continuing:

   | Field | Required |
   |---|---|
   | Problem statement | yes |
   | ≥1 user story | yes |
   | ≥3 acceptance criteria | yes |
   | Dependencies declared | yes |
   | No open blocking questions | yes |
   | Complexity estimate | yes |
   | Affected components / services listed | yes |
   | Cross-cutting concerns noted | yes |
   | No duplicate in backlog | yes |

   Any field fails → report exactly what's missing, set state `needs-refinement`,
   and stop. Do **not** promote a half-baked item.

4. **Duplicate scan** — `Grep docs/project/backlog.md` for similar titles /
   problem keywords; prefer linking over a duplicate row.
5. **Gather metadata** — `Priority` (P0-P3), `Size` (S/M/L/XL), target sprint
   (optional).
6. **Allocate the next B###** — `Grep docs/project/backlog.md` for the highest
   B### and increment.
7. **Append the enriched entry** to `docs/project/backlog.md` `## Active` with
   Status `open` (or `wip S##` if a sprint was named — one token, never a
   narrative): user story + AC + affected components + discovery ref (`see D###`)
   + Priority · Size · Source = idea.
8. **Update the idea detail file** — set State = `promoted (B###)` in the header.
   Commit backlog + idea-file edits atomically.
9. **Confirm** — print the new B### and, if set, the target sprint.

## Rules

- **Never modify `docs/project/backlog.md` from capture or refine** — that is
  promote's job alone.
- `/work` is where backlog items become sprint tasks — not `/idea`.
- Backlog row format + DoR detail:
  [`../../../docs/project/backlog.md`](../../../docs/project/backlog.md) and
  [`../../../docs/designs/_templates/BACKLOG_ENTRY_TEMPLATE.md`](../../../docs/designs/_templates/BACKLOG_ENTRY_TEMPLATE.md).
- State lifecycle: `raw` → `refined` → `promoted` | `dropped`.

## See also

- [`../work/SKILL.md`](../work/SKILL.md) — picks a backlog item into a sprint and drives it
- [`../../../docs/project/NAMING.md`](../../../docs/project/NAMING.md) — D### / B### / F#### formats
