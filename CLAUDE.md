# CLAUDE.md — AI-Workflows (template repo)

> This file is for Claude Code instances editing the **template itself**.
> It is NOT shipped to installed projects — the installer renders
> `core/CLAUDE.md.tmpl` into the target instead. Treat that as the
> "user-facing" CLAUDE.md and this one as the "maintainer" view.

## What this repo is

A portable control-plane template, copied into other projects by
`install.sh`. Two production codebases informed it (`idip-platform`,
`aggegator`). See `README.md` for user-facing usage.

## Layout

```
.
├── install.sh                # one-shot installer (placeholder render + preset merge)
├── template.config.example   # config var skeleton
├── core/                     # ALWAYS installed
├── presets/                  # opt-in via --preset
└── docs/                     # docs about THIS template (not what install ships)
```

Anything inside `core/` lands in every target. Anything inside
`presets/<name>/` lands only when `--preset <name>` is selected. Anything
inside `docs/` (top level here) stays in this repo.

## Rules for editing the template

1. **De-domain-specify everything in `core/`.** No mention of `idip-`,
   `agg-`, `IDIP-XXX`, `TG-AGG-S*`, specific PRD IDs, or tech-stack
   opinions. Opinions go in `presets/`. If you find yourself writing
   "Postgres" or "Vue" in `core/`, you're in the wrong folder.
2. **Use the placeholder convention.** Files needing project-specific
   values get the `.tmpl` suffix and use `{{PROJECT_NAME}}`,
   `{{PROJECT_SLUG}}`, `{{AGENT_PREFIX}}`, `{{TECH_STACK_DESC}}`,
   `{{BRAIN_PATH}}`, `{{TASK_ID_PREFIX}}`. If you add a new placeholder,
   add it to the `sed` block in `install.sh`.
3. **Process over content.** Lift the *workflow* (pre-task ritual, 6-gate
   review, contract-first, parallel conflict prevention, design-first,
   live mini-retro) — not the specific lessons. Per-project lessons land
   in the consumer's `brain-hot.md` under `## Project-specific rules`.
4. **Skill SKILL.md headers must include `name`, `description`, and
   `## Token budget`.** No skill without a budget section. The
   `description` must be **trigger/symptom-based** (CSO), not a workflow
   summary — lead with the user phrases / slash-commands / failure
   symptoms that should auto-load it (see `CONTRIBUTING.md` "Improving a
   skill").
5. **Each agent file MUST reference `agent-pre-task-ritual.md` and
   `brain-hot.md` as mandatory reads** in its body — that's the contract
   between orchestrator and subagent.
6. **Never write or run code in `core/.claude/memory/`** — that folder is
   shipped empty (with a README explaining the in-repo Brain fallback).
   Same for `core/docs/spec/sprints/.gitkeep` and `retros/.gitkeep`.

## Adding a new preset

`docs/adding-new-preset.md` has the full recipe. Short version:

```
presets/<name>/
├── agents/<some-engineer>.md
├── rules/<some-rule>.md
├── skills/<some-skill>/SKILL.md
└── docs/setup/<some-doc>.md
```

The installer merges these into the same paths in the target. No
registration step — just put the files in the right shape and add a row
to the preset table in `README.md`.

## Verification cadence

After any change, do at minimum:

```bash
mkdir -p /tmp/test-install
./install.sh /tmp/test-install --preset go-hex,nextjs-fsd \
  --config <(echo 'PROJECT_NAME="Test Service"
PROJECT_SLUG=test-svc
AGENT_PREFIX=tsvc
TASK_ID_PREFIX=TSVC
TECH_STACK_DESC="Go 1.22, Postgres, Next.js 14"
BRAIN_PATH=""
PRESETS=go-hex,nextjs-fsd') --force

grep -rln '{{[A-Z_]\{2,\}}}' /tmp/test-install  # must be empty
ls /tmp/test-install/.claude/agents/            # core + preset agents
ls /tmp/test-install/.claude/skills/            # 14 core + preset skills
```

Full check: `docs/control-plane-architecture.md` "Verification" section.

## Out of scope (deliberately)

- Migrating *existing* idip/aggegator-style projects to template-managed
- Versioning / `install.sh upgrade` (later)
- ClickUp / Sentry / Mixpanel wiring beyond skill stubs
- Managing the external Obsidian Brain itself

## See also

- `README.md` — user-facing
- `docs/control-plane-architecture.md` — the layered pattern explained
- `docs/how-to-customize.md` — common per-project edits
- `docs/adding-new-preset.md` — extend the template
- Plan doc that drove this build:
  `~/.claude/plans/project-users-rittiphonphoarun-desktop-sleepy-crab.md`
