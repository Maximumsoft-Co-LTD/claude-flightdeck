---
synthesis_source: synthesis/claude-code-core/coding-conduct-front-door.md
target: core/.claude/rules/coding-conduct.md + core/CLAUDE.md.tmpl + onboard draft-templates + pre-task ritual + brain-hot
status: shipped
pr: local (branch feat/coding-conduct-rules; upgrade-eligible)
---

## What changes

Adopt a Karpathy-style **behavioral-guidelines** layer as a front door to our rigor,
present in the orchestrator AND every service / area repo it controls:

- **New** `core/.claude/rules/coding-conduct.md` — the four guidelines (Think Before
  Coding · Simplicity First · Surgical Changes · Goal-Driven Execution) in the
  source's format, de-domain-specified, cross-linked to the A-rules they map onto, and
  reconciled with `programming-fundamentals.md` (real errors still handled deliberately).
- **`core/CLAUDE.md.tmpl`** — compact "Behavioral guidelines (every agent, every repo)"
  section (4 one-liners + pointer), kept under the 200-line budget.
- **`core/.claude/skills/onboard/references/draft-templates.md`** — per-area `CLAUDE.md`
  now carries a fixed `## Coding conduct` pointer (the 5-section shape → 6), so every
  generated service repo restates the four + where the canonical text lives.
- **`core/.claude/rules/agent-pre-task-ritual.md`** Step 2 + **`brain-hot.md.tmpl`**
  "Where to look next" — every dispatched agent reads `coding-conduct.md`.

## Why (link to synthesis)

[`synthesis/claude-code-core/coding-conduct-front-door.md`](../../synthesis/claude-code-core/coding-conduct-front-door.md)
— names the *posture* gap (the A-rules enforce; nothing stated the habit *before* the
rigor) and gives the multi-repo orchestrator + its service repos one consistent set.

## Migration / install impact

- New installs get the rule + the CLAUDE.md section + the per-area pointer directly.
- Existing installs: `coding-conduct.md` is a new template-owned rule file (arrives on
  upgrade); the root `CLAUDE.md` section is `seed_then_user_extends` (flagged NEEDS
  MERGE, never auto-overwritten) — hand-merge the new section.

## Validation

- `bash scripts/validate-skills.sh` green (0 warn / 0 fail).
- `./install.sh <tmp> --force` renders `coding-conduct.md` + the CLAUDE.md section with
  0 leftover placeholders; the per-area pointer is present in `draft-templates.md`.
- `core/CLAUDE.md.tmpl` stays ≤ 200 lines.

## Deferred

- Optionally surface the four guidelines on the generated site (index/workflow content
  parts) — not required (changelog + rule file already ship).
