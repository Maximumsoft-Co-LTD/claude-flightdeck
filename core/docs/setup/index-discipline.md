# Index Discipline — token-friendly file creation workflow

> Rule **L154** — auto-loaded via CLAUDE.md.
> Purpose: every large living document (sprint, backlog, design-doc collection) has a sibling slim INDEX file. Skills that read these files should prefer the index; skills that mutate them must refresh the index same-commit.

## Why

Large markdown tables with a wide notes column are the #1 per-invocation token sink. A 40-line slim index answers the same "what is the next task?" question in ~1 K tokens vs the full-file Read of ~4 K. It compounds across `/work`, `/status`, `/retro`, `/document`.

Typical measured savings:
- `/work`: ~5 K → ~1.5 K
- `/status`: ~14 K → ~4 K
- `/retro`: ~18 K → ~6 K

## The four index files

| Index | Companion to | Shape | Max size | Consumer |
|---|---|---|---|---|
| `docs/project/sprints/XX/tasks.md` | `sprint-XX.md` | 4-col: ID \| Component \| Status \| Depends | ~60 lines | `/work` Step 1, `/status`, `/retro` |
| `docs/project/sprints/XX/designs/INDEX.md` | the dir of `DXXX-*.md` | 4-col: DXXX \| Title \| Status \| Task-ID | ~30 lines | `/work` Step 7, `/document` |
| `docs/project/backlog-index.md` | `backlog.md` | 3-col: Sprint \| Status \| Pointer | ~40 lines | `/work` Step 1 (sprint resolver), `/idea promote`, `/retro archive` |
| `docs/project/sprints/INDEX.md` | the dir of `sprint-*.md` | 3-col: Sprint \| Status \| Dates | ~30 lines | `/retro archive`, humans orienting |

## Creation workflow (MANDATORY)

### Creating a new sprint

1. `docs/project/sprints/XX/tasks.md` — full file
2. `docs/project/sprints/XX/tasks.md` — **sibling, same commit**
3. Append one row to `docs/project/sprints/INDEX.md`
4. Update `docs/project/backlog-index.md`

### Creating a new design-doc directory

1. `docs/project/sprints/XX/designs/DXXX-name.md` — full file
2. First design doc in a new dir: create `docs/project/sprints/XX/designs/INDEX.md`
3. Every subsequent design doc: **append one row** to INDEX.md same commit

### Mutating any of these files

| You change | You MUST also update | Same commit? |
|---|---|---|
| `sprint-XX.md` task-row status | `sprint-XX-index.md` row | Yes |
| Add a new `DXXX-*.md` | `docs/project/sprints/XX/designs/INDEX.md` row | Yes |
| Close a sprint in `backlog.md` | `backlog-index.md` + `docs/project/sprints/INDEX.md` | Yes |

## Staleness detection

```bash
stat -f '%m' sprint-XX-index.md sprint-XX.md
# index mtime < full-file mtime → warn + read full file (indexes are derived from the board/backlog — no manual refresh needed)
```

## Index refresh

Indexes are derived from the board/backlog — no manual refresh command is needed. Skills that mutate sprint/backlog files must update the sibling index in the same commit.

## Related rules

- **L087** backlog sync per-task
- **L153** token hygiene (`/clear` between skill invocations)
