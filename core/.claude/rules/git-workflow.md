# Git Workflow (auto-loaded · reflex rules)

> Short reflex rules for git-touching work. NOT a textbook — every
> rule is one sentence with a `because` so you can apply it cold.
>
> Fires on: any task whose phase 11 (Ship) is ✓ in the
> [phase matrix](./phase-matrix.md), plus any agent that branches,
> commits, rebases, force-pushes, or opens a PR.

## The 7 reflex rules

1. **Branch from a fresh base.** Always `git fetch && git checkout -b
   <type>/<task-id>-<slug> origin/<integration-base>` — never from a
   stale local copy. `<type>` matches the task's `Type:` slot from the
   phase matrix (`feat | fix | refactor | chore | docs | spike |
   release`). Stale bases cause merge surprises caught at the gate,
   not at write time.
2. **One purpose per branch.** If you find yourself adding "and also"
   to the branch name, split it. Mixing a feature + a refactor in
   one branch makes review and rollback both harder.
3. **Atomic commits.** Each commit compiles, tests pass, and tells one
   story. "WIP" / "fix typo" / "address review" commits get squashed
   before merge. The atomic-commit rule is the runtime version of
   "one function, one thing" from `programming-fundamentals.md`.
4. **Conventional commit messages.**
   `<type>(<scope>): <subject>` (≤ 72 chars subject), blank line, body
   explaining the *why* (not the *what* — the diff shows the what).
   Types: `feat | fix | refactor | chore | docs | spike | release`
   (test-touching work tags as `feat` / `fix` / `refactor` per A001 —
   no standalone `test` type). Match the task's `Type:` slot from the
   phase matrix.
5. **Never `git push --force` on a shared branch.** Use
   `--force-with-lease` if you must — but only on your own feature
   branch. `main` / `dev` / integration branches: never force, even
   with lease. A branch is "shared" the moment another human or CI
   job has fetched it; your local feature branch before push is not
   shared.
6. **`git -C <path>` instead of `cd`.** Long agent sessions accumulate
   `cd` state and end up committing to the wrong repo. Always pass
   the path explicitly.
7. **Recover with `git reflog` before destroying.** Reach for
   `reflog` first when something looks lost — almost everything can
   be recovered for ~90 days. Only `git reset --hard` / `checkout
   --` / `clean -fd` once you've confirmed there's nothing to save.

## Pre-flight checklist (before push / PR)

- [ ] `git status -s` clean (no stray modified files)
- [ ] `git log --oneline origin/<base>..HEAD` reads like a story
  (squash WIP commits if not)
- [ ] Every commit message has a `<type>(<scope>): <subject>` line
- [ ] Lint / test / build pass locally (don't outsource this to CI;
  CI is the second check, not the first)
- [ ] No secrets / large binaries / `.env` / credentials committed
  (`git diff --stat origin/<base>` to scan size + new paths)
- [ ] Branch tracks remote (`git branch --set-upstream-to=…` or
  push with `-u`)

## PR opening checklist

- [ ] Title matches the lead commit's conventional subject
- [ ] Description summarizes *why* (1-3 bullets) and links the task
  ID + design doc
- [ ] "Test plan" / "How verified" section with concrete commands
  the reviewer can run
- [ ] Screenshots / before-after for UI changes
- [ ] Auto-merge OFF until 6-gate review passes

## Forbidden actions

- ❌ `--no-verify` on commits (skips hooks the team set up
  deliberately)
- ❌ `--no-gpg-sign` if the team requires signed commits
- ❌ Rewriting history on a branch other people have pulled
- ❌ Committing `.env` / credentials / large binaries (use
  `.gitignore` proactively)
- ❌ `git checkout .` or `git clean -fd` before checking what
  you're throwing away

## Tie-ins

- **A002 (zero-bug)** — atomic commits make `git bisect` cheap, so
  regressions are caught fast.
- **Phase matrix** — phase 11 (Ship) row ✓ → load this rule in the
  dispatched agent's ritual.
- **`programming-fundamentals.md`** — atomic commits = the delivery
  cousin of "one function, one thing."

## See also

- `.claude/rules/brain-hot.md` — the 10 A-rules (A002 zero-bug, A004
  6-gate review)
- `.claude/rules/phase-matrix.md` — when this rule fires
- `docs/setup/integration-branch-strategy.md` — your project's branch
  layout (feature → integration → main)
- `docs/setup/deployment-workflow.md` — what happens after the PR
  merges
