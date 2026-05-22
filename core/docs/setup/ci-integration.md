# CI Integration — running the 6-gate review on every PR

> The 6-gate post-delegation review (see
> `docs/playbooks/post-delegation-review.md`) is a discipline, not a
> suggestion. CI is where that discipline becomes enforcement.
>
> The template ships a GitHub Actions workflow as the primary
> implementation, plus four cross-CI stubs for teams not on GitHub.
> All implementations are mirrors of the same playbook — pick the one
> matching your runner and adapt.

## Files

| Provider | Path | Status |
|---|---|---|
| GitHub Actions | `.github/workflows/post-delegation-gate.yml` | full, PR-blocking |
| GitLab CI | `docs/setup/ci-stubs/gitlab-ci.yml.example` | stub |
| Jenkins | `docs/setup/ci-stubs/Jenkinsfile.example` | stub |
| Azure DevOps | `docs/setup/ci-stubs/azure-pipelines.yml.example` | stub |
| CircleCI | `docs/setup/ci-stubs/.circleci/config.yml.example` | stub |

The GitHub Actions file lives at install destination and runs on every
PR. The other four are **examples** — copy to your repo root (renaming
to drop `.example`) and adapt.

## Why each CI matters

- **Gate 1 Inspect** — surfaces stray secrets / large binaries before
  review. Catches the `.env` commit that everyone misses.
- **Gate 2 Build + Test** — catches the "workspace green, container
  red" class of failure (the most common Gate 2 catch).
- **Gate 3 Boundary** — architectural drift is the bug class hardest
  to spot in PR review; only a programmatic check catches it
  reliably.
- **Gate 4 Quality** — intentionally NOT in CI. Humans + reviewer
  subagents (`pr-review-toolkit:*`) do this in PR review. CI logs a
  notice so it's visible in the run summary.
- **Gate 5 Wiring** — advisory. Greps composition roots for symbols
  named in the PR body. Best-effort; not blocking.
- **Gate 6 Smoke** — `make smoke` if the project has it. Catches
  service-won't-start regressions that unit tests miss.

## Adaptation per CI

### GitHub Actions

Out of the box. The workflow runs on `pull_request` to `main`, `dev`,
or `integration`. To enforce blocking on merge, mark the
`post-delegation-gate / 6-gate review` check as required in branch
protection.

Required PR body conventions for Gate 5 to be useful: mention new
constructors / wiring entrypoints by name (e.g.
`Adds NewUserRepository, RegisterUserRoutes`). The grep is
`\b(New|Register|Wire|Bind)[A-Z][A-Za-z0-9]+\b`.

### GitLab CI

The stub assumes `merge_request_event` triggers (modern GitLab). For
older GitLab installs, swap `$CI_MERGE_REQUEST_TARGET_BRANCH_NAME` for
your equivalent (`$CI_COMMIT_REF_NAME`). The stub bootstraps a
minimal toolchain on `ubuntu:22.04`; in real use, swap to a
project-stack image (`golang:1.22`, `node:20`, etc.) for faster
cold-start.

### Jenkins

The stub assumes the GitHub Branch Source or GitLab Branch Source
plugin (to populate `CHANGE_TARGET` + `CHANGE_BODY`). Without those
plugins, `BASE_REF` defaults to `main` and Gate 5 falls back to an
empty grep (still reports correctly, just less useful).

Agent label `linux && docker` is a hint — adjust to match your fleet.
Pin orb / plugin versions in the Jenkins controller; the stub doesn't
embed pins.

### Azure DevOps

`$(System.PullRequest.TargetBranch)` and
`$(System.PullRequest.PullRequestTitle)` are the closest Azure
analogues to GitHub's `github.base_ref` / `github.event.pull_request.body`.
Full PR body requires the Azure DevOps REST API; the stub uses the PR
title instead. To upgrade, add a step that fetches the body via the
REST API + a `System.AccessToken` (see secrets section below).

### CircleCI

`CIRCLE_PR_BASE_BRANCH` is populated by the GitHub / Bitbucket
integration. PR body is not exposed by CircleCI directly; the stub
uses the most recent commit message as a proxy. For full PR body,
add a step calling the GitHub API with a token from CircleCI
contexts.

## Secrets / variables to wire

Most steps in the gates are **read-only** — no secrets required.
Where secrets ARE required:

| CI | Variable | Purpose |
|---|---|---|
| GitHub Actions | `GITHUB_TOKEN` (auto) | PR description access — already in env |
| GitLab | `$CI_JOB_TOKEN` (auto) | Repo clone; PR description is in `$CI_MERGE_REQUEST_DESCRIPTION` |
| Jenkins | none required | PR plugins inject `CHANGE_BODY` automatically |
| Azure DevOps | `$(System.AccessToken)` | Only if you upgrade Gate 5 to fetch PR body via REST |
| CircleCI | optional `GITHUB_TOKEN` in a context | Only if you upgrade Gate 5 to fetch PR body via GH API |

The audit hook (`.claude/hooks/audit.sh`) does NOT run in CI — it's a
session-time hook on the developer machine. If you want to capture
audit events from CI runs into the same JSONL, add a final step that
appends a structured event manually. (Out of scope for the stub —
JSONL is open format, simple to extend.)

## Lint hook: CI vs local

`core/.claude/hooks/lint.sh` runs as a PostToolUse hook **on the
developer machine**, after every `Write` / `Edit` / `MultiEdit`. It's
designed for fast feedback in the conversation — it exits 2 on a lint
fail, which Claude Code surfaces back to the model so it can
self-correct.

In CI, the lint should be re-run as a separate stage / job — DO NOT
shell into the agent hook from CI. Examples:

```yaml
# GitHub Actions
- name: Lint
  run: |
    if [ -f Makefile ] && grep -qE '^lint:' Makefile; then
      make lint
    fi
```

This keeps CI lint failures distinct from Gate 2 build failures and
keeps the hook focused on dev-loop usage.

## Branch protection (GitHub Actions)

Make the `6-gate review` check required on `main` / `dev` /
`integration`:

1. Settings → Branches → Add rule for `main`
2. Enable "Require status checks to pass before merging"
3. Add `post-delegation-gate / 6-gate review` from the search box
4. Optional: also require "Require pull request reviews before
   merging" + "Dismiss stale pull request approvals when new commits
   are pushed"

The wiring step (Gate 5) is advisory in the workflow definition; the
job overall still passes if Gate 5 only emits warnings.

## Troubleshooting

- **"no Makefile target X"** — the gates auto-skip when a target is
  missing. The CI logs a `::notice::` (GitHub) / equivalent. Add the
  target to your project Makefile to opt in.
- **"workspace build green, CI red"** — the canonical Gate 2 catch.
  Check container build context (sibling modules), then re-run.
  See playbook §Gate 2 — Common bug catches.
- **Gate 5 noisy / wrong** — Gate 5 is a heuristic. Tune the symbol
  regex in the workflow if your project's conventions differ (e.g.
  Python `make_x` instead of `NewX`). Mark advisory always.
- **Gate 6 flake** — your `make smoke` is not deterministic. Fix the
  test, not the gate. The playbook's §Gate 6 has the recipe for a
  reliable `smoke` target.

## Related

- `docs/playbooks/post-delegation-review.md` — the authoritative
  playbook the CI workflow implements
- `docs/setup/audit-trail.md` — sibling operational doc (the JSONL
  audit log)
- `CHANGELOG.md` (template root) — `post-delegation-gate.yml` added
  in v0.2.0
- `.github/workflows/ai-workflow-validation.yml` — sibling CI that
  checks template hygiene (placeholders, frontmatter)
