---
name: index-refresh
description: "Refresh the slim INDEX files (sprint index, design INDEX, backlog index, sprints INDEX) from their wide source files. Use when the user says '/index-refresh', or after any skill mutates sprint / backlog / design-doc files (next-task done, retro close, promote, archive, new design doc). Canonical spec: docs/setup/index-discipline.md."
user_invocable: true
---

# /index-refresh — Index Discipline Companion

Keep the four slim index files in sync with their wide source files. Every skill that mutates the source file is responsible for calling this in the same commit.

## Token budget (MANDATORY)

- **Never full-Read a wide source file to rebuild the index.** Use Grep with targeted regex to pull the minimal data per row.
- **Each Grep call < 2k tokens.** Total skill invocation budget: ≤6k tokens.
- Full `Read` is only permitted on the index files themselves (they are small by contract).

## What to refresh

| # | Index file | Source file | Grep pattern | Fields |
|---|---|---|---|---|
| 1 | `docs/project/sprints/sprint-S<N>-index.md` | `docs/project/sprints/sprint-S<N>.md` | `^\| TG\|^\| S` (task rows) | `ID`, `Component`, `Status`, `Depends` |
| 2 | `docs/designs/sprint-S<N>/INDEX.md` | `docs/designs/sprint-S<N>/D*.md` | `^#\s+Design:\|^> \*\*Status\*\*\|^> \*\*Task Group\*\*` | `DXXX`, `Title`, `Status`, `TG#` |
| 3 | `docs/project/backlog-index.md` | `docs/project/backlog.md` | `^### Sprint \|^## 🚀` | `Sprint`, `Status`, `Pointer` |
| 4 | `docs/project/sprints/INDEX.md` | `docs/project/sprints/sprint-*.md` | `^> \*\*Status\*\*\|^# Sprint` | `Sprint`, `Status`, `Opened`, `Closed` |

## Staleness detection

A consumer skill does:

```bash
stat -f '%m' docs/project/sprints/sprint-S<N>-index.md docs/project/sprints/sprint-S<N>.md
```

If `mtime(index) < mtime(source)`:
- Warn: `"[warn] sprint-index stale — run /index-refresh"`
- Fall through to Grep the source (no silent drift)

## Steps

1. **Detect stale indexes** — compare mtimes across all 4 pairs.
2. **Confirm scope with user** — if standalone, ask which to refresh (default: all stale). If called from another skill, refresh only the index for the parent's source.
3. **Run the rebuild script**: `.claude/skills/index-refresh/scripts/refresh_indexes.sh`. Inspect the output; if any rebuild reports `0 rows` (or emits a `WARN`), surface it to the user as a likely bug — the source file's shape may have drifted away from the patterns the script parses.
4. **Verify** — re-check mtimes; confirm each index file ends with the auto-generated footer comment.
5. **Commit** — if standalone: `docs(index): refresh slim indexes`. If called from another skill: bundle into the parent commit.

## What the script does

Rebuilds the four index pairs idempotently:

- `docs/project/sprints/INDEX.md` — list of every `sprint-S*.md` with status/opened/closed
- `docs/project/sprints/sprint-S<N>-index.md` — per active sprint, the task row → ID/Component/Status/Depends extracted from the wide sprint file
- `docs/project/backlog-index.md` — every `### Sprint S<N>` section in `backlog.md` with status + anchor link
- `docs/designs/sprint-S<N>/INDEX.md` — per sprint design dir, every `D<NNN>-*.md` with title/status/task

Standard tools only (`grep`, `sed`, `awk`, `find`, `sort`). No external deps. Running twice in a row produces identical output (idempotency-verified).

## When other skills invoke index-refresh logic

| Skill | Trigger | Indexes |
|---|---|---|
| `/next-task` | Task closed | `sprint-S<N>-index.md` |
| `/retro` | Sprint close | `sprint-S<N>-index.md` + `backlog-index.md` + `sprints/INDEX.md` |
| `/promote` | New backlog item | `backlog-index.md` |
| `/archive` | Moving old sprint | `sprints/INDEX.md` + `backlog-index.md` |
| `/document` | New design doc | `designs/sprint-S<N>/INDEX.md` |
| Manual sprint creation | New `sprint-S<N>.md` | All four |

## Rules

- **Never hand-edit an index's data table** — always regenerate from source (hand-edits desync the mtime chain).
- **Header + Summary sections ARE hand-curated** — preserve across refreshes.
- **Empty source → empty data table but keep the header.**
- **Missing source → warn + exit; do NOT delete the index.**

## Full canonical spec

`docs/setup/index-discipline.md`.
