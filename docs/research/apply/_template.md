---
synthesis_source: ../../synthesis/<track>/<slug>.md
track: claude-code-core
target: core/... | presets/...        # the file(s) this change touches
type: new-skill | new-agent | rule-update | doc-update | preset
status: proposed | in-progress | shipped
pr: n/a                                # url once opened
date: YYYY-MM-DD
---

## What changes
<concrete description — which files, what edits, what gets added/removed>

## Why
<link to the synthesis and the one-line reason this improves the template>

## Migration / install impact
<does it change what the installer ships? new placeholder? preset-only?
backward-compatible? — see repo CLAUDE.md placeholder & core/preset rules>

## Validation
<how we'll know it works — e.g. run install.sh into /tmp, grep for stray
placeholders, run scripts/validate-skills.sh, exercise the new skill/agent>

## Checklist
- [ ] Respects `core/` de-domain-specification rule (if touching core/)
- [ ] Skill has `## Token budget` / agent references pre-task ritual (if applicable)
- [ ] Installer verification passed
- [ ] PR opened
- [ ] Moved to `shipped/` + INDEX scoreboard updated
