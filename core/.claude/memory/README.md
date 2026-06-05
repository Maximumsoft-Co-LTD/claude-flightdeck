# In-repo Brain (fallback)

This folder is the **in-repo Brain** — used when `BRAIN_PATH` is empty
(the installer left this folder in place). If you set `BRAIN_PATH` to
an external Obsidian vault, deep lessons live there instead and this
folder can stay as just this README.

## What goes here

Long-form versions of the lessons that brain-hot.md only summarizes.

```
memory/
├── MEMORY.md          # index — one line per lesson, ≤ 200 lines total
├── lessons/
│   ├── L001-<slug>.md
│   ├── L002-<slug>.md
│   └── …
├── patterns/
│   ├── P001-<slug>.md
│   └── …
└── retros/
    └── sprint-S<N>-summary.md   # only the *learnings*, not the task log
```

`brain-hot.md` cites these by ID. Adding a new lesson:

1. Pick the next L### number (look at MEMORY.md tail).
2. Write `lessons/L###-<short-slug>.md` with:
   - One-sentence headline
   - Concrete failure / surprise that motivated it
   - The rule (1-3 bullets)
   - How to apply (when does it fire?)
3. Append a line to `MEMORY.md`.
4. If it's "always-apply", also cite it from `../rules/brain-hot.md`.

## What does NOT go here

- Project specs (those live in `docs/`)
- Per-task work logs (those live in `docs/project/sprints/`)
- Per-task retros (those live in `docs/project/sprints/S<N>/tasks.md`)
- Agent-specific feedback (that lives in `../agent-memory/<agent>/`)

## External Brain alternative

If you want this shared across many projects, set `BRAIN_PATH` (e.g. to
an Obsidian iCloud vault) on install and put the structure above there
instead. The advantage: lessons accumulate across projects. The
disadvantage: not in version control, not visible in code review.
