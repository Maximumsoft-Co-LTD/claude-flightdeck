# Integration Branch Strategy (Per Sprint)

> **Purpose:** isolate parallel sprint work from `dev` until the full sprint passes CI + senior-tech-lead review. Conflicts resolve in sandbox (integration branch), not on `dev`. Used by the `dispatch-parallel` skill.

## Branch Topology

```
main          ─────────────────────────────────●─── tag v1.5.0
                                              ↑
dev           ─────────────────────────────●──┘   (UAT auto-deploy)
                                          ↑
integration/  ●──────●──●──●──●─────●─●─●─┘       (sprint sandbox)
sprint-NN
              │     │  │  │  │     │ │ │
feature/B001  ●─────┘  │  │  │     │ │ │           (worktree branches)
feature/B002  ●────────┘  │  │     │ │ │
feature/B003  ●───────────┘  │     │ │ │
feature/B004  ●──────────────┘     │ │ │
feature/B005a ●────────────────────┘ │ │
feature/B005b ●──────────────────────┘ │
feature/B006  ●────────────────────────┘
...
```

## Lifecycle

### 1. Sprint kickoff (Day 1)
1. Create integration branch: `git checkout -b integration/sprint-NN origin/dev`
2. Push: `git push -u origin integration/sprint-NN`
3. Create empty PR `integration/sprint-NN → dev` as **DRAFT** with the sprint summary
4. Pin PR in the repo for visibility

### 2. Feature work (Days 1-N)
1. Each task: agent creates worktree + branch from `dev`
2. Agent implements per Design Doc
3. Agent opens PR `feature/B### → integration/sprint-NN` (NOT `dev`)
4. CI runs on every PR (lint + unit + e2e if affected)
5. Agent waits for CI green; if red, fixes and re-runs

### 3. Merge into integration (continuous)
1. As each feature PR goes green → merge to `integration/sprint-NN`
2. Merge strategy: **rebase** (linear history) — `gh pr merge <pr> --rebase`
3. If next PR has conflict with already-merged work:
   - Sub-agent rebases its branch: `git rebase integration/sprint-NN`
   - Resolve conflicts in worktree
   - Re-push, re-run CI
4. **No PR merges directly to `dev` during sprint**

### 4. Sprint integration review (Day N-1)
1. After all feature PRs merged to integration:
   - Run full CI on integration branch
   - Invoke `senior-tech-lead` agent for review (sees full sprint as a unit)
   - Review against `docs/setup/lesson-trigger-map.md` — every applicable lesson applied?
2. If review fails → loop back specific tasks (sub-agent)
3. If review passes → mark integration PR ready (un-draft)

### 5. Integration → dev (Day N)
1. Un-draft integration PR
2. Final CI run on the merge-base
3. `gh pr merge integration/sprint-NN --merge` (NOT rebase — preserve sprint as one merge commit on dev)
4. Tag dev with sprint label for tracking
5. UAT auto-deploys from dev

### 6. dev → main (UAT validated)
1. After UAT validation period (typically 1-3 days)
2. Open PR `dev → main` with UAT Checklist
3. Manual review
4. Merge → triggers prod build pipeline
5. After prod tag/deploy → close sprint

### 7. Cleanup (Day N+1)
1. Delete worktrees: `git worktree remove <path>` for each
2. Delete feature branches: `git branch -D feature/B###-*`
3. Delete integration branch: `git branch -D integration/sprint-NN`
4. Update backlog statuses
5. Add brain lessons learned this sprint

## When to deviate

| Situation | Action |
|-----------|--------|
| Hotfix (P0 prod outage) | Branch from `main`, expedited PR to `main`, merge back to `dev` AND `integration/sprint-NN` |
| Solo task (no parallel work this sprint) | Skip integration branch; PR feature → dev directly. Per-task DoD still applies. |
| Cross-repo migration | Multiple integration branches (one per repo); coordinate fan-in timing |
| Mid-sprint scope addition | New feature branch joins same integration branch; Conflict Radar re-run |
| Mid-sprint scope drop | Close PR; do not merge to integration. Branch deletable. |

## Anti-patterns

- Merging feature PR directly to `dev` during a parallel sprint (defeats integration)
- Force-pushing integration branch (history matters for review)
- Merging integration → dev with CI red (defeats purpose)
- Rebasing integration on dev mid-sprint (causes feature PRs to rebase too — coordinate first)
- Skipping senior-tech-lead review before integration → dev

## Conflict Resolution Playbook

### Pattern A: i18n files — multiple agents add keys
**Risk:** common. JSON merge conflicts are noisy.

**Resolution:**
- **Single i18n owner per sprint** designated; other agents emit i18n-key-deltas in their PR description
- Owner consolidates keys in one PR at end of sprint
- OR split into per-domain files — better long-term

### Pattern B: routing config — multiple agents add routes
**Risk:** medium. Sections add per-module routes.

**Resolution:**
- Module-scoped route files (one per feature module)
- Main router only imports + composes
- Agents touch their module file only

### Pattern C: package / dep manifest — multiple agents add deps
**Risk:** medium. Lockfile churn.

**Resolution:**
- One designated agent owns the manifest edits for the sprint
- Other agents emit "add dep X@Y" requests in their PR description
- Owner runs the install once, commits both manifest + lockfile

### Pattern D: shared component / store / service
**Risk:** high. Logic conflict, not just text.

**Resolution:**
- Conflict Radar must flag at design time
- Either: split component, sequence tasks, or assign single owner
- Never silently parallel — guaranteed rework

### Pattern E: migration files
**Risk:** high. Sequential numbering: `000115_foo.up.sql` then `000116_bar.up.sql`.

**Resolution:**
- Migration numbers allocated at sprint planning (recorded in sprint doc)
- Each agent uses pre-allocated number
- No mid-sprint allocation

## CI Configuration

`integration/sprint-NN` branches need same CI as `dev`:
- Lint (per language)
- Unit tests
- E2E tests (affected specs only)
- Build (container image)
- Type check (if typed language)

Add to `.github/workflows/ci.yaml`:
```yaml
on:
  push:
    branches: [main, dev, 'integration/**']
  pull_request:
    branches: [main, dev, 'integration/**']
```

## Migration from current `feature → dev` flow

For projects adopting this strategy after their first few sprints:
- Adopt integration branch from the next sprint onward
- Small-parallelism sprints (≤2 tasks) can stay on `feature → dev`
- Make integration branch the default for sprints with ≥3 parallel tasks

## Verification

How to confirm this strategy is working:

1. **Zero conflicts on `dev`** during sprint (all conflicts resolved in integration)
2. **Single merge commit per sprint** on `dev` (clean history)
3. **Rollback is sprint-scoped** — `git revert <integration merge sha>` rolls back whole sprint
4. **senior-tech-lead review catches** cross-task issues that solo PR review misses (target: 1+ catch per sprint)
5. **PR queue throughput** ≥ current — sprint completes in similar time despite extra integration step

## Cross-references

- `dispatch-parallel` skill (`.claude/skills/dispatch-parallel/SKILL.md`)
- `superpowers:using-git-worktrees`
- `superpowers:finishing-a-development-branch`
- `deployment-workflow.md` — overall release flow
