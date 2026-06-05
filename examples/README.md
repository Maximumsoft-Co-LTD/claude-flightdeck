# AI-Workflows — Examples

This folder holds **filled-in** examples of the AI-Workflows control plane in
actual use on a fictional project. The blank `.tmpl` files under
[`../core/docs/project/`](../core/docs/project/) tell you *what shape* a control-plane
file takes; these examples show *what it looks like* once a team has been
running with the template for a few weeks.

## What's here

| Folder | Stack | What it demonstrates |
|---|---|---|
| [`url-shortener-go-hex/`](./url-shortener-go-hex/) | Go hexagonal backend + Postgres + Redis | Full S01 → S03 progression. Closed sprints, an in-flight sprint mid-week 5, design docs across XS/S/M/L tiers, retros with a real lesson promotion, FOLLOWUPS with both open and closed rows. |

Each example is a `docs/` tree only — no source code, no `.claude/` install.
The point is to see the **artifacts** (STATUS, sprints, retros, designs,
FOLLOWUPS) in coherent, cross-linked form, not to run anything.

## Why filled-in examples beat blank templates

A blank template shows you the headings. It does not show you:

- How long a real retro is (~100 lines, not 30, not 500)
- What level of detail belongs in a design doc step at L vs S tier
- How to write a STATUS row that survives a sprint close
- What a FOLLOWUP item looks like when it ages from `open` to
  `consumed-by:<task-id>`
- How a recurring lesson becomes a project-local A011 rule

The example below has all of those, sized to plausible reality. Read it the
way you'd read a real project: top-down from STATUS.

## How to read the example

Start at the top of the control plane and walk down:

1. **[`url-shortener-go-hex/README.md`](./url-shortener-go-hex/README.md)** —
   project overview (~120 lines). What the team is building, where they
   are in the calendar, what conventions they're holding.

2. **[`url-shortener-go-hex/docs/project/sprints/S<N>/tasks.md`](./url-shortener-go-hex/docs/project/sprints/S<N>/tasks.md)**
   — the single-pane glance. One row. Tells you the active sprint, in-flight
   task, current branch, latest movement.

3. **[`docs/project/sprints/S<N>/retro.md`](./url-shortener-go-hex/docs/project/sprints/S<N>/retro.md)**
   — closed-sprint narrative. Two entries: S01 (MVP) and S02
   (analytics + rate-limit). Each entry is the prose that was *moved out of*
   STATUS on sprint close.

4. **[`docs/project/sprints/S03/tasks.md`](./url-shortener-go-hex/docs/project/sprints/S03/tasks.md)**
   — the active sprint's task table. Five rows, one `[x] Done`, one
   `[~] In Progress`, three `[ ] Not Started`.

5. **[`docs/project/sprints/S03/designs/D006-admin-login-handler.md`](./url-shortener-go-hex/docs/project/sprints/S03/designs/D006-admin-login-handler.md)**
   — the L-tier design doc the in-flight task is following. Status: Draft.
   Phase 7 (security review) trigger pending.

6. **[`docs/project/sprints/S02/retro.md`](./url-shortener-go-hex/docs/project/sprints/S02/retro.md)**
   — the most recent closed retro. Includes a lesson promotion: a recurring
   observation about Redis fallback behaviour gets promoted into a new
   project-local A011 rule.

7. **[`docs/project/backlog.md`](./url-shortener-go-hex/docs/project/backlog.md)**
   — open carryover items (F0001 → F0005) plus closed ones consumed by
   tasks in S02.

8. Walk back up. Notice how each layer cites the next.

## Trying the template on your own project

When you want to start a new project from this template:

```bash
./install.sh ~/your-project --preset go-hex
```

Run that from the repo root. The installer drops `.claude/`, `docs/project/`,
`docs/designs/`, the agent files, and the preset-specific rules into your
target directory. After install, your `docs/project/sprints/S<N>/tasks.md` will look like
the blank `.tmpl` — your job over the next sprint is to fill it in until
it looks like the example below.

## See also

- [`../README.md`](../README.md) — the template's main README
- [`../docs/control-plane-architecture.md`](../docs/control-plane-architecture.md) — how STATUS, sprints, designs, retros, and FOLLOWUPS fit together
- [`../docs/how-to-customize.md`](../docs/how-to-customize.md) — adapting the example's conventions to your own stack
