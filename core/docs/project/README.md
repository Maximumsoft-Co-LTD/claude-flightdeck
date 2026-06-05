# {{PROJECT_NAME}} — Project State

> The single home for **what we're building and where it stands**. Everything
> the workflow reads or writes about backlog, sprints, design, and retros lives
> here. Naming conventions → [`NAMING.md`](./NAMING.md).

## The model (hybrid sprint-folder)

```
docs/project/
├── README.md            ← you are here
├── NAMING.md            ← id cheat-sheet (S<N> · D<NNN> · B### · F####)
├── backlog.md           ← cross-sprint: all work, ever + the Follow-ups registry
├── ideas/               ← pre-backlog staging (D###-slug.md, via /idea)
├── audit/               ← agent-dispatch JSONL (YYYY-MM.jsonl)
└── sprints/
    └── S<N>/                       ← one folder per sprint (created at runtime)
        ├── tasks.md                ← THE BOARD: glance + tasks + live mini-retros
        ├── designs/                ← per-task design docs, size-tiered, read on demand
        │   ├── D<NNN>-<slug>.md
        │   └── _briefs/<TASK_ID>-<role>.md   ← dispatch briefs
        └── retro.md                ← sprint-close retro (written by /retro)
```

**One board per sprint.** `sprints/S<N>/tasks.md` is the source of truth for that
sprint — the active-state glance, the task rows with `[ ]/[x]/[~]/[B]` state, and
the live mini-retros, all in one file. There is **no separate `STATUS.md`,
`STATUS-archive.md`, or `FOLLOWUPS.md`** — the active glance is the board header,
closed-sprint prose lives in that sprint's `retro.md`, and follow-ups are a
section of `backlog.md`.

## Where each thing lives (source of truth, per A008)

| Question | Look at |
|---|---|
| What sprint are we in / what's in flight? | the active `sprints/S<N>/tasks.md` **Glance** |
| What's the full backlog / is this tracked? | [`backlog.md`](./backlog.md) |
| What got deferred past a sprint? | [`backlog.md`](./backlog.md) `## Follow-ups` |
| A captured-but-not-committed idea? | [`ideas/`](./ideas/) |
| How was task X designed? | `sprints/S<N>/designs/D<NNN>-<slug>.md` |
| How did sprint X close? | `sprints/S<N>/retro.md` |

## Scaffolding a sprint

Copy the templates into a new sprint folder:

```bash
mkdir -p docs/project/sprints/S<N>/designs/_briefs
cp docs/project/_templates/tasks.md docs/project/sprints/S<N>/tasks.md
cp docs/project/_templates/retro.md docs/project/sprints/S<N>/retro.md   # filled at close by /retro
```

(`/work` does this for you when it opens a sprint.)

## See also

- [`_templates/`](./_templates/) — board + retro scaffolds (rendered at install)
- [`../designs/_templates/`](../designs/_templates/) — design-doc templates (size-tiered)
- [`../INDEX.md`](../INDEX.md) — the master map of the whole control plane
