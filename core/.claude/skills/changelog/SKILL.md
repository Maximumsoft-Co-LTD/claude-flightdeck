---
name: changelog
description: "Generate a Keep-a-Changelog style CHANGELOG.md from git history using Conventional Commits. Supports per-repo and unified multi-repo aggregation. Use when the user says '/changelog', 'generate changelog', 'what changed since v1.2.0', or before tagging a release."
user_invocable: true
---

# /changelog — Generate from Git History

## Token budget (MANDATORY)

- Bound `git log` by the tag range — do not log the entire history.
- Use `--oneline --no-merges` to keep the output small.
- Read the existing `CHANGELOG.md` once to preserve prior entries; never re-Read it per commit.

## Usage

- `/changelog` — generate changelog for the current repo from git log since last tag
- `/changelog --unified` — aggregate all per-repo changelogs into the platform `CHANGELOG.md`
- `/changelog --all` — generate per-repo changelogs for every repo + unified
- `/changelog --dry-run` — preview without writing files

## How it works

### Step 1 — Detect context

Determine which repo you're in:
- Inside a service / component repo → generate for that repo
- At platform root with `--unified` → aggregate all repos
- At platform root without `--unified` → ask user to clarify

### Step 2 — Find version range

```bash
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LATEST_TAG" ]; then
  RANGE="HEAD"
else
  RANGE="${LATEST_TAG}..HEAD"
fi
```

### Step 3 — Parse git log

```bash
git log ${RANGE} --oneline --no-merges
```

Parse each commit per Conventional Commits: `<type>(<scope>): <description>`.

### Step 4 — Map to Keep-a-Changelog categories

| Conventional Commit Type | Changelog Category |
|---|---|
| `feat` | Added |
| `fix` | Fixed |
| `refactor`, `perf` | Changed |
| `docs` | Changed |
| `deprecate` (or message contains "deprecate") | Deprecated |
| `revert`, message contains "remove" | Removed |
| `security`, `vuln` | Security |
| `test`, `ci`, `chore`, `build`, `style` | _(skip — internal only)_ |

Non-conventional commits → "Changed" with the original message.

### Step 5 — Generate Markdown (Keep a Changelog 1.1.0)

```markdown
## [Unreleased]

### Added
- Description of new feature (#PR)

### Fixed
- Description of bug fix (#PR)

### Changed
- Description of change (#PR)
```

When tagging a release, replace `[Unreleased]` with `## [1.2.0] - 2024-03-20`.

### Step 6 — Write `CHANGELOG.md`

- Read the existing file if present.
- Insert the new version section after the header (newest first).
- Preserve all existing entries.
- Write to the repo root.

### Step 7 — Unified changelog (`--unified`)

For each repo in the platform:
1. Read its `CHANGELOG.md`.
2. Aggregate into the platform-root `CHANGELOG.md`:
   ```markdown
   ## [Sprint S<N>] - 2024-03-20

   ### <repo-a> v1.2.0
   #### Added
   - ...

   ### <repo-b> v0.8.0
   #### Fixed
   - ...
   ```
3. Write to the platform-root `CHANGELOG.md`.

## CHANGELOG.md header template

Every per-repo `CHANGELOG.md` starts with:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
```

## Rules

- **Never delete** existing changelog entries.
- **Prepend** new versions (newest first).
- Include short commit hash for traceability: `(abc1234)`.
- If a commit references a ticket / task ID, include it.
- Skip merge commits (`--no-merges`).
- Group multiple commits of the same type into a single category.
- Empty categories should be omitted (don't show `### Removed` if nothing was removed).
- For `--unified`: only include repos that have changes.
