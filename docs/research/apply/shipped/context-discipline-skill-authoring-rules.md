---
synthesis_source: ../../synthesis/claude-code-core/context-discipline-as-design-constraint.md
track: claude-code-core
target: core/docs/setup/skill-authoring.md, core/docs/INDEX.md, CONTRIBUTING.md, CLAUDE.md
type: new-file (core) + doc-update
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-05-31
---

## What changes
Shipped as scope **(b)** — pushed into `core/` so installed projects' skill
authors benefit, not just maintainers.

1. **NEW `core/docs/setup/skill-authoring.md`** (ships to every project) —
   canonical skill-authoring discipline: required header (`name` /
   `description` / `## Token budget`), CSO trigger-based descriptions,
   **split-when-unwieldy** (progressive disclosure → `references/`),
   **execute-vs-read** script intent, and the "smallest set of high-signal
   tokens" rationale (context as a finite, degrading resource).
2. **`core/docs/INDEX.md`** — added `skill-authoring` to the Setup-docs table
   (and backfilled `agent-config-security` from the prior change).
3. **`CONTRIBUTING.md` "Improving a skill"** — added the split-when-unwieldy +
   execute-vs-read rules tersely, linking the canonical core doc (no drift).
4. **`CLAUDE.md` rule 4** — added the rationale clause behind `## Token
   budget` + pointer to the core doc.

## Why
See synthesis. Two Anthropic primary sources converge on context as the
scarce resource; these rules were applied implicitly but never written down.
Making them explicit gives reviewers a citable standard — and shipping them
in `core/` means project skill authors get the standard too.

## Migration / install impact
- `core/docs/setup/skill-authoring.md` ships on fresh install + via
  `install.sh upgrade` (template_owned). No placeholder / `sed` change.
- `CONTRIBUTING.md` + maintainer `CLAUDE.md` are not shipped (maintainer
  surface) — edited directly.
- Backward-compatible; additive.

## Validation
- `install.sh` (real install) exit 0; `docs/setup/skill-authoring.md` ships;
  0 stray placeholders; de-domain grep clean; both INDEX links resolve to
  real shipped files.

## Checklist
- [x] Respects `core/` de-domain-specification rule (verified: idip/agg grep empty)
- [x] Skill rule edits keep `## Token budget` requirement intact
- [x] Installer verification passed (new doc ships; links resolve)
- [x] Moved to `shipped/` + INDEX scoreboard updated + CHANGELOG entry

## Verification evidence (2026-05-31)
```
install exit=0
docs/setup/skill-authoring.md → shipped; 0 placeholders; de-domain clean
docs/setup/agent-config-security.md → still ships
INDEX rows skill-authoring + agent-config-security → both resolve to real files
```
