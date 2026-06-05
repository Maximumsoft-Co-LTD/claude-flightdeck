---
name: next-task
description: "Find the next uncompleted task from the active sprint and dispatch it to the right specialized subagent. Enforces design-first (task MUST have design doc before code) + 6-gate post-delegation review. Use when asked: 'what's next', 'next task', 'continue the sprint', 'pick the next thing', '/next-task', or anytime the user wants the orchestrator to drive forward without naming a specific task. Sister skill: `/assign` (when the user knows the task ID — pass `{{TASK_ID_PREFIX}}-S<N>.<NN>` directly)."
user_invocable: true
---

# /next-task — {{PROJECT_NAME}} sprint orchestrator (design-first)

> **Announce on start:** open your reply with "Using /next-task to pick and dispatch the next sprint task."

Find and execute the next task from the active sprint. Every task requires a Design Doc before implementation (design-first is non-negotiable — clear ports require upfront design).

## Token budget (MANDATORY)

- Steps 1–6 (identify task): ≤15k tokens total. Use Grep + offset/limit; never full-Read files ≥200 lines.
- Step 7 (create design doc): Read `docs/designs/_templates/DESIGN_TEMPLATE.md` ONLY if a fresh design doesn't already exist for this task.
- Step 9 (dispatch): do not re-read CLAUDE.md — the harness auto-loads it; double-loading is waste.

## Steps

1. **Find the active sprint pointer**

   ```
   Grep docs/project/sprints/S<N>/tasks.md for the project row (or the active-sprint marker)
   ```

   Extract: active sprint number, in-flight task ID, branch, last update.

   Fallback: `Grep` `docs/project/backlog-index.md` for the active-sprint marker (e.g. `🚀`) → identify the active sprint pointer.

2. **Find the next un-started task in the sprint file**

   ```
   Read docs/project/sprints/S<N>/tasks.md with limit: 80 (header + task table only)
   Scan for the first row with status [ ] Not Started
   ```

   - If a row is `[B] Blocked`, skip it.
   - If all rows are done → announce sprint complete, suggest `/retro`.
   - **Read the task's `Type:` slot** (feat / fix / refactor / chore / docs / spike / release). If missing, ask the user (default = `feat`).
   - **Look up the type in `.claude/rules/phase-matrix.md`** to determine which phases run / run light / skip for this task. Quote the phase list back to the user before dispatch (e.g. `Type=fix → phases 1, 2⚠, 3, 4 (regression first), 5, 6, 8, 12`).

2b. **Check FOLLOWUPS.md** — concrete scan rules:

   - `Grep docs/project/backlog.md` `## Open` section for **(a)** the task's component path or directory (e.g. `apps/web/features/auth`), **(b)** the design-doc slug (`D<NNN>-<slug>` token), and **(c)** any backlog keyword present in the candidate row's Item cell.
   - **Surface ALL `Priority=high` open rows unconditionally** — even if the keyword grep didn't hit. High-priority follow-ups are always candidates for bundling.
   - For each surfaced row, ask the user: "Open follow-up `F####` looks related — should we bundle it into this task?". Never silently consume a follow-up.
   - Cite scanned IDs in the dispatch summary (e.g. `Follow-ups scanned: F0007, F0012` or `Follow-ups scanned: none matched`).

3. **Verify dependencies**

   For the candidate task, check all `blockedBy:` entries:

   - Are they marked `[x] Done` or `[~] Partial`?
   - If any is open → skip; pick the next candidate.

4. **State-scan (pre-flight grep)**

   ```
   Glob the paths the task is expected to touch
   Grep for existing implementation
   ```

   - If already shipped → mark "Verification Only", skip to Step 11.
   - If partially shipped → revise the task spec to reflect the actual residual scope.

5. **Readiness check**

   | # | Check | Required for |
   |---|---|---|
   | 1 | Design doc at `docs/project/sprints/S<N>/designs/D<NNN>-<slug>.md` | All tasks |
   | 2 | Dependencies marked Done / Partial | All |
   | 3 | Contract update committed if cross-service | Tasks touching event/REST/RPC shape |
   | 4 | Idempotent migration pattern declared | Tasks with persistence schema changes |
   | 5 | Observability instrumentation plan declared | Any new handler / consumer / worker |
   | 6 | Authz/AuthN requirements declared | Any new protected route |

   If any required check is missing → **BLOCK**: print the gap, keep task at `[ ] Not Started`, drop a note `[B] Blocked — <reason>` in the sprint file, skip to next task.

