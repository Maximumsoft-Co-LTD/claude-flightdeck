# Workflow Rules (Mandatory)

> Extracted from root `CLAUDE.md` to keep it slim.
> Reference when writing a Design Doc, running Post-Delegation Review, or verifying Definition of Done.

## Token hygiene & Index discipline (L153 + L154)

- **L153 — `/clear` between skill invocations**: before `/next-task` if prior turn ran `/progress` or `/retro`; cross-skill sprint+backlog Reads stack ~15 K of pollution.
- **L154 — Index-first for sprint/backlog/design-doc creation**: New `sprint-XX.md` requires sibling `sprint-XX-index.md`; new `docs/designs/sprint-XX/` requires `INDEX.md`; `backlog.md` has slim `backlog-index.md`. Skills that mutate these files refresh the index same-commit. See `docs/setup/index-discipline.md` + run `/index-refresh`.

## Visible Task Tracking (TaskCreate/TaskUpdate) — MANDATORY

> **Every multi-step work session needs a visible task list on the CLI status bar.**

**Session Start:**
1. Run `TaskList` — if empty and work has 2+ steps → create tasks
2. `/next-task`: 1 task per phase (Design Doc → Delegate → Review → Retro)
3. `/deploy`: 1 task per phase (Pre-flight → CI → Deploy → Health → Sign-off)
4. `/retro`: 1 task per step (Read data → User input → Write retro → Fix actions → Brain update)
5. Ad-hoc work: create tasks per plan steps

**During Work:**
- `TaskUpdate` → `in_progress` before starting each task
- `TaskUpdate` → `completed` after finishing each task
- New tasks emerge → `TaskCreate` adds them

**Naming:** `S{sprint}.{task} — {name}` | `Deploy P{N} — {phase}` | imperative verb + object

**Anti-patterns:**
- Creating a task for a single-step request
- More than 15 tasks at once — batch into logical groups
- Forgetting to mark completed — stale tasks confuse the next session

## Retro by Task (L036) — MANDATORY

> **After Post-Delegation Review passes, write a mini retro immediately** — before context is cleared.

```
Per task group (after review + smoke test):
  1. Compliance check passed
  2. Write mini retro → append to docs/project/retros/sprint-XX-tasks.md
     - What Happened, Issues, Fixes, Lessons, Verdict
  3. Mark task done in sprint file
  4. **Backlog Sync (L087):** update backlog.md status immediately
     - done → `done S##`
     - already-done discovery → `done (L049 S## — reason)`

End of sprint: /retro reads sprint-XX-tasks.md → aggregates into full retro
  + **Final Backlog Audit:** grep backlog.md for items in this sprint → MUST be 0 mismatch
```

**Why:** context vanishes after a task finishes — if not captured live, the sprint retro is missing the load-bearing detail.
**No need to ask the user** — auto-write after every review.
**File:** `docs/project/retros/sprint-XX-tasks.md` (1 file per sprint, append per task)

## E2E-Per-Task Rule (L021) — MANDATORY when project has E2E

> **Do NOT defer E2E runs to the end of the sprint** — every task group that has UI or API must run its E2E before marking done.

```
Per task group:
  1. Implement feature
  2. Unit tests pass
  3. Write E2E spec (if not yet present)
  4. RUN E2E spec → must pass before marking done   ← non-negotiable
  5. Mark done

