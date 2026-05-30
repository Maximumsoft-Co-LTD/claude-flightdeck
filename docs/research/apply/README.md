# apply/ 🟣 Apply

The payoff. This is where research turns into actual edits to the template.
If nothing reaches `apply/`, the workspace is a reading club, not a
feedback loop.

```
apply/
├── proposed/   candidate changes — written, not yet merged
└── shipped/    merged changes — the scoreboard
```

## proposed/

A synthesis that cleared [Gate 3](../METHODOLOGY.md#gate-3--synthesize--apply-synthesis--proposed-change)
(named a concrete file, passes friction-or-quality) becomes a
`proposed/<slug>.md` from [`_template.md`](_template.md). This is the spec
for the change — enough that someone could open the PR from it.

Treat each proposed change like a normal template edit: it must respect the
rules in the repo [`CLAUDE.md`](../../../CLAUDE.md) — e.g. **de-domain-specify
anything in `core/`**, keep opinions in `presets/`, skills need a
`## Token budget`, agents must reference the pre-task ritual.

## shipped/

When the PR merges, move the note to `shipped/` and fill in the `pr:` link.
Then add a row to the scoreboard in [`INDEX.md`](../INDEX.md#shipped-changes-the-scoreboard).
This closes the loop: link in → change shipped.

## What good looks like

A steady trickle of small, well-justified changes — a new rule here, a
sharpened skill description there, a new preset when a pattern proves out —
each traceable back to the sources that motivated it.
