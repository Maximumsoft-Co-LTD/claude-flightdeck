---
name: assign
description: "Delegate a specific, named task to the right repo / engineer subagent — design-first, with full pre-flight checks and the 6-gate post-delegation review. Use when the user names a specific task ID, e.g. '/assign {{TASK_ID_PREFIX}}-S<N>.<NN>', 'work on TG-NN', 'execute task NN'. Sister skill: /next-task (when the user doesn't name a specific task — the orchestrator picks the next eligible row)."
user_invocable: true
---

# /assign — Delegate a Specific Task (Design-First)

> **Announce on start:** open your reply with "Using /assign to delegate `<TASK_ID>` design-first."

For when the user already knows which task they want to dispatch. Otherwise → `/next-task`.

## Token budget (MANDATORY)

- **All scan steps ≤1k tokens total.** `Grep` the sprint file for the task row (not full Read); `Read` the Design Doc directly (path is in the row).
- **Read large artifacts lazily** — only when a specific step needs the content. No full `Read` on files ≥200 lines.
- **Do NOT re-read CLAUDE.md** — the harness auto-loads it at session start (both parent AND child subagent).

## Input

`/assign <repo-or-component> <task_id>` — e.g. `/assign backend {{TASK_ID_PREFIX}}-S03.04`

## Repo / Component → Subagent mapping

Define a mapping table for your project (one row per repo or component → the subagent that owns it). Example shape:

| Repo / Component | Subagent |
|---|---|
| `<backend-svc-a>` | `<your backend engineer>` (e.g. `go-hexagonal-engineer` from the go-hex preset) |
| `<backend-svc-b>` | `<your backend engineer>` |
| `<frontend>` | `<your frontend engineer>` (e.g. `frontend-fsd-engineer` from the nextjs-fsd preset) |
| `<pipeline-svc>` | `<your pipeline engineer>` |
| `<infra/k8s>` | `<your platform engineer>` |

## Steps

1. **Parse repo + task ID.** Map repo → directory.
2. **Find the task row (lazy — do not Read full sprint file)**:
   - `Glob` for the active sprint file in `docs/spec/sprints/sprint-*.md`
   - `Grep` for the task ID with `-A 5 -B 1` → extract row + context
   - `Read` with `limit: 80` only if the Grep didn't resolve it
3. **Check dependencies** — warn / refuse if `blockedBy` is open.
4. **Task Readiness Check**:
   - Determine task type from the title prefix (e.g. `[BE]`, `[FE]`, `[BE+FE]`, `[Infra]`)
   - If FE work and your project uses design references → verify the design / Figma node IDs exist (if missing → **BLOCK**, request design)
5. **Show task details, ask user to confirm.**
6. **Check / create the Design Doc** — at `docs/designs/sprint-S<N>/D<NNN>-<slug>.md`. If missing, dispatch the `design-doc-writer` agent first (via a brief file — write `docs/designs/sprint-S<N>/_briefs/<TASK_ID>-design.md`, dispatch with a short pointer prompt; see `docs/setup/file-based-dispatch.md`), then resume.
7. **Cross-cutting pre-checks** — multi-tenancy / RBAC / contract-first, per the rules that apply to {{PROJECT_NAME}}.
8. **Delegate** — pick the `subagent_type` from `references/repo-to-agent-mapping.md`, then instantiate `references/dispatch-prompt-template.md` with the task ID, type, design-doc path, AC list, touched-files matrix, and test plan (verbatim from the design doc) and **write it to a brief file** `docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md`. Dispatch with the short **pointer prompt** (NOT the full template inline — that stalls the agent; see `docs/setup/file-based-dispatch.md`). The dispatched agent emits a JSON object matching `references/verification-json-schema.md` BEFORE writing code.

   ```
   # 1. write the brief
   Write docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md  <instantiated template>
   # 2. dispatch the pointer
   Agent(subagent_type="<mapped agent>",
         description="impl for <TASK_ID>",
         prompt="You are the impl engineer for <TASK_ID>. Your brief:
                 docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md — read it FIRST,
                 run your pre-task ritual, report per the output contract in the brief.",
         isolation="worktree")
   ```

   If any blocker is detected during Steps 3-7, consult `references/blocked-task-recovery.md` for the recovery path — do NOT silently proceed past a block.

9. **Act on the agent's return status, then run the gates** — the reply leads with `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`. `DONE` → gates. `DONE_WITH_CONCERNS` → read concerns, resolve correctness/scope ones first. `NEEDS_CONTEXT` → add the missing context to the brief + re-dispatch (`SendMessage`). `BLOCKED` → assess (more context / more capable model / split / escalate); never retry the same model unchanged. Then invoke `/post-delegation-gate` which runs all 6 gates (incl. 4a spec-compliance → 4b quality) in order. Do NOT mark Done until every gate passes.
10. **Live mini-retro (per task)** — append a 6-field retro to `docs/spec/retros/sprint-S<N>-tasks.md`: what went well / what didn't / lessons / design compliance verdict / TDD verdict / post-review fixes needed.
11. **Update sprint file + design doc + backlog** — row status, design doc status, backlog row marker. Refresh slim indexes via `/index-refresh`.
12. **Bump the meta submodule pointer** if a nested repo was edited; commit + push.

## Rules

- **NEVER delegate without a Design Doc** — Step 6 is non-negotiable.
- The **Design Doc IS the spec** — the dispatched agent reads and follows it strictly, not as a hint.
- Include **FULL AC + FULL test plan** in the brief file, not summaries (and not inlined in the dispatch `prompt` — the prompt is just a pointer to the brief).
- Tests BEFORE implementation (TDD) is the default — the dispatched agent's pre-task ritual enforces this.
- **The 6-gate post-delegation review is mandatory** — never skip it.
- Sprint file MUST be updated after every task.