End of sprint: integration regression only.
```

**There is no longer a separate "E2E task"** — E2E is part of every task's Definition of Done.

## E2E Selector Contract (L020) — MANDATORY when project has UI + E2E

> **Before starting a task that has both UI + E2E**, create or update the selector contract first.

```
docs/contracts/e2e-selectors-sprint-XX.md
```
- List every selector (e.g. `data-testid`) E2E will use, BEFORE Frontend implements
- Frontend agent and E2E agent both read this file before writing code
- Convention: `noun-first-kebab-case` — `new-page-btn`, `approve-btn`, `page-content`

## Design-First Development — MANDATORY

Every non-trivial task must have a **Design Doc** before implementation:

```
Tech Lead (Root PM):
  0. **Branch Setup (Auto):**
     a. cd {repo} && git checkout dev && git pull origin dev
     b. git checkout -b feature/{{TASK_ID_PREFIX}}-{sprint}.{task}-{short-desc}
     c. Agent works on this feature branch
  1. Create Design Doc from template (docs/designs/_templates/)
     - Root: docs/designs/sprint-XX/DXXX-name.md (overview + contract)
     - Per-repo: {repo}/docs/designs/sprint-XX/DXXX-name.md (detail)
  1.5. Run Design Review Checklist (docs/designs/_templates/DESIGN_REVIEW_CHECKLIST.md)
     - Check every item: API contract, Routes, Menu, RBAC, E2E selectors, Side-effects,
       Component Spec, Interactive Behavior Map, User Journey
     - **API↔UI Coverage:** every write endpoint must have a frontend UI spec referencing it
     - **Permission-Based Access:** every access check uses a permission key, not a hard-coded role
     - If checklist fails → fix design first
  2. Tech Lead self-review & auto-approve (no user gate)
  2.5. **Verify 3-Tier Sync (MANDATORY before approve)**
     - Open Root Doc + Repo Doc + Task File side-by-side
     - Types match 100% (field name, type, optional/required)
     - Repo Doc has all sections from Root (S1, S2.5-S2.8, S3, S6, S8, S9, S10)
     - API endpoints match (method, path, request, response, errors)
     - RBAC matrix + selector map + AC match
     - If not in sync → fix before approve
  3. Delegate to repo agent with design-doc path
     - Agent must work on the feature branch from step 0

User confirms only the TASK choice — not the design.

Repo Agent:
  1. Read its repo's Design Doc
  2. Write tests first (TDD)
  3. Implement until tests pass
  4. Update task status in the repo design doc
  5. Report back to root (agent does NOT commit/push — Root PM handles git)

