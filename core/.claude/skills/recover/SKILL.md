---
name: recover
description: "Safely recover from partial-dispatch failures, orphan worktrees, mid-merge aborts, accidental main commits, and lost branches. Inventories git state, classifies the failure mode with the user's confirmation, then walks through the recovery options for that class with explicit per-step confirmation. Use when the user says 'undo', 'rollback', 'recover', 'orphan worktree', 'partial commit', 'failed dispatch', 'merge gone wrong', '/recover', or after `/dispatch-parallel` reports partial success."
user_invocable: true
---

# /recover — Safe recovery from broken git state

Walks the operator through a deliberate, **non-destructive** recovery
from common failure modes that follow `/dispatch-parallel`, hand-edit
mistakes, or interrupted merges.

Canonical reference: `docs/playbooks/failure-recovery.md`.

**Core principle:** `git reflog` first; destructive operations
(`reset --hard`, `clean -fd`, `branch -D`) only after explicit
confirmation per step.

## Token budget (MANDATORY)

- `git status -s` + `git worktree list` + `git stash list` + `git log
  --oneline -5` is enough state for 90% of recoveries. Do NOT
  `git diff` everything up front.
- `git reflog | head -30` only when you need to find a lost SHA.
- Read FOLLOWUPS.md before writing to it; otherwise no other file
  reads.
- For each recovery branch, the destructive command runs only after
  the user types literal confirmation ("yes" or the exact SHA).

## Step 1 — Inventory current state

Run all four in one shell turn (read-only):

```bash
git -C "$PWD" status -s
git -C "$PWD" worktree list
git -C "$PWD" stash list
git -C "$PWD" log --oneline -5
```

Plus, if the user mentioned a specific branch / SHA / file, also:

```bash
git -C "$PWD" reflog | head -30
```

**Report back** what you see — do NOT act yet. The operator may have
context (e.g. "yes that worktree is mine, abandoned") that changes
what's safe.

## Step 2 — Classify the failure (user confirms)

Match the inventory against one of the named classes. Present the
match to the user with a one-line summary and ask them to confirm.

| Class | Signals |
|---|---|
| **Partial dispatch** | `git status` shows changes from one path but not others declared by `/dispatch-parallel`; some worktrees committed and others didn't |
| **Orphan worktree** | `git worktree list` shows worktrees with no recent activity / branches the user doesn't recognize |
| **Dirty merge** | `git status -s` shows `UU` / `AA` markers, or a `MERGE_HEAD` file exists in `.git/` |
| **Accidental main commit** | `git log --oneline -1` on `main` / `dev` / `integration` shows a commit you didn't intend there |
| **Lost branch** | A branch the user expected to find is gone (`git branch --list <name>` empty); SHA is recoverable via reflog for ~90 days |
| **Stuck rebase** | `.git/rebase-apply/` or `.git/rebase-merge/` exists |
| **Detached HEAD with work** | `git status` shows "HEAD detached at <sha>" + uncommitted work |

**If no class matches** → ask the user to describe what happened. Do
NOT guess. Do NOT default to "reset --hard".

## Step 3 — Per-class recovery

Present the options for the classified class. Each command runs
**only after explicit user confirmation**. No batch / silent
execution.

### A) Partial dispatch

1. Identify what's committed vs uncommitted:
   ```bash
   git log --oneline --all --since='2 hours ago'
   git status -s
   ```
2. Two paths:
   - **Revert** (clean slate, retry dispatch):
     ```bash
     git stash push -m "recover-stash-$(date +%s)"   # uncommitted
     git revert <sha-of-the-committed-half>          # committed half
     ```
   - **Fix forward** (keep committed half, complete the rest):
     - Re-dispatch the uncommitted half via `/dispatch-parallel`
       with `--only <task-id-2>` or by invoking the relevant agent
       directly.
     - Confirm via `/post-delegation-gate` before merge.

Ask the user which path they want before running anything.

### B) Orphan worktree

```bash
# inventory first (already done in Step 1):
git worktree list

# remove the orphan worktree (force only if its branch has no
# committed work you care about):
git worktree remove --force <path-from-list>

# if the branch is also abandoned:
git branch -D <feat-branch-name>
```

**Stop and ask** if the orphan has any commits not on `main` /
`integration` — those would be permanently lost.

