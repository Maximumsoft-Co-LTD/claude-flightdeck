---
name: discover
description: "Capture feature ideas with structured questioning into a discovery staging area before they reach the backlog. Use when the user says 'capture idea', '/discover', '/discover refine D###', or wants to record a new request without committing to it yet. Sister skill: /promote (graduates the item into the backlog)."
user_invocable: true
---

# /discover — Structured Requirement Capture

Capture raw ideas into `docs/project/ideas.md` (index) + `docs/project/ideas/D<###>-<slug>.md` (detail file). Discovery is the staging area — nothing reaches the backlog without `/promote`.

## Token budget (MANDATORY)

- Never full-Read the backlog or sprint files — use Grep for the duplicate scan.
- Read existing discovery detail files only when refining a specific D###.
- Keep the interactive interview lean — short, targeted questions; don't dump exhaustive checklists on the user.

## Usage

- `/discover` — interactive 3-stage interview
- `/discover <title>` — quick raw capture (skip the interview)
- `/discover refine D###` — fill gaps on an existing item
- `/discover review D###` — readiness check (the same gate `/promote` will run)
- `/discover show D###` / `/discover list` / `/discover drop D###`

## Interactive steps

1. **Stage 1 — Core**: title, problem statement, affected user roles, source of the request, affected components / services.
2. **Estimate complexity** — trivial/small → 3-4 follow-ups; medium → 5-8; large → 8-10. Don't over-ask small items.
3. **Stage 2 — Scope**: target behaviour, explicit non-goals, related features, cross-component impact (events, persistence, UI entry points). Ask which areas of the system will need to change.
4. **Stage 3 — Context**: urgency, technical constraints, deadlines, related discovery items.
5. **Allocate next D### ID** — `Grep` `docs/project/ideas.md` for the highest ID and increment.
6. **Create the detail file** `docs/project/ideas/D<###>-<slug>.md` with: User Stories, Acceptance Criteria, Affected Components, Cross-cutting Concerns (multi-tenancy / RBAC / observability if applicable to {{PROJECT_NAME}}), Open Questions.
7. **Update the discovery index** `docs/project/ideas.md` — append a new row: `D###`, title, state = `raw` or `refined`, owner.
8. **Auto-scan for duplicates** — `Grep` `docs/project/ideas.md` + `docs/project/backlog.md` for title keywords. If a similar item exists, surface it and ask whether to merge.

## Definition of Ready (used by `/discover review` and by `/promote`)

**Required:** problem statement, ≥1 user story, ≥3 AC, dependencies declared, no open blocking questions, complexity estimate, no duplicate, affected components, cross-cutting concerns addressed.

**Recommended:** happy path described, error cases enumerated, UX notes, contract/event implications, technical constraints.

## Rules

- **Never modify `docs/project/backlog.md`** — that is `/promote`'s job.
- Sequential D### IDs, never reused.
- Auto-scan for duplicates on every new capture.
- Discovery items can be `dropped` (state change) but the file is never deleted — keep the trail.
