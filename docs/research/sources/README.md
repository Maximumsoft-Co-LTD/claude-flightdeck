# sources/ 🟡 Process

One file per source. A `source` note is a **distilled** read — not a copy,
not a bookmark. If you can't say what it claims and whether it's true,
you haven't processed it yet.

## Creating a note

1. Copy [`_template.md`](_template.md) to `YYYY-MM-DD-<slug>.md`
   (date you process it; slug = short kebab title).
   e.g. `2026-05-30-anthropic-agent-skills-docs.md`
2. Fill the frontmatter — especially `quality` (see [METHODOLOGY](../METHODOLOGY.md#source-quality-score-15)) and `topics`.
3. Write the TL;DR in your own words. If you can't, read again.
4. Note **relevance to our template** — even "none" is a valid finding.

## Naming

`YYYY-MM-DD-<slug>.md` — date-prefixed so the folder sorts chronologically
and slugs stay collision-free. Don't nest by topic here; the `topics:`
frontmatter tag is how cross-cutting reads get found at synthesis time.

## When you have ≥3 on one topic

That's [Gate 2](../METHODOLOGY.md#gate-2--process--synthesize-sources--synthesis).
Move up to [`synthesis/`](../synthesis/README.md) and write the pattern.
A single quality-5 primary source can also clear the gate alone.

## Quality bar

Don't create a note for quality-1 noise — archive it in the inbox instead.
A `sources/` note is a small commitment: it says "this was worth my close
attention." Keep that signal clean.
