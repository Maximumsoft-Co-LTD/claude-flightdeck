---
name: archive
description: "Move old sprint files, design docs, and retros into the archive subtree — keeps only the latest 3 sprints active. Use when the user asks '/archive', 'archive sprint-XX', 'clean up old sprints', or after a long-running project accumulates too many stale sprint files."
user_invocable: true
---

# /archive — Move Old Sprints to `historical/`

Keep `docs/project/sprints/`, `docs/designs/`, and `docs/project/retros/` lean by moving anything older than the 3 most-recent sprints into a `historical/` (or `_archive/`) subfolder. Uses `git mv` — nothing is deleted.

## Token budget (MANDATORY)

- Only `Glob` + `Grep` on sprint / design / retro filenames — never full-Read sprint contents.
- Preview before moving. Confirm with user.

## Usage

- `/archive` — preview + confirm (default behaviour)
- `/archive sprint-S<N>` — archive one specific sprint
- `/archive list` — show what is currently archived
- `/archive restore sprint-S<N>` — restore a previously archived sprint

## Steps

1. **Scan** — `Glob` `docs/project/sprints/sprint-*.md`, `docs/designs/sprint-*/`, `docs/project/retros/sprint-*.md`.
2. **Sort by sprint number** (parse `S<N>` from the path).
3. **Keep the latest 3 sprints active.** Everything older is a candidate for archive.
4. **Show the preview**: list every file that will move + its destination path. Ask the user to confirm.
5. **Execute `git mv`** for each candidate → `docs/project/sprints/historical/`, `docs/designs/historical/sprint-S<N>/`, `docs/project/retros/historical/`.
6. **Update the historical INDEX** — `docs/project/sprints/historical/INDEX.md` gets a new row per archived sprint with title + date archived.
7. **Refresh slim indexes** via `/index-refresh` so `docs/project/sprints/INDEX.md` and `docs/project/backlog-index.md` reflect the move.
8. **Commit** — `docs(archive): move sprints older than the active window to historical/`.

## Restore flow

`/archive restore sprint-S<N>` reverses the moves and refreshes the indexes.

## Rules

- **Never delete files** — always `git mv` so history is preserved.
- **Always confirm** with the user before moving anything.
- **Templates are never archived** — `docs/designs/_templates/` stays put.
- The latest 3 sprints stay active, regardless of completion status (a long open sprint isn't archived just because it's old).