### C) Dirty merge

Pick ONE:

```bash
# Option 1 — back out the merge entirely (most common):
git merge --abort

# Option 2 — go back to pre-merge state (if --abort doesn't work
# because the merge already committed):
git reset --hard HEAD@{1}     # only after confirming HEAD@{1} is the right snapshot
```

`HEAD@{1}` is the previous HEAD location — verify with
`git reflog | head -5` before running `reset --hard`.

### D) Accidental main commit

```bash
# Keep the changes but move them off main:
git reset --soft HEAD~1
git switch -c feat/<task-id>-<slug>
# Now your work is on a feature branch; main is back to its prior tip.
```

If the commit was already **pushed** to `main`:

- Don't rewrite remote main history. Open a `revert` PR instead:
  ```bash
  git revert <sha-on-main>
  git push origin main:revert-<sha>
  ```
- Then move the original commit to a proper feature branch and PR it
  back the right way.

### E) Lost branch

```bash
# Find candidate SHAs in the reflog:
git reflog | head -30
# (look for "commit:", "checkout: moving from <branch> to ...", etc.)

# Re-create the branch at the recovered SHA:
git branch <recovered-name> <sha>

# Confirm:
git log --oneline <recovered-name> -5
```

Ask the user to confirm the SHA before creating the branch. If
`reflog` doesn't have what you need, also check
`git fsck --lost-found` (dangling commits live ~90 days by default).

### F) Stuck rebase

```bash
# If `.git/rebase-apply` or `.git/rebase-merge` exists, decide:
git status                  # see what the rebase is in the middle of
git rebase --abort          # safest — restores pre-rebase state
# OR if you want to skip the offending commit + continue:
git rebase --skip
# OR if you've fixed the conflict, then:
git add <files> && git rebase --continue
```

### G) Detached HEAD with work

```bash
# Branch the detached HEAD so your work isn't lost:
git switch -c recover/detached-$(date +%Y%m%d-%H%M%S)
git log --oneline -5
# Now you have a branch you can rebase / merge / PR normally.
```

## Step 4 — Execute with confirmation

For every destructive command, the workflow is:

1. **Echo the command** about to run (do not run it).
2. **Ask the user**: "Run this? (yes / no / change command)".
3. **Run only on "yes"**. On "no", offer the next-safest option.
4. **After running**: re-run the Step 1 inventory and show the new
   state.

Never chain destructive commands in one shell call without
in-between confirmation. A single `set -e` failure in a chain leaves
unpredictable state.

## Step 5 — Post-mortem hook (always run)

After recovery succeeds, append a row to `docs/project/backlog.md` so
the sprint retro picks it up. Format:

```markdown
| YYYY-MM-DD | recovery | <class> | <one-sentence root cause> | <one-sentence what-changed> |
```

Examples:

- `2026-05-22 | recovery | partial-dispatch | Task A finished, Task B agent OOM'd at gate 2 | reverted A, re-dispatched B with smaller scope`
- `2026-05-22 | recovery | accidental-main-commit | Forgot to branch off integration | soft-reset + branched; added pre-push hook reminder`

This row makes the failure visible at sprint retro — so the
process can improve, not just the immediate state.

## What to NEVER do

- ❌ `git reset --hard` without confirming `HEAD@{1}` is the snapshot
  you expect.
- ❌ `git push --force` on `main` / `dev` / `integration` (use a
  revert PR instead).
- ❌ `git clean -fd` before confirming there's nothing valuable in
  untracked files (use `git stash --include-untracked` first).
- ❌ `git branch -D` on a branch you don't have backed up to remote
  or to another branch / tag.
- ❌ Run any destructive command in batch without per-step user
  confirmation.
- ❌ Skip the FOLLOWUPS.md row — the retro is how we learn.

## Related

- `docs/playbooks/failure-recovery.md` — full 6-8 scenario
  walkthroughs + decision tree
- `.claude/rules/git-workflow.md` rule 7 — "Recover with `git reflog`
  before destroying"
- `.claude/skills/work/SKILL.md` — what to do when
  partial-dispatch happens
- `docs/playbooks/parallel-conflict-prevention.md` — preventing the
  failure in the first place
- `docs/project/backlog.md` — where Step 5 writes
