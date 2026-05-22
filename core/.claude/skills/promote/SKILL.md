---
name: promote
description: "Promote a discovery item into the product backlog with a Definition-of-Ready gate and an enriched entry. Use when the user says 'promote D###', '/promote', or wants to graduate a discovery item into the sprint backlog. Sister skill: /discover (which captures the item in the first place)."
user_invocable: true
---

# /promote — Readiness-Gated Promotion to Backlog

Move a discovery item from `docs/spec/discovery/D###-*.md` into `docs/spec/backlog.md` as an enriched, sprint-ready row. The Definition-of-Ready gate is non-negotiable: incomplete items stay in discovery.

## Token budget (MANDATORY)

- Read only the target discovery detail file in full; use Grep for everything else.
- `Grep` `docs/spec/backlog.md` for duplicates (do not full-Read it).
- `Grep` the discovery index for the row's current state; do not full-Read.

## Usage

- `/promote D###` — promote a specific discovery item
- `/promote` — list refined items, let the user pick

## Steps

1. **Read** the discovery detail file `docs/spec/discovery/D<###>-<slug>.md` (full read — small file).
2. **Validate state** — item must not already be `promoted` or `dropped`.
3. **Definition of Ready gate** — every required field must pass:
   - Problem statement present
   - ≥1 user story
   - ≥3 acceptance criteria
   - Dependencies declared
   - No open blocking questions
   - Complexity estimate
   - Affected components / services listed
   - Cross-cutting concerns noted (multi-tenant, RBAC, observability, etc., as applicable to {{PROJECT_NAME}})
4. **Duplicate scan** — `Grep` `docs/spec/backlog.md` for similar titles / problem keywords. If a dup exists, prefer linking the discovery item to it instead of promoting.
5. **Gather metadata** with the user: `Priority`, `Complexity`, `Target Sprint`.
6. **Allocate the next backlog ID** — `Grep` `docs/spec/backlog.md` for the highest `B###` and increment.
7. **Append the enriched entry** to `docs/spec/backlog.md`:
   - User story + AC + affected components + discovery ref (`see D###`)
   - Priority · Complexity · Target Sprint · Source = discovery
8. **Update the discovery index** `docs/spec/discovery.md` — set State = `promoted`, append `→ B###`.
9. **Update the discovery detail file** — set State = `promoted (B###)` in the header.
10. **Refresh the slim index** — `/index-refresh` for `docs/spec/backlog-index.md`.
11. **Confirm to the user** — print the new B### and target sprint.

## Rules

- Always run the DoR gate; never promote a half-baked item.
- Update **all three** files (backlog, discovery index, detail) atomically in a single commit.
- The enriched entry must include: user story, AC, affected components, discovery ref.
- Never edit `docs/spec/backlog.md` from `/discover` — that is `/promote`'s job alone.