6. **Show the task to user**

   Display: task ID, one-line description, target component(s), AC, readiness result. Ask: "Confirm dispatch? (yes / pick different / write design doc first)".

6b. **Mid-sprint follow-up consumption** — if the user confirmed bundling an open follow-up (from Step 2b) into this dispatch, update the row in `docs/project/backlog.md`:

   - Change its `Status` cell from `open` to `in-progress`.
   - Keep the row in `## Open` for now (it transitions to `## Closed` only at sprint-close `/retro` once status becomes `consumed-by:<task-id>` or `wont-do`).
   - Commit this `FOLLOWUPS.md` edit in the **same commit** as the sprint-file task pickup (single atomic state move).
   - Cite the `F####` ID(s) in the dispatch summary so the audit trail is unambiguous.

7. **If no design doc exists yet, create one**

   ```
   Use docs/designs/_templates/DESIGN_TEMPLATE.md (if absent, scaffold it)
   ```

   Prefer dispatching the `design-doc-writer` agent for this step — it owns the template and the section checklist.

   **Dispatch via a brief file, not a long inline prompt** (oversized prompts stall the agent — see `docs/setup/file-based-dispatch.md`):

   ```
   1. Write docs/project/sprints/S<N>/designs/_briefs/<TASK_ID>-design.md
      <intent, AC, context grep excerpts, constraints, reads-first list, target D-doc path>
   2. Agent(subagent_type="design-doc-writer",
            description="design for <TASK_ID>",
            prompt="You are the design-doc-writer for <TASK_ID>.
                    Your brief: docs/project/sprints/S<N>/designs/_briefs/<TASK_ID>-design.md
                    Read it FIRST, run your pre-task ritual, write the D-doc, report per your output contract.")
   ```

   Sections (mandatory):

   - **Context**: why this task exists, which sprint it belongs to, which rules apply
   - **API / Contract**: request/response shapes; ref the relevant contract file if any
   - **Data Model**: entities + their persistence layout
   - **Use-case Flow**: numbered steps the use-case will take
   - **Ports**: which inbound and outbound interfaces this work adds/extends
   - **Adapter Choices**: transport/persistence — which and why
   - **Migrations**: schema changes, all idempotent
   - **Tests Plan**: unit (use-case w/ mock ports) + integration
   - **Observability Plan**: span names + custom metrics added
   - **Acceptance Criteria**: numbered, testable
   - **References**: spec section, prior D-docs, related tasks

8. **Self-review the design doc**

   - Every AC testable?
   - Use-case flow is I/O-free (no transport / persistence calls in the orchestration)?
   - Ports + adapters declared distinct?
   - Migration is idempotent?
   - Observability span + metric is named?

   Cross-check against the project's local rules file. Iterate until clean.

