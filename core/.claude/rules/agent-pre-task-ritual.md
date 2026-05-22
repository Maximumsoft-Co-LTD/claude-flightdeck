# Sub-Agent Pre-Task Ritual (MANDATORY)

> Single source of truth. Every specialized agent (`<prefix>-orchestrator`,
> `design-doc-writer`, `senior-tech-lead`, `sprint-retro-author`, plus any
> preset agents like `go-hexagonal-engineer`, `frontend-fsd-engineer`,
> `hexagonal-reviewer`, `kafka-pipeline-engineer`, …) references this
> file in its body and MUST execute the ritual before touching any code
> or producing output.
>
> **Why this exists:** sub-agents don't auto-inherit the main session's
> SessionStart hooks (brain-hot, MEMORY.md, etc.). Without this ritual
> they would forget critical rules — TDD discipline, the 6-gate review,
> the wiring check (L116), LSP-first navigation. The ritual forces
> explicit re-loading.

## The Ritual — execute in order, do not skip

### Step 0 — Read your brief (if the dispatch named one)

If your dispatch prompt references a **brief file** — typically
`docs/designs/sprint-S<N>/_briefs/<TASK_ID>-<role>.md` — **Read it
FIRST, before anything else.** It is your complete, primary task input:
intent, acceptance criteria, context excerpts, constraints, the
reads-first list, and your output contract. The dispatch prompt is kept
deliberately short (a pointer) so an oversized inline prompt can't stall
the dispatch; the real detail is in the brief. Re-Read the brief any
time you need to re-check a detail. See
[`../../docs/setup/file-based-dispatch.md`](../../docs/setup/file-based-dispatch.md).

> If the dispatch did NOT name a brief file (small inline task), skip
> this step and proceed with the inline instructions.

### Step 1 — Repo orientation (Read 3 files)

1. Read the root **`CLAUDE.md`** — orchestrator manual + non-negotiables
   + subagent routing table.
2. Read **`.claude/rules/brain-hot.md`** — the 10 always-apply rules
   (A001-A010) plus cross-cutting lessons (L###) and any project-local
   appendix (A011+).
3. Read the **submodule / sub-area CLAUDE.md** that matches your working
   scope (if one exists). If the project is single-repo, skip — but
   still scan the relevant `docs/` folder for your stack.

> ⚠️ If a sub-area CLAUDE.md is missing, defer to the root CLAUDE.md
> and **report the missing file in your output summary** so the
> orchestrator can scaffold it.

### Step 2 — Rule + lesson scan

4. Read **`.claude/rules/phase-matrix.md`** (type × phase lookup),
   **`.claude/rules/programming-fundamentals.md`** (reflex coding
   rules), and **`.claude/rules/git-workflow.md`** (commit / branch /
   PR reflex). These auto-load on every code-touching task per the
   Phase Matrix — they are non-negotiable for any agent that writes
   or commits code.
5. Read any preset-specific rule files referenced by your role
   (e.g. `hex-boundaries.md` for `go-hexagonal-engineer`, `fsd-layers.md`
   for `frontend-fsd-engineer`). These are non-negotiable for your
   domain.
6. Open **`docs/setup/lesson-trigger-map.md`** — the mechanical mapping
   of "if touching X → apply L###". For every file you plan to read or
   write, mentally tag the applicable rules.
7. In your final report, include an `## Applied Rules` section listing
   the A### / L### rules you actively applied.

### Step 3 — Task file (if a task ID was provided)

8. If invoked with a task ID (e.g. `{{TASK_ID_PREFIX}}-S03.04`), Read the
   task design doc:
   - `docs/designs/sprint-S<N>/D<NNN>-<slug>.md` (active sprint), or
   - `docs/designs/_archive/<sprint>/...` (historical reference only).
9. Confirm: AC list, touched-files matrix, applicable A/L rules,
   dependencies, blockedBy.
10. If the design doc does NOT exist → **STOP.** Defer to the
    `design-doc-writer` agent first (A005 — design-doc-first).
11. If the doc is < 200 lines and the task is non-trivial → emit a
    warning **"Task design may be under-specified"** but proceed.

### Step 4 — Activate required skills (BEFORE writing code)

12. Match task class → invoke the right superpower skill:
    - **Implementation** → `superpowers:test-driven-development`
      (failing test first)
    - **Bug fix** → `superpowers:systematic-debugging` (RCA before fix)
    - **Design / planning** → `superpowers:writing-plans` or
      `superpowers:brainstorming`
    - **All tasks** → `superpowers:verification-before-completion`
      BEFORE claiming done
    - **Multiple independent sub-tasks** →
      `superpowers:dispatching-parallel-agents` + `/dispatch-parallel`
13. Invoke **LSP-first** navigation (A010 / L147):
    - LSP `documentSymbol` + `hover` on key files BEFORE Read/Grep when
      asking *what a symbol IS*
    - Use Grep only for *where a string appears* (configs, YAML, JSON,
      Markdown, cross-language)

### Step 5 — Work isolation (parallel safety)

14. If the invoker provided a worktree path (via
    `Agent(isolation: "worktree")`), confirm `pwd` matches it.
15. Branch from the project's integration base (most projects: `main`;
    some use `dev` — check the root `CLAUDE.md` for the convention).
    `git -C <worktree> checkout -b <type>/<task-id>-<slug>` where
    `<type>` matches the task's Type slot (per `git-workflow.md`
    Rule 1).
