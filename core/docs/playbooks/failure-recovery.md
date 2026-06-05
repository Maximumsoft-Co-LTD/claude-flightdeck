# Playbook — Failure recovery

> Operator playbook for recovering from broken git state. This is the
> deep-dive that the `/recover` skill points at. Includes named
> scenarios with full walkthroughs, a "when to recover vs leave
> alone" decision tree, and specific guidance for the
> `/dispatch-parallel` partial-success case.
>
> **Core principle:** read state before acting. `reflog` before
> destroying. Confirm before chaining destructive commands.

## When to recover vs when to leave alone

```
                Something looks wrong
                         ↓
   ┌─────────────────────┴─────────────────────┐
   ↓                                            ↓
Is the current state                  Can you finish what you started
acceptable as-is?                     by going forward (commits, fixes)?
   │ yes                                         │ yes
   ↓                                             ↓
LEAVE ALONE. Document in the              FIX FORWARD.
backlog Follow-ups section if you         No recovery needed.
want to remember it; don't touch git.    Commit, gate, ship.
   │ no                                          │ no
   ↓                                             ↓
RECOVER. Use /recover or this playbook.   RECOVER. Same.
```

**Examples — leave alone:**
- A worktree exists from a task you finished and PR'd. The worktree
  is harmless until you clean up; cleanup can wait.
- A stash has been sitting for a sprint with notes you may need;
  drop it later, not in a panic.
- A commit on a feature branch isn't perfect — rebase / amend in
  the normal flow, not via `/recover`.

**Examples — recover:**
- Worktree is blocking another dispatch because the path overlaps.
- Merge conflict half-resolved and you've forgotten which file is
  which.
- Commit went to `main` instead of a feature branch.
- A branch you needed for a PR is gone.

## Scenario 1 — `/dispatch-parallel` partial success

The most common reason `/recover` is invoked. Two or three
subagents were dispatched in parallel; one finished + committed, one
or two did not.

**Symptoms:**

- `git worktree list` shows the worktrees from the dispatch.
- `git log --oneline --all` shows commits from agent A on its
  branch, no commits from agent B's branch.
- Agent B's worktree may have uncommitted changes (worktree-isolated
  failure) or may be empty (agent never wrote).

**Decision tree:**

```
Agent A committed + Agent B did not
        ↓
Is A's work independent (could ship on its own)?
   yes →  Land A's PR. Re-dispatch B as a single task.
   no  →  Both must land together → REVERT A on its branch
          (don't delete; the work may be salvageable). Re-dispatch
          both as a single SERIALIZED task (not parallel).
```

**Walkthrough (revert A, re-dispatch both serially):**

```bash
# 1. Inventory:
git worktree list
git log --oneline --all --since='2 hours ago'

# 2. Revert A's commits (keep history, just neutralize):
git -C <A-worktree-path> revert <A-sha-1>..<A-sha-N>
git -C <A-worktree-path> push origin <A-branch> 2>/dev/null || true

# 3. Remove the half-done worktree for B (force only if no commits):
git -C <A-worktree-path> log --oneline -1   # check there's nothing valuable
git worktree remove --force <B-worktree-path>
git branch -D <B-feature-branch>

# 4. Re-dispatch SERIALIZED:
#    /assign <task-A>    → finish A inline / as single subagent
#    /assign <task-B>    → after A merges, run B
```

**Append to the backlog's Follow-ups section** (`docs/project/backlog.md` `## Follow-ups`):

```markdown
| 2026-05-22 | recovery | partial-dispatch | A finished, B agent timed out at gate 2 | reverted A on branch, re-ran both serialized |
```

## Scenario 2 — Orphan worktree

`git worktree list` shows a worktree the user doesn't recognize, or
one from a task they thought they cleaned up.

**Walkthrough:**

```bash
# 1. See what's in there:
WT=<path-from-worktree-list>
git -C "$WT" status -s
git -C "$WT" log --oneline -5

# 2. Decide: any work to save?
#   - If yes: cherry-pick the commits onto a real branch:
git -C <main-checkout> cherry-pick <sha-1> <sha-2>

# 3. Remove the worktree:
git worktree remove --force "$WT"

# 4. If the branch is also abandoned:
git branch -D <branch-name>

# 5. Verify cleanup:
git worktree list
```

## Scenario 3 — Mid-merge abort

`git status` shows `UU` / `AA` markers; you started a merge, got
distracted, and need to go back.

**Walkthrough:**

```bash
# 1. Inventory:
git status -s
ls .git/MERGE_HEAD 2>/dev/null    # confirms an in-progress merge

# 2. Two options:
git merge --abort                  # restores pre-merge state (preferred)
# OR if --abort fails (rare — merge already committed):
git reflog | head -5               # find the pre-merge HEAD
git reset --hard HEAD@{<n>}        # only after confirming the snapshot

# 3. If you saved partial conflict resolution and want to keep it:
git stash push -m "partial-merge-$(date +%s)" --include-untracked
git merge --abort
# Apply the stash later when you're ready to retry the merge.
```