Root PM (Post-Delegation Review — 6-gate, MANDATORY):
  Show the review as a PASS/FAIL table per step + flag deviations.
  0. **De-sloppify**: remove dead code, debug prints, commented-out code, non-business tests; re-run tests.
  1. **Verify Files**: `ls` files changed → match task file "Files to change"?
  2. **Verify Types/Contracts**: types, signatures, API params match design?
  2.5. **Verify Route Names**: grep router.push usage → must exist in router + match spec
  2.6. **Verify i18n Keys**: grep `t('...')` → must exist in every language file
  2.7. **Verify Store Wiring**: grep store method calls → must exist in store
  2.8. **Verify Global Singletons**: framework-wide singletons (e.g. dialog/toast hosts) only at the root layout
  2.9. **Verify API↔UI Coverage**: every new service method has at least one component import
  3. **Verify Behavior**: every interactive element has a handler? selector matches contract?
  4. **Verify UX States**: loading / empty / error / success — all 4?
  5. **Build + Test (Auto-Fix Loop — max 2 attempts):**
     a. Run the project's build + test command
     b. PASS → step 6 | FAIL → delegate fix → re-run (attempt 2) → still FAIL → manual intervention
  5.5. **Browser Smoke Test (frontend only — MANDATORY, no skip):**
     **build pass + test pass != UI works — always open in a real browser**
     Evidence: screenshot or table-row entry per item
     Checklist:
       a. URL loads — no 404 / blank
       b. No raw i18n keys visible
       c. Create/Add navigates correctly
       d. Row click navigates to detail
       e. Back/Cancel returns to previous page
       f. Delete shows confirm dialog
       g. Browser console — no red errors
       h. **Cross-role:** if RBAC was touched → also log in as non-admin → inspect sidebar
  6. **Cross-reference AC**: open repo design doc → check each AC → mark done/fail
  7. If FAIL → delegate fix task before mark done
  8. **Retro by Task**: append to `docs/project/retros/sprint-XX-tasks.md`
     - Every claim must be evidence-based (count, don't estimate)
  9. Update sprint status + design doc tasks
  10. **Backlog Sync**: update `docs/project/backlog.md` immediately
  11. **Commit + PR (Auto):**
     a. cd {repo} (already on the feature branch)
     b. git add -A && git commit -m "feat(module): description (S##.#)"
     c. git push -u origin feature/{{TASK_ID_PREFIX}}-{sprint}.{task}-{desc}
     d. Create PR → dev
     e. CI pass → merge PR
     f. After the last task of the sprint (or at a batch checkpoint):
        Create PR dev → main with UAT Checklist
  12. **Documentation Update (before PR to main):**
     > **Docs are part of the deliverable** — a feature without docs is a feature that is not done.
  13. **UAT Verification (MANDATORY after merging to main):**
     a. Automated health/readiness check
     b. Browser smoke test
     c. Doc verification — pages updated, screenshots current
     d. Sign-off report
     e. If FAIL → fix → re-verify; if PASS → ready for production tag
```

## Frontend Behavioral Quality (P012) — MANDATORY when project has UI

> **Every UI task needs a Behavior Map + User Journey** — never ship a button that does nothing when clicked.

Design Doc must include:
- **S2.7** Interactive Behavior Map — every button/link: Trigger → Action → Target → Feedback
- **S2.8** User Journey — step-by-step flow + error flows + back/forward/refresh behavior

Frontend implementation in **4 Phases**:
1. Route & Navigation (create route + empty page, test navigation)
2. API Integration (create service + store, test API call)
3. UI Components (create UI, every button has a handler per Behavior Map)
4. Behavioral Verification (open browser, click every button, walk the journey)

**Anti-patterns:**
- Button without an `@click` / `onClick` handler, or handler is an empty function
- Navigate without checking dirty state (unsaved changes)
- Delete without a confirmation dialog
- API error → silent fail (must show toast / retry)
- One mega-prompt that asks the agent to "do all the frontend" — must split into 4 phases

## 3-Tier Documentation (L033 + L035 — MANDATORY)

> **Every non-trivial task has 3 levels of documentation that stay in sync.**

```
1. Root Design Doc: docs/designs/sprint-XX/DXXX-name.md
   → Source of truth, full spec, overview + cross-repo contract

2. Repo Design Doc: {repo}/docs/designs/sprint-XX/DXXX-name.md
   → Agent READS THIS FIRST — MUST COPY verbatim from Root: S1, S2.5-S2.8, S3, S6, S8, S9, S10
   → PLUS repo-specific implementation contracts
   → Never summarize, abridge, or reformat (L035)

3. Task File: {repo}/.claude/tasks/X.X-name.md
   → Self-contained execution instructions — MUST have: API contract (full), types (full),
     component specs, behavior map, selector map, phased steps, Definition of Done
```

**Anti-patterns:** Task file containing only "see root design doc" | Repo doc missing behavioral spec | Type mismatch across docs | Task file missing route names or i18n key list | Agent editing files outside scope

**Verify Sync Checklist:**
- [ ] Types match 100%
- [ ] API endpoints match (method, path, request, response, errors)
- [ ] RBAC matrix + selector map + AC match
- [ ] Route names match across Root + Repo + Task + router config
- [ ] i18n key list matches across Root + Repo + Task

## Context Bridge — PROGRESS.md (L040)

> **Every repo has a PROGRESS.md that agents read/write every dispatch** — bridges context across Agent-tool calls.

Location: `{repo}/PROGRESS.md` (git-ignored, local only)

Agent must:
1. Read PROGRESS.md before starting (if it exists)
2. Write an update after finishing:
   - Task finished + files changed
   - Blockers / issues encountered
   - Functions / patterns created (so the next call can reuse them)
   - Learnings (e.g., "framework X needs config Y for use case Z")
3. Root PM reads PROGRESS.md as part of Post-Delegation Review

```
Format:
  ## Sprint XX Progress
  ### [timestamp] Task X.X — name
  - Status: done/in-progress/blocked
  - Files: list of changed files
  - Notes: important discoveries
  - Reusable: functions/patterns created
```

**Delegation Prompt Template:**
```
IMPORTANT: You MUST be on branch '{expected_branch}'.
Verify: run `git branch --show-current` — if NOT '{expected_branch}', STOP and report.
Do NOT switch branches or push. Just implement the task and leave changes uncommitted — Root PM handles git.

Read these files FIRST before writing any code:
1. {repo}/PROGRESS.md                              ← context from previous tasks
2. {repo}/docs/designs/sprint-XX/DXXX-name.md      ← repo design doc
3. {repo}/.claude/tasks/X.X-name.md                 ← task file (execute this)
Then follow all phases in the task file. Update PROGRESS.md when done.
```

## Resume Context — MANDATORY

> **Every new conversation:** read your repo-state summary file → understand the state of every repo before working.

```
1. Scan git state of every repo → write to BRANCHES.md (or equivalent)
2. Read BRANCHES.md → which repo is on which branch, which task, how many uncommitted files
3. Action items: "needs PR", "uncommitted on main", "stale branch"
4. Use together with PROGRESS.md — BRANCHES.md = branch state, PROGRESS.md = task content
```

**Prevents:** context loss after session interrupt, working on the wrong branch, forgotten pending PRs.

## API↔UI Coverage Audit — periodic

> **Every ~10 sprints** audit that backend endpoints have frontend UI coverage.

```
1. grep backend routes → list every endpoint
2. grep frontend service imports → list every service method called
3. cross-reference: endpoint with no UI → file as backlog item
4. service method with no caller → flag as incomplete feature
```

## Discovery-First Requirement Gathering — MANDATORY

> **Every feature passes structured discovery before entering the backlog.**

Pipeline: `/discover` → detail file → `/discover refine` → `/discover review` → `/promote` (gated) → backlog → sprint

**Requirement Dimensions** (kept in `docs/project/ideas/D###-slug.md`):
1. Problem/Opportunity 2. User Stories 3. Acceptance Criteria 4. User Scenarios
5. UI/UX Notes 6. Technical Constraints 7. Business Context 8. Dependencies 9. Open Questions

**Definition of Ready (gate before promote):**
- Problem stated + ≥1 User Story + ≥3 AC + Dependencies + No blocking questions + Complexity estimate + No duplicates

**Complexity-Scaled Questioning:**
| Tier | Dimensions required | Questions |
|------|--------------------|-----------|
| trivial/small | User Story + AC + Business Context + Dependencies | 5-8 |
| medium | + Scenarios + Technical + UI/UX Notes | 8-12 |
| large/XL | + Sub-feature breakdown + Risk + Cross-repo mapping | 12-15 |

## Feature Development — Complexity Tiers

Choose tier BEFORE starting work each time:

| Tier | Scope | Workflow | Docs Required |
|------|-------|---------|---------------|
| **trivial** | fix typo, rename, 1-2 files | implement → test → verify | No Design Doc |
| **small** | add a filter, fix UI logic, 3-5 files | Light Design → test → code → verify | Light Template only |
| **medium** | CRUD feature, new page, 6-15 files | Full Design → TDD → code → E2E → review | 3-Tier Docs |
| **large** | new module, cross-repo, 15+ files | Full Design → research → plan → implement → review → final review | 3-Tier Docs + reviewer |

**Core principle:** Design-First → Test-First → Code
- Always Design-Doc before implementation
- Write tests before code (TDD)
- Lay the API contract before implementation
- Seed data needs FK / relationship coverage before tests
- curl-verify response shape before writing frontend

## Bug Fix + Evidence-Based Investigation

> **Do not fix from code-reading alone** — always have runtime evidence first.

1. **Reproduce with Evidence** — see the bug with your own eyes + capture evidence (curl output, error log, observability dashboard panel). Do not fix if you cannot reproduce.
2. **Root Cause with Data-Flow Tracing** — trace symptom → handler → service → repo → store. Every hypothesis needs evidence. Code can look correct and still misbehave at runtime.
3. **Fix** — fix only the root cause; do not refactor at the same time.
4. **Verify** — runtime-verify the fix + regression test passes.
5. **Checklist Trace-Back:**
   - Where SHOULD this bug have been caught? (Design Review / Post-Delegation / DoD / Task File)
   - If a rule exists already → why did it slip? move / strengthen the rule to catch it earlier
   - If no rule exists → add a checklist item
   - Record trace-back in the retro file as a row: `Bug | Root Cause | Should Catch At | Rule Exists? | Action Taken`

## Definition of Done (do not merge / commit if any unchecked)

**Backend / Data:**
- [ ] API endpoints return correct shape — runtime verified
- [ ] Frontend-backend contract in sync (computed fields, optional fields)
- [ ] Role names in frontend match backend DB role names
- [ ] All DB fields have real values, relationships valid
- [ ] Seed script: parents before children
- [ ] Migrations applied and verified
- [ ] Smoke test: new endpoints not 500, field names match frontend / E2E

**Tests:**
- [ ] Unit tests pass
- [ ] RBAC: cross-role integration tests (access + no-access)
- [ ] E2E: happy path + RBAC negative — actually run, not just written
- [ ] selectors match the selector contract

**Frontend Quality (when applicable):**
- [ ] Route registry updated
- [ ] Layout discipline: pages do not import Layout; root layout handles it
- [ ] i18n: every component uses the t() helper; every string runs through it
- [ ] No double base-URL: services use the centralized api wrapper
- [ ] Null guard on list assignments and on `.map()` / iteration
- [ ] Menu discoverable: 3 places match (menu config + layout paths + i18n)
- [ ] Permission checks use the permission helper; no hard-coded roles
- [ ] **API↔UI Coverage:** every new/changed service method has a component import

**Behavioral:**
- [ ] Every button has a response on click — no dead buttons
- [ ] Back navigation returns to the right page
- [ ] User journey complete per design + error flows show feedback
- [ ] Frontend implementation went through the 4 phases (Route → API → UI → Verify)

**Process:**
- [ ] Complexity tier chosen before design
- [ ] 3-Tier Docs in sync (Root + Repo + Task)
- [ ] Post-Delegation Review done
- [ ] Retro by Task written
- [ ] No stub without a backlog row
- [ ] PROGRESS.md updated
- [ ] Agent scope respected (no edits outside scope)
- [ ] No stale processes
- [ ] **Backlog synced**: `backlog.md` matches sprint file — no items "done" in the sprint but "new" in backlog
- [ ] **Documentation updated**: no page outdated, sprint features have docs
- [ ] **UAT verified**: sign-off report APPROVED

---

## Delegation v2 — Agent tool + Specialized Sub-agents

> **Replaces the deprecated `claude -p` invocation pattern.**

### Available specialized sub-agents

| Agent type | Repo scope | When to use |
|---|---|---|
| `{{AGENT_PREFIX}}-backend` | backend repo | Server-side endpoint, RBAC, message handling, migration, integration test |
| `{{AGENT_PREFIX}}-frontend` | frontend repo | Page, component, store, i18n, E2E selectors |
| `{{AGENT_PREFIX}}-infra` | infra / k8s / helm repo | Manifests, CI workflows, secrets |
| `design-doc-writer` | root (orchestrator) | Author Design Doc ≥500 lines per task; AC scan; LSP-verify types |
| `pm-orchestrator` | root | Plan breakdown from spec; cross-repo coordination |
| `senior-tech-lead` | root | Post-delegation review; lesson-application audit |

Definition source: `.claude/agents/<name>.md` — each agent has a frontmatter + body that auto-loads via the Agent tool.

### Dispatch tools (Agent tool, NOT `claude -p`)

| Tool | When to use |
|---|---|
| `Agent` (single dispatch) | One task → one specialized sub-agent. Use `/assign` skill. |
| `Agent` with `run_in_background: true` | Long-running impl (>10 min) — main agent continues, harness notifies on completion. |
| `dispatch-parallel` skill | 2+ independent tasks → Conflict Radar + EnterWorktree per agent + parallel Agent calls in a single message |
| `superpowers:subagent-driven-development` | Sequential plan execution (current-session, stacked dependencies) |

**Forbidden:** `claude -p`, ad-hoc shell scripts for delegation. Route new work through the Agent tool.

### Sub-agent pre-task ritual (HARD ENFORCEMENT — NOT optional)

Every specialized sub-agent has a `## MANDATORY Pre-Task Ritual` section in its definition. Before any code action it MUST:

1. Read `.claude/rules/agent-pre-task-ritual.md` (the shared ritual)
2. Read its scoped sub-repo CLAUDE.md (`backend/CLAUDE.md`, `frontend/CLAUDE.md`, etc.)
3. Read `.claude/rules/brain-hot.md`
4. Read `docs/setup/lesson-trigger-map.md`
5. Read the Design Doc if a task ID was provided
6. Invoke `superpowers:test-driven-development` BEFORE writing impl code
7. Invoke `superpowers:verification-before-completion` BEFORE claiming done
8. Output report MUST contain a `## Lessons Applied` section listing every applied L###

This is the **forcing function** that prevents sub-agents from forgetting CLAUDE.md / skills / lessons. The main agent does NOT re-issue these instructions per dispatch — they're baked into the agent definition.

### Lesson Trigger Map (mechanical lesson application)

`docs/setup/lesson-trigger-map.md` is the single source of truth for "if touching X → apply L###".

- Sub-agents scan it during the pre-task ritual; apply matching lessons mechanically
- `senior-tech-lead` post-review checks the map vs. the agent's `## Lessons Applied` output — catches misses
- When a new lesson is captured → add a trigger row in the SAME PR (otherwise enforcement gap)

### Output Contract per sub-agent

Sub-agent output MUST include:
- Files Touched (with line counts)
- Lessons Applied (L### list with rationale)
- Skills Invoked
- Tests added / updated
- Verification Evidence (paste actual command output, not summary)
- Open Issues / Flags
- Branch + Commit SHA

If any section is missing → post-review fails → re-dispatch with fix instructions.

## Parallel Conflict Prevention (MANDATORY for 2+ concurrent tasks)

> Use `dispatch-parallel` skill. See `docs/setup/integration-branch-strategy.md` for the full lifecycle.

### Pre-flight Conflict Radar

Before dispatching parallel tasks:
1. Extract touched-files matrix from each task's Design Doc (required)
2. Build the cross-task file → tasks map
3. Identify overlap risk per file type:
   - **High-risk shared:** i18n locale files, router/index file, package manifest, layout files
   - **Domain-shared:** stores, services, shared components
   - **Migration numbering:** allocate sequence at sprint planning, record in sprint doc
4. Resolution (in order):
   - Designate single owner per overlapping file
   - Split file by domain (e.g. per-module i18n file)
   - Sequence the tasks (lose parallelism)
5. Verdict per pair: PASS / WARN / FAIL — record in the sprint doc

### Worktree isolation

- Each parallel task → its own worktree via `EnterWorktree`
- Branch from the integration baseline branch (typically `dev`)
- Never `cd <worktree>` — use `git -C <worktree>` for git operations
- After PR merge → `git worktree remove` cleanup

### Integration branch (per sprint)

- Sprint kickoff: create `integration/sprint-XX` from `dev`
- All feature PRs target the integration branch (NOT dev)
- Conflicts resolve in integration (sandbox), not on dev
- After all features merged + senior-tech-lead approves → integration → dev (single merge commit)
- Dev → UAT auto-deploy; UAT validated → dev → main → tag → prod

### Conflict resolution patterns

| Pattern | Resolution |
|---|---|
| Multiple agents add i18n keys | Single i18n owner per sprint; others emit a delta in the PR description |
| Multiple agents add routes | Split into per-module route files |
| Multiple agents add deps | One designated manifest-owner per sprint |
| Multiple agents modify shared component | Conflict Radar must flag at design time; assign single owner OR sequence |
| Multiple agents add migrations | Pre-allocate numbers at sprint planning |

Full playbook: `docs/setup/integration-branch-strategy.md`.

## How sub-agents apply lessons without forgetting (5-layer enforcement)

1. **Agent definition body** — system prompt baked with always-apply lessons + mandatory ritual
2. **Shared pre-task ritual** — `.claude/rules/agent-pre-task-ritual.md` (single source, agent references in body)
3. **Lesson trigger map** — `docs/setup/lesson-trigger-map.md` (mechanical scan, no memory needed)
4. **Verification skill pin** — agent MUST invoke `superpowers:verification-before-completion` before "done"
5. **senior-tech-lead post-review** — checks lessons applied vs. trigger map; catches misses

If a sub-agent skips a layer → that's a process failure, not a knowledge failure. Re-dispatch with the specific skipped step called out.
