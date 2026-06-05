---
synthesis_source: synthesis/claude-code-core/lean-workflow-redesign.md
target: core/ + install.sh + install.ps1 + core/.flightdeck-upgrade.json
status: shipped
pr: local `main` (branch refactor/lean-workflow-6-verbs; upgrade-eligible)
---

## What changes

Consolidated the control plane: **22 skills → 6 verbs + 4 niche**, a **hybrid
sprint-folder state model** under `docs/project/` (renamed from `docs/spec/`),
reference-on-demand detail (playbooks + size-tiered templates + per-folder
READMEs + `NAMING.md`), and `/doctor` removed.

Shipped in 6 validator-green commits:

- **C1** remove `doctor.sh` + refs.
- **C2** rename `docs/spec/` → `docs/project/` (+ `discovery/` → `ideas/`); all
  ~69 inbound references rewritten in lock-step.
- **C3** collapse 5 state files → `sprints/S<N>/{tasks.md, retro.md}` + `backlog.md`
  (`## Follow-ups`); new `_templates/` + `README.md` + `NAMING.md`.
- **C4** merge 22 skills → 6 verbs + 4 niche (drafting fanned out to 5 read-only
  subagents; all writes serial); `/tdd` + 6-gate → playbooks.
- **C5** sweep old command names → new verbs; rebuild INDEX cheat-sheet (→10).
- **C6** install.sh / install.ps1 next-steps + backup path; upgrade classifier
  (`docs/project/**` added, legacy `docs/spec/**` retained); this research loop.

## Why (link to synthesis)

[`synthesis/claude-code-core/lean-workflow-redesign.md`](../../synthesis/claude-code-core/lean-workflow-redesign.md)
— fewer commands to learn + a cleaner, self-documenting state folder, with
design-first + the 6-gate rigor intact; grounded in spec-kit/Kiro command-surface
research and Anthropic/Cognition/MAST fan-out research.

## Migration / install impact

- New installs get the lean layout directly.
- Existing installs: the upgrade classifier RETAINS the legacy `docs/spec/**`
  `user_owned` globs, so a pre-rename project's content is never clobbered. A
  one-shot `docs/spec → docs/project` migration helper is a deferred follow-up.

## Validation

- `bash scripts/validate-skills.sh` green at every commit.
- `./install.sh <tmp> --force` renders clean (0 leftover placeholders) with the
  10-skill layout; `jq` confirms the upgrade classifier is valid JSON.
- Residual old-command / `docs/spec` greps over `core/` are clean (modulo
  intentional history in CHANGELOG + the `(was /x)` notes in the new verb files).

## Deferred

- Split `/onboard` (337L, over the 250-line budget); reconsider folding
  `/flightdeck-feedback`. Re-add slim-index auto-refresh if needed. A
  `docs/spec → docs/project` migration helper for existing installs.
