---
name: dispatch-parallel
description: "Dispatch 2+ subagents in parallel safely, running the 4-layer Conflict Radar guard (path overlap, working-tree state, contract-first, task dependency graph) before dispatching. Refuses to dispatch if any overlap is detected; serializes instead. Use when the user says '/dispatch-parallel', 'fan out', 'work on these together', 'run both', 'in parallel', 'do these in parallel', names 2+ task IDs at once, or has multiple independent coding tasks."
user_invocable: true
---

# /dispatch-parallel — Safe Parallel Subagent Dispatch

> **Announce on start:** open your reply with "Using /dispatch-parallel to fan out N tasks after the Conflict Radar check."

Dispatch 2+ coding subagents in a single message with `isolation="worktree"`. Verifies the 4-layer Conflict Radar (see `docs/playbooks/parallel-conflict-prevention.md`) before dispatching.

## Token budget (MANDATORY)

- Read each task's design doc with `limit: 120` — header + Touched Files matrix only.
- Conflict Radar is grep-based — no full reads.
- Do NOT re-read CLAUDE.md (auto-loaded by the harness).

## Invocation

```
/dispatch-parallel <task-id-1> <task-id-2> ... <task-id-n>
```

The skill reads each task's design doc, extracts the declared paths, runs Conflict Radar, then either dispatches in parallel (overlap-free) or refuses and suggests serialization.

## Steps

1. **Read each task's design doc**

   For each task ID `{{TASK_ID_PREFIX}}-S<N>.<NN>`:

   ```
   Read docs/designs/sprint-S<N>/D<NNN>-<slug>.md (limit: 120)
   Extract: declared touched-files matrix, dependencies (blockedBy), subagent_type
   ```

2. **Conflict Radar Layer 1 — Path overlap check**

   For each pair of tasks, intersect their declared paths. If any pair intersects → SERIALIZE (refuse parallel dispatch).

   - Allowed: tasks touching different components / different modules.
   - Forbidden: two tasks both editing the same file or the same shared package.

3. **Conflict Radar Layer 1b — Working-tree state overlap**

   ```bash
   git status --porcelain
   ```

   For each declared path in step 1, check whether it overlaps with any path already dirty in the working tree. If yes, local state would conflict with the dispatched work → refuse.

4. **Conflict Radar Layer 2 — Worktree isolation per agent**

   When dispatching, include `isolation: "worktree"` in every `Agent()` call. The harness creates a temporary git worktree per subagent.

   **Write one brief file per agent first** (`docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md`, using the per-agent template below), then dispatch each with a SHORT pointer prompt — never inline the full spec (it stalls the agent; see `docs/setup/file-based-dispatch.md`):

   ```
   # write N brief files (one per task) ...
   Agent(description: "Implement <task1>", subagent_type: "<type1>", prompt: "<pointer to _briefs/<task1>-impl.md>", isolation: "worktree")
   Agent(description: "Implement <task2>", subagent_type: "<type2>", prompt: "<pointer to _briefs/<task2>-impl.md>", isolation: "worktree")
   ...
   ```

   All `Agent()` calls go in a SINGLE message to run in parallel.

5. **Conflict Radar Layer 3 — Contract-first**

   If any task involves changing a contract / event / API shape:

   ```
   Grep contracts/ for related changes in the current uncommitted state
   ```

   - If the contract change is NOT in a separate, prior commit → fail. Apply the contract change first as a standalone commit.
   - Only after the contract is committed → dispatch the downstream tasks (which only consume the contract, never mutate it).

6. **Conflict Radar Layer 4 — Task dependency graph**

   For each task, check `blockedBy`:

   - If any `blockedBy` is NOT `[x] Done` → refuse parallel dispatch; queue the task for later.

7. **If all 4 layers pass — dispatch**

   Emit the single message with N `Agent()` calls.

   After dispatch, await all N responses. Run `/post-delegation-gate` per merged subagent **in sequence** (NOT in parallel — git operations are not safe across parallel reviewers).