16. **Never `cd <dir>` for git work** — always `git -C <dir> ...`.
    `cd` mid-session is a top cause of "wrong-repo commit" mistakes.
17. If working in a meta-repo with submodules: never edit submodule
    files from the meta's working tree. Always operate on the
    submodule's own checkout. `git rev-parse --show-toplevel` from the
    file's directory tells you which repo owns it.

### Step 6 — Deliver

18. **Commit your work** in the relevant repo. Do not skip `git commit`.
    Do not leave changes uncommitted in the worktree.
19. Run `git status -s` and confirm a clean tree before reporting "done".
20. Push the feature branch + open a PR targeting the integration base.
21. **Final output summary MUST include:**
    - **Files touched** — paths + line counts
    - **Rules applied** — bulleted A### / L### list
    - **Skills invoked** — list (e.g. `test-driven-development`,
      `verification-before-completion`)
    - **Tests added / updated** — file paths + assertion counts
    - **Verification evidence** — paste actual `build` + `test` + smoke
      output, not a summary
    - **Open issues** — flags for `senior-tech-lead` / preset reviewer
      post-review
    - **Branch name + commit SHA** — exact, for tracking

## Forbidden actions (will cause review reject)

- ❌ Claim "done" without invoking
  `superpowers:verification-before-completion`
- ❌ Skip Read on `brain-hot.md` or the sub-area CLAUDE.md
- ❌ Use `cd` for git operations (use `git -C`)
- ❌ Commit secrets, `.env`, credential folders, or large binaries
- ❌ Modify files outside your declared touched-files matrix without
  flagging
- ❌ Use `claude -p` — orchestrate via the `Agent` tool from the main
  session instead
- ❌ Push directly to the integration base of a service repo (always
  via PR)
- ❌ Hardcode user-facing strings (always go through i18n / `t()`)
- ❌ Mock the database / external dependencies in integration tests
  (mocks belong in unit tests; integration must hit the real surface)
- ❌ Merge without the 6-gate post-delegation review
  (`docs/playbooks/post-delegation-review.md`)

## Token budget (for sub-agent context economy)

- Read root `CLAUDE.md` + `brain-hot.md` + sub-area `CLAUDE.md` exactly
  **once each** at start
- Do not re-Read files you've already Read in this session — context is
  preserved
- Prefer LSP `documentSymbol` + `hover` over full file Reads (A010 /
  L147)
- For exploration tasks dispatched within your work, spawn `Explore`
  sub-agents — don't burn your own context with broad Greps

## Cleanup

- If your worktree was created by `Agent(isolation: "worktree")` and
  you made changes → leave it; the orchestrator (main session) will
  merge + clean up after PR review.
- If you made NO changes → confirm worktree exit is safe (auto-cleanup
  reclaims disk).
- Update the relevant `docs/spec/sprints/sprint-S<N>.md` row
  immediately after task complete — change `[ ] Not Started` → `[x]
  Done` or `[~] Partial`. Do NOT defer to sprint close.
- Append the **live mini-retro** (A009 / L036) to
  `docs/spec/retros/sprint-S<N>-tasks.md` before reporting back to the
  orchestrator.

## Origin

Synthesized from battle-tested pre-task ritual conventions across
multiple production repos (a rich step-structure merged with clean
multi-repo handling). De-domain-specified for use across projects.
