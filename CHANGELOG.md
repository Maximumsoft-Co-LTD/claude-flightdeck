# Changelog — AI-Workflows template

> Versioned changes to the **template itself** (the `core/` + `presets/` +
> `install.sh` you copy into a target project). Target-project changes do
> NOT belong here — those live in each project's own changelog (often
> produced by `/changelog`).
>
> Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) +
> semver. Each release should list **Added / Changed / Fixed / Removed**
> sub-sections as relevant.

## Unreleased

- (none yet)

## v0.5.0 — 2026-05-22

The **"file-based dispatch"** release — stops oversized inline prompts
from stalling subagents. Instead of pasting a long task spec into the
`Agent` `prompt` argument, the orchestrator writes a **brief file** and
dispatches with a short pointer prompt; the agent reads its brief first.
Modeled on the [superpowers](https://github.com/obra/superpowers)
plugin's plan/spec-file + prompt-template-file pattern.

### Added

- **`core/docs/setup/file-based-dispatch.md`** — the convention: why
  long inline prompts hang, the brief-file location/naming
  (`docs/designs/sprint-S<N>/_briefs/<TASK_ID>-<role>.md`), the short
  pointer-prompt shape, lifecycle/commit guidance, and a worked example.
- **Pre-task ritual Step 0** (`agent-pre-task-ritual.md`) — every agent
  now reads its brief file FIRST when the dispatch names one. Single
  shared edit ⇒ all 12 agents (5 core + 7 preset) become brief-aware.

### Changed

- **All 12 agent files** — each gains a "Step 0 — read your brief"
  pointer in its pre-task ritual (role-specific:
  `design`/`impl`/`review`/`retro`). The `orchestrator` also gains a
  "write a brief, dispatch a pointer" note for when it dispatches.
- **`/next-task`, `/assign`, `/dispatch-parallel`** — dispatch steps now
  write the spec to a brief file and dispatch a short pointer prompt
  instead of inlining the full spec.
- **`dispatch-prompt-template.md`** — reframed as the **brief-file
  content** plus a short pointer-prompt template (was: "paste this as
  the inline prompt").
- **`sub-agent-workflow.md`** §3 — file-based dispatch is now the
  documented default for non-trivial work; inline only for tiny
  (~≤30-line) tasks.

### Why

A multi-thousand-line `prompt` string can stall the dispatch before the
subagent starts. A short pointer + a re-readable, auditable brief file
is robust, keeps the orchestrator's context lean, and lines the audit
trail up with a concrete artifact.

## v0.4.1 — 2026-05-22

The **"self-containment"** release — makes every rule and lesson
reference resolve **in-repo**, so adopters who don't have the original
external "second brain" never hit a dangling pointer. Also reconciles a
two-scheme A-rule numbering collision inherited from the source repos.

### Fixed

- **Dangling lesson references (17)** — `L005, L008, L021, L022, L023,
  L026, L030, L033, L036, L040, L041, L042, L049, L058, L063, L102,
  L109` were cited in the design templates / workflow docs but defined
  nowhere in-repo. All now have a one-line definition in the
  `lesson-trigger-map.md` `L###` reference table.
- **A-rule numbering collision** — two conflicting schemes
  (`brain-hot.md`'s global A001-A010 vs. an older domain scheme where
  A013=LSP, A015=design-first, A016=mini-retro, A017=backlog-audit, and
  A001-A011 carried domain meanings). Canonicalized to **one** meaning:
  A001-A010 = the global always-apply rules; A011+ = project-local.
  Stale `A013/A015/A016/A017` references remapped to `A010/A005/A009/A008`
  across `workflow-master.md`, `getting-started-tour.md`,
  `zero-fix-task-template.md`, `compliance-mapping.md`, and both
  playbooks.
- **Dangling file reference** — `.claude/rules/project-local.md` (never
  shipped) was referenced by the two playbooks and several docs;
  re-pointed to `brain-hot.md` (A011+) + `lesson-trigger-map.md`.
- **6-gate cross-refs** — several docs cited `§N4` for the 6-gate review;
  corrected to `§N3` (N4 is parallel-conflict-prevention).

### Changed

- **`lesson-trigger-map.md`** — de-domain-specified: backend/frontend
  tables now use stack-neutral `N1`/`N2` + defined `L###` instead of
  colliding domain `A###`; removed hardcoded RBAC / Kafka / framework
  paths; dropped the "full lesson detail lives in your brain / MemPalace"
  framing (the table **is** the detail now).
- **`brain-hot.md.tmpl`** — `BRAIN_PATH` framed as explicitly optional;
  header states the template is fully self-contained without an external
  brain.
- **De-domain-specifying** — removed leftover source-repo names
  (`idip-platform`, `aggegator`, `claude-foundation`) and example task
  IDs (`IDIP-`, `AGG-`) from `core/` per the template's own ground rules.

## v0.4.0 — 2026-05-22

The **"feedback loop"** release — closes the distributed-template gap:
adopters can now send structured feedback back to the canonical repo
without any always-on phone-home. Pull-based, zero passive token cost.

### Added

- **GitHub issue forms** (`.github/ISSUE_TEMPLATE/`) — 5 structured
  YAML forms (bug / rule-feedback / preset-request / skill-feedback /
  onboarding-feedback) each with a template-version dropdown, plus a
  `config.yml` routing to Discussions + onboarding guide + CONTRIBUTING.
- **`/flightdeck-feedback` skill** (`core/.claude/skills/flightdeck-feedback/`)
  — opt-in, one-shot. Reads the install manifest for version context,
  asks the feedback type, drafts a structured issue body, **redacts
  secrets**, shows a **preview**, then opens the issue via `gh` (or
  prints a prefilled URL). Never sends automatically.
- **`CONTRIBUTING.md`** — 4 contribution paths (issue / discussion /
  in-Claude skill / PR), `core/` ground rules, local contributor setup.
- **`.github/PULL_REQUEST_TEMPLATE.md`** — VERSION-bump + CHANGELOG +
  de-domain-specify + token-budget checklist.
- **`core/docs/setup/feedback.md`** — ships into every project; how to
  send feedback upstream (prefilled URLs + skill + sanitized-retro
  sharing).

### Changed

- **`install.sh`** — Next-steps output now mentions `/flightdeck-feedback`.
- **`README.md`** — new "Feedback & contributing" section.

### Design note

Feedback is **pull, not push** — nothing phones home, every send shows
a preview first, and the only token cost is the one-shot
`/flightdeck-feedback` invocation (~5-10k, opt-in). No always-on
telemetry by design (privacy + token-cost).

## v0.3.0 — 2026-05-22

The **"adopter onboarding"** release — adds an 8-stage setup wizard
that takes a fresh install from `template files in place` to
`Claude Code understands this project`. Multi-repo aware: detects
sibling installs and offers soft inheritance of project-local
A-rules.

### Added

- **`/onboard` skill** (`core/.claude/skills/onboard/SKILL.md`,
  ~330 lines) — user-invocable 8-stage hybrid wizard. Auto-does
  mechanical work (topology detection, codebase scan, git history
  mining, document drafting); prompts the operator only for context
  Claude can't infer (team interview, A-rule ratification, sprint
  state). Subcommands: `refresh` / `scan` / `rules` / `retro`.
- **`onboarding-engineer` agent**
  (`core/.claude/agents/onboarding-engineer.md`) — doc-drafting
  specialist for Stage 4. Reads codebase scan + interview answers
  + git-mining signals; writes root + per-area `CLAUDE.md`, polished
  `codebase-orientation.md`, `team-conventions.md`, and **drafts**
  (never auto-applies) A011+ rule candidates for operator
  ratification.
- **3 helper scripts** under
  `core/.claude/skills/onboard/scripts/`:
  - `detect-topology.sh` — JSON output of repo type (single /
    monorepo / meta), languages, areas, sibling installs, preset
    recommendations
  - `mine-git-history.sh` — fix-class commit aggregation → JSONL
    of hotspot files / keyword frequency / revert hotspots
  - `extract-pr-comments.sh` — `gh`-based recent PR review-comment
    extractor for convention sniffing (fail-open if `gh` missing)
- **5 reference deep-dives** under
  `core/.claude/skills/onboard/references/`:
  `repo-topology-detection.md`, `interview-questions.md`,
  `pattern-mining-prompts.md`, `draft-templates.md`,
  `multi-repo-coordination.md`.
- **`docs/setup/onboarding-guide.md`** (~330 lines) — operator
  companion for `/onboard`. Walks the 8 stages with what-to-expect
  per stage, multi-repo decision tree, common stumbles, FAQ.
- **`docs/setup/sibling-repos.md.tmpl`** — lands when `/onboard`
  detects multi-repo inheritance; documents the soft-inheritance
  link + conflict-resolution protocol.
- **`docs/setup/retention-policy.md`** (extracted from
  `audit-trail.md`) — full retention policy across all artifact
  classes (audit logs, sprints, retros, design docs).

### Changed

- **Root `CLAUDE.md.tmpl`** — new dispatch-routing row for
  first-time setup ("→ `/onboard`").
- **`.claude/rules/brain-hot.md.tmpl`** — `## Where to look next`
  now leads with "First time? Run `/onboard`".
- **`README.md`** — new "After install — run `/onboard`" section
  promoting the wizard right after the install command.
- **`getting-started-tour.md`** — new **Step 0** at the top:
  "Run `/onboard` first."
- **`audit-trail.md`** — Retention section now points at
  `retention-policy.md` for the full policy (deduplication).

### Fixed

- (none — `v0.3.0` is purely additive)

## v0.2.0 — 2026-05-22

The "operational tier" release — adds drift control, audit trail, CI
enforcement, and a recovery path. Aligned with the 6-gate review +
A001-A010 hot rules.

### Added

- **`VERSION` file** at the template root (single line, semver). Read
  by `install.sh` and exposed as `$AIWF_VERSION`.
- **`install.sh --version` flag** — prints `AI-Workflows vX.Y.Z` and
  exits.
- **`install.sh diff <target>` subcommand** — reports drift between a
  target's `.ai-workflows/manifest.json` and the current template
  version. Lists per-file drift since the manifest's
  `source_commit`.
- **`$TARGET/.ai-workflows/manifest.json`** — written at install end.
  Captures version, ISO8601 install date, presets used, placeholder
  names (no secret values), and `source_commit` (template repo
  `git rev-parse --short HEAD`, empty for tarball installs).
- **`CHANGELOG.md`** — this file. Versioning + retro-friendly
  history of template-level changes.
- **Audit-trail hook**:
  `core/.claude/hooks/audit.sh` (PostToolUse on `Agent` +
  SubagentStop) — appends one JSONL line per agent dispatch /
  completion to `docs/spec/audit/YYYY-MM.jsonl`. Fail-open (never
  blocks dispatch). Schema documented in
  `docs/setup/audit-trail.md`.
- **`docs/setup/audit-trail.md`** — JSONL schema, retention policy
  defaults (12 months baseline, longer for SOC2), redaction guidance,
  jq query recipes ("dispatches by agent X", "gate failures last
  week"), SIEM ingestion notes.
- **PR-blocking 6-gate CI workflow**:
  `core/.github/workflows/post-delegation-gate.yml` — runs on
  `pull_request` to `main` + integration branches. Maps each of the 6
  gates to a job step (Inspect / Build+Test / Boundary / Quality /
  Wiring / Smoke). Quality step is a logged no-op (humans + reviewer
  agents do this in PR).
- **Cross-CI stubs** at `core/docs/setup/ci-stubs/`:
  `gitlab-ci.yml.example`, `Jenkinsfile.example`,
  `azure-pipelines.yml.example`, `.circleci/config.yml.example`.
- **`docs/setup/ci-integration.md`** — per-CI adaptation guide,
  secret / variable wiring, lint-hook-in-CI vs local notes.
- **`/recover` skill**:
  `core/.claude/skills/recover/SKILL.md` — safe recovery from
  partial-dispatch failures, orphan worktrees, mid-merge aborts,
  accidental main commits, lost branches. User-invocable.
- **`docs/playbooks/failure-recovery.md`** — 6-8 named scenarios with
  detailed walkthroughs, decision tree ("when to recover vs leave
  alone"), specific `/dispatch-parallel` partial-success guidance.

### Changed

- `install.sh` now records `manifest.json` at install end (visible
  drift surface for multi-project installs).
- `core/.claude/settings.*.tmpl` (all permission-profile variants —
  `restricted` / `standard` / `permissive`) gain a PostToolUse
  matcher on `Agent` and a SubagentStop matcher calling `audit.sh`
  alongside the existing `Write|Edit|MultiEdit` lint hook.
- `README.md` gains a **Versioning & upgrades** section pointing at
  `VERSION`, `manifest.json`, and `install.sh diff`.

### Notes

- Re-install with `--force` (after backup) remains the upgrade path
  until `install.sh upgrade` lands (out of scope for v0.2.x).
- Audit JSONL is **opt-in** via `.gitignore` — see
  `docs/setup/audit-trail.md` for whether your repo should track or
  ignore the audit folder.

## v0.1.0 — initial template lift

- Initial extraction from `idip-platform` + `aggegator` —
  de-domain-specified `core/` + four presets (`go-hex`, `nextjs-fsd`,
  `vue-pinia`, `k8s-helm`).
- 14 user-invocable skills (`/next-task`, `/promote`, `/discover`,
  `/assign`, `/progress`, `/archive`, `/retro`, `/document`,
  `/dispatch-parallel`, `/design-review`, `/post-delegation-gate`,
  `/deploy`, `/changelog`, `/index-refresh`).
- 4 core agents (`orchestrator`, `design-doc-writer`,
  `senior-tech-lead`, `sprint-retro-author`).
- 7 always-loaded rules (`brain-hot`, `agent-pre-task-ritual`,
  `lsp-first`, `sub-agent-workflow`, `phase-matrix`,
  `programming-fundamentals`, `git-workflow`).
- Lint dispatcher PostToolUse hook (`core/.claude/hooks/lint.sh`).
- AI workflow validation CI
  (`core/.github/workflows/ai-workflow-validation.yml`) — checks
  placeholder render + agent / skill frontmatter.

[unreleased]: ./