8. **If any layer fails — explain and offer serialization**

   ```
   Cannot dispatch in parallel:
     Layer <N> violation: <description>
     Tasks affected: <list>

   Suggested approach:
     1. <serialization plan>
     2. <or: fix the violation by ...>
   ```

## Brief-file template (per parallel agent)

Write this to `docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md`. The
inline `prompt` is just a pointer: *"You are the impl engineer for
`<TASK_ID>` (parallel sprint-S<N> work). Your brief:
`docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md` — read it FIRST, run
your pre-task ritual, report per the output contract in the brief."*

```
You are dispatched as part of sprint S<N> parallel work. Execute the pre-task
ritual MANDATORY (.claude/rules/agent-pre-task-ritual.md).

Task: {{TASK_ID_PREFIX}}-S<N>.<NN> — <title>
Design Doc: docs/designs/sprint-S<N>/D<NNN>-<slug>.md
Worktree: <harness-provided absolute path>
Branch: <harness-provided feature branch>

Your touched-files matrix (Conflict Radar verified — DO NOT touch outside it):
- <file 1>
- <file 2>
...

Co-running agents this dispatch (paths for awareness, do NOT touch theirs):
- {{TASK_ID_PREFIX}}-S<N>.<NN-A> (<subagent_type>) — touches: <files>
- {{TASK_ID_PREFIX}}-S<N>.<NN-B> (<subagent_type>) — touches: <files>

Rules in play for this task: <project rules referenced in the D-doc>.

Read the D-doc fully. Execute the pre-task ritual. Implement per the D-doc
§Approach + §Touched files matrix. Run TDD where the D-doc declares tests.

Output contract (mandatory in your final reply):
- Files touched (path + line count)
- Rules applied (rule-id bullet list)
- Skills invoked (e.g., test-driven-development, verification-before-completion)
- Tests added / updated (file + assertion count)
- Verification evidence (paste actual command output, not summary)
- Branch + commit SHA
- Open issues (flag any deviation from the D-doc)
```

## Sprint cleanup (after fan-in completes)

1. Bump any meta-submodule pointers for touched repos + push.
2. **Backlog sync** — mark each task row done in `docs/project/backlog.md` immediately. Do NOT defer to sprint close.
3. **Live mini-retro per task** — append a 6-field retro to `docs/project/retros/sprint-S<N>-tasks.md` BEFORE moving to the next dispatch.
4. `git worktree remove <path>` for any persistent worktrees you held open.
5. `/retro` at sprint close (aggregates the mini-retros + audits the backlog).

## Failure recovery

| Failure | Action |
|---|---|
| Conflict Radar refuses dispatch | Apply suggested resolution: file split, owner designation, contract-first commit, or serialize |
| Sub-agent reports "need clarification" | Resolve in the main session → re-dispatch only the affected agent |
| One sub-agent fails CI | Other agents proceed; re-dispatch the failed task with the failure output |
| Merge conflict at fan-in (despite PASS) | Conflict Radar missed an overlap; retroactively split or sequence; document in the D-doc §History |
| Sub-agent silent / times out | Worktree intact; `git -C <wt> log` shows partial work; re-dispatch with `Resume from <commit>` |

## When NOT to use this skill

- Single task → use `Agent()` directly (no Conflict Radar overhead).
- Sequential tasks (must wait for previous) → foreground serial `Agent()` calls; not "parallel".
- Read-only exploration → `subagent_type: "Explore"` directly (read-only; can't conflict).
- 1-file bug fix → just do it inline in the main session.

## Related

- `docs/playbooks/parallel-conflict-prevention.md` — the canonical 4-layer guard
- `/post-delegation-gate` — the 6-gate review skill to run per parallel task
- `superpowers:dispatching-parallel-agents` — global skill for setup
- `superpowers:using-git-worktrees` — worktree mechanic
