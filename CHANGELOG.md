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
