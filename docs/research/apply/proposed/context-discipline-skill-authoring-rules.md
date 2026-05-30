---
synthesis_source: ../../synthesis/claude-code-core/context-discipline-as-design-constraint.md
track: claude-code-core
target: CONTRIBUTING.md, CLAUDE.md, docs/research/METHODOLOGY.md
type: doc-update
status: proposed
pr: n/a
date: 2026-05-30
---

## What changes
Two small, process-level additions backed by Anthropic primary sources:

1. **`CONTRIBUTING.md` → "Improving a skill":** add two authoring rules —
   - *Split-when-unwieldy* (progressive disclosure): move rarely-co-used
     content out of `SKILL.md` into referenced files.
   - *Execute-vs-read intent*: each shipped script states whether Claude
     runs it or reads it as reference.
2. **`CLAUDE.md` skill-header rule (#4):** one clause pointing to the
   "smallest set of high-signal tokens" principle as the rationale behind
   the mandatory `## Token budget` section.

(Optional, low priority: a "context-bloat" check item in the review gate.)

## Why
See [synthesis](../../synthesis/claude-code-core/context-discipline-as-design-constraint.md).
Both Anthropic sources converge on context as the scarce resource; these two
rules are the specific, currently-implicit pieces of their guidance worth
making explicit. Quality gate: gives reviewers a citable standard.

## Migration / install impact
- **None to the installer.** `CONTRIBUTING.md` and root `CLAUDE.md` are not
  shipped (`CLAUDE.md` here is the maintainer manual; the installer renders
  `core/CLAUDE.md.tmpl` instead). If any clause should reach installed
  projects, it must be added to `core/CLAUDE.md.tmpl` separately — decide
  per-clause.
- Backward-compatible; docs-only.

## Validation
- Re-read `CONTRIBUTING.md` "Improving a skill" — the two rules are present and concise.
- `grep -n "Token budget" CLAUDE.md` shows the rationale clause added.
- No `core/` change required, so installer verification (`install.sh` dry-run
  + stray-placeholder grep) is unaffected — confirm it still passes.

## Checklist
- [ ] Respects `core/` de-domain-specification rule (N/A — touches root docs, not core/)
- [ ] Skill rule edits keep `## Token budget` requirement intact
- [ ] Installer verification passed (unchanged)
- [ ] PR opened
- [ ] Moved to `shipped/` + INDEX scoreboard updated