8b. **Surface design-doc risk + ambiguity before approval** — read THREE sections of the doc in order and bundle every unresolved row into `AskUserQuestion` calls. Do NOT proceed to Step 9 until each is `[x]` resolved.

   **§1.5.2 Knowledge Gaps** (read FIRST — these are blockers):
   - Each `Resolved? = [ ]` row means the design author had no defensible default. The doc should have come back `NEEDS_CONTEXT`; either way BLOCK dispatch.
   - Bundle into `AskUserQuestion` with one question per row (include `What I need to know` + `Why` + `Likely source` + `Impact if I guess wrong` as context). The user may answer directly, or route the question to a human with the context — either way the doc cannot proceed until each gap is filled.
   - After answers land, the design-doc-writer must be re-dispatched (via `SendMessage`) with the resolved knowledge so it can complete the doc body.

   **§1.5.1 Blast Radius** (read SECOND — risk surface):
   - Bundle every `Risk grade = HIGH` row into `AskUserQuestion` (one question per row): "Downstream `<consumer>` is affected by `<how>` — proposed mitigation: `<X>`. Approve / require coordination / require mitigation change?"
   - For `MEDIUM` rows, ask the user in one batch: "MEDIUM-risk downstream consumers — heads-up sent (or to be sent) to: `<list>`. OK to proceed?"
   - `LOW` rows are informational — skim, don't prompt.

   **§10. Open Questions / Risks** (read THIRD — decision-tier):
   - `severity = load-bearing` rows: should have been `NEEDS_CONTEXT`. BLOCK and bundle into `AskUserQuestion`.
   - `severity = material` rows: bundle into `AskUserQuestion` (author's default + impact-if-wrong as context). User ratifies or overrides.
   - `severity = cosmetic` rows: one batch prompt "Cosmetic defaults — OK to take them all?".

   **After the user answers each section**, update the doc in-place: flip every touched `Resolved?` to `[x]`, set `Default picked` (or knowledge-gap answer) to the chosen answer, and append a Change Log row per section (`<date> | Resolved §1.5.2 KG #<n>: <decision> | user via /next-task`). Commit this design-doc edit before Step 9 so the impl brief points at a fully-ratified spec.

   If a section is absent or empty, skip it and move to the next. If all three are clean, proceed straight to Step 9.

9. **Dispatch to the right subagent**

   | Task class | Subagent |
   |---|---|
   | Any server-side feature (handler, use-case/service, data access, migration, worker, producer/consumer) | `backend-engineer` |
   | Any client-side feature (page, component, state, form, API call, i18n) | `frontend-engineer` |
   | Infra / deploy (if `k8s-helm` installed) | `k8s-engineer` |
   | Cross-service architectural decision | `senior-tech-lead` |

   The engineers are architecture-agnostic — they read `.claude/rules/code-style.md` + sample the codebase and conform to its real style. A custom preset may add specialized agents; route to those when installed. Full table: `.claude/skills/assign/references/repo-to-agent-mapping.md`.

   **Write the task spec to a brief file, then dispatch with a short pointer prompt** — never paste the full spec into `prompt` (it stalls the agent). Write `docs/project/sprints/S<N>/designs/_briefs/<TASK_ID>-impl.md` from `references/dispatch-prompt-template.md`, then `Agent(subagent_type=..., prompt="<short pointer to the brief>")`. Single foreground dispatch (parallel dispatch only if multiple independent sub-tasks — use `/dispatch-parallel`). Full convention: `docs/setup/file-based-dispatch.md`.

10. **Wait for subagent return; act on its status, then run the 6-gate post-delegation review** (`/post-delegation-gate`)

    The agent's reply leads with a status. Handle it BEFORE the gates:

    | Status | Orchestrator action |
    |---|---|
    | `DONE` | Proceed to the gates. |
    | `DONE_WITH_CONCERNS` | Read the concerns first. If about correctness/scope → resolve (or send back) before gates; if observational → note + proceed. |
    | `NEEDS_CONTEXT` | Supply the missing context (add it to the brief file) and re-dispatch the same agent via `SendMessage`. Don't run gates yet. |
    | `BLOCKED` | Assess: context gap → add context + re-dispatch; needs more reasoning → re-dispatch a more capable model; too large → split the task; plan is wrong → escalate to the user. Never force the same model to retry unchanged. |

    Then run gates in order; any failure → fix loop → re-run that gate.

11. **Close the task**

    - Update the sprint file: change `[ ] Not Started` → `[x] Done` (or `[~] Partial` if scope cut)
    - Update `docs/project/sprints/S<N>/tasks.md` project row (REPLACE, don't append history; move closed prose to `STATUS-archive.md`)
    - Bump any submodule pointer if a nested repo was edited
    - Commit + push

12. **Append the live mini-retro for this task**

    Append a 6-field entry to `docs/project/sprints/S<N>/tasks.md` BEFORE moving to the next dispatch (what went well / what didn't / lessons / verdict).

13. **Decide what's next**

    - If the sprint has more `[ ] Not Started` rows → loop to Step 2.
    - If the sprint is done → suggest `/retro` to capture lessons.
    - If user asked to stop → stop cleanly.

## Common failure modes

- Skipping Step 5 readiness check → design doc missing → subagent has to ask back-and-forth.
- Forgetting Step 11 STATUS update → next session sees stale state.
- Running multiple subagents on overlapping paths → merge conflict (use `/dispatch-parallel` which runs the Conflict Radar 4-layer guard).
- Skipping the 6-gate review → silent failures land on the main branch.

## Related

- `/assign` — sister skill for when the user provides a specific task ID
- `/dispatch-parallel` — when you have 2+ independent tasks
- `/post-delegation-gate` — the 6-gate review skill
- `docs/playbooks/post-delegation-review.md` — canonical gate definition