## Scenario 4 — Accidental commit on main

You meant to branch off, ran `git commit`, then realized HEAD was on
`main` (or `dev` / `integration`).

**Walkthrough (not yet pushed):**

```bash
# 1. Confirm the commit is the one you want to move:
git log --oneline -3

# 2. Move it to a feature branch:
git switch -c feat/<task-id>-<slug>    # creates branch at current HEAD
git switch main
git reset --hard HEAD~1                # rewind main one commit

# 3. Push the feature branch:
git switch feat/<task-id>-<slug>
git push -u origin feat/<task-id>-<slug>
```

**Walkthrough (already pushed):**

```bash
# Do NOT rewrite remote main. Revert in a PR instead:
git revert <sha-on-main>
git push origin main:revert-<short-sha>
# Then re-apply the work cleanly on a feature branch and PR normally.
```

## Scenario 5 — Lost branch

A branch you expected to find is gone. Maybe `git branch -D` ran
prematurely; maybe a stale `git fetch --prune` pruned it.

**Walkthrough:**

```bash
# 1. Look for the SHA in the reflog (covers ~90 days):
git reflog | head -30
# Look for lines like "commit:" / "checkout: moving from <name>"

# 2. If not in reflog, check dangling commits:
git fsck --lost-found
# Output includes "dangling commit <sha>" — inspect:
git show <sha>

# 3. Re-create the branch at the SHA:
git branch <recovered-name> <sha>
git log --oneline <recovered-name> -5    # confirm

# 4. Push:
git push -u origin <recovered-name>
```

## Scenario 6 — Stuck rebase

You ran `git rebase` and now you're in the middle of one with no
clear path out.

**Walkthrough:**

```bash
# 1. See what's happening:
git status                          # shows "rebase in progress"
ls .git/rebase-apply/ 2>/dev/null   # interactive / apply mailbox style
ls .git/rebase-merge/ 2>/dev/null   # merge style

# 2. Decide:
git rebase --abort     # safest — back to pre-rebase state
# OR continue forward:
# (a) skip the bad commit:
git rebase --skip
# (b) resolve + continue:
git add <resolved-files>
git rebase --continue
```

If the rebase included force-pushing to a shared branch and you're
already past `--abort` → escalate to scenario 4 (revert PR).

## Scenario 7 — Detached HEAD with uncommitted work

You ran `git checkout <sha>` to look at history, then edited and
committed. Now `git status` says "HEAD detached".

**Walkthrough:**

```bash
# 1. Save the detached work to a branch immediately:
git switch -c recover/detached-$(date +%Y%m%d-%H%M%S)

# 2. Confirm:
git status                    # should say "on branch recover/..."
git log --oneline -5

# 3. Decide: PR this branch, or cherry-pick its commits onto a
#    proper feature branch:
git cherry-pick <sha-1> <sha-2>    # onto feat/<task-id>-<slug>
```

## Scenario 8 — Wrong-repo commit (submodule / meta-repo)

You committed to the meta-repo when you meant to commit to a
submodule (or vice versa). Most common when using `cd` instead of
`git -C` (forbidden — see `git-workflow.md` rule 6).

**Walkthrough:**

```bash
# 1. Identify the wrong-repo commit:
git -C <wrong-repo> log --oneline -1

# 2. Cherry-pick into the correct repo:
git -C <correct-repo> cherry-pick <sha>

# 3. Revert in the wrong repo:
git -C <wrong-repo> reset --soft HEAD~1   # if local-only
# OR git -C <wrong-repo> revert <sha>     # if pushed

# 4. Push the cherry-picked commit:
git -C <correct-repo> push -u origin <branch>

# 5. Add a row to the backlog Follow-ups section + reinforce: always `git -C`, never `cd`.
```

## What to NEVER do

- ❌ `git reset --hard` without first checking what HEAD@{1} actually
  points at via `reflog`.
- ❌ `git push --force` on `main` / `dev` / `integration`. Always
  revert PRs on protected branches.
- ❌ `git clean -fd` before confirming there's nothing in untracked
  files you want to save.
- ❌ `git branch -D <name>` without confirming the branch has a
  remote / another local pointer / a tag — otherwise the commits are
  on the 90-day reflog-expiry clock.
- ❌ Pipe multiple destructive commands through `&&` without
  intermediate confirmation — partial failure leaves unpredictable
  state.
- ❌ Skip the backlog Follow-ups row. The retro is how we stop the same
  recovery from happening again next sprint.

## Related

- `.claude/skills/recover/SKILL.md` — the skill the user invokes;
  this playbook is its longform companion
- `.claude/rules/git-workflow.md` — the 7 reflex rules; rule 7 is
  "reflog before destroying"
- `.claude/skills/work/SKILL.md` — Scenario 1 starts
  here
- `docs/playbooks/parallel-conflict-prevention.md` — how to prevent
  scenario 1 next time
- `docs/playbooks/post-delegation-review.md` — the gates that catch
  most issues before they need recovery
- `docs/project/backlog.md` — where every recovery writes its
  post-mortem row
