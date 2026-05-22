# Zero-Fix Task File Template

> Copy this into `{repo}/.claude/tasks/{TG#}-{slug}.md` before delegating. A complete task file means the agent needs zero back-and-forth to execute.
>
> "Zero-fix" target: the agent commits the implementation, all tests pass, and post-delegation review finds no issues — without you having to send a follow-up message to clarify anything.

```markdown
# Task {TG#}: {Name}

> Sprint: sprint-XX | Design Doc: `docs/designs/sprint-XX/DXXX-{slug}.md` | Status: In Progress

## 1. Context

{Why this task exists. 2–4 sentences. Link to the Discovery Detail if relevant.}

## 2. Design Doc (READ FIRST — FOLLOW STRICTLY)

**Root path:** `{absolute_path}/docs/designs/sprint-XX/DXXX-{slug}.md`

This design doc is the specification. Every AC, API contract, business rule, and test case MUST be implemented exactly. Do not skip or reinterpret.

## 3. Acceptance Criteria

{Paste the full AC list from the design doc. Do NOT link — paste. The agent will not chase a link.}

- AC1: …
- AC2: …
- AC3: …

## 4. Test Plan (TDD — WRITE TESTS FIRST)

| # | Test | Type | File |
|---|---|---|---|
| 1 | … | unit | `src/…_test.{ext}` |
| 2 | … | integration | `tests/…` |
| 3 | … | E2E | `e2e/…` |

## 5. Project Rules Recap (applicable subset)

- **A001** Architectural boundary — domain imports nothing outside domain; layers respect direction
- **A003** Contract-first — interface schema commits BEFORE producer / consumer code
- **A004** Idempotent migration — every migration is `IF NOT EXISTS` / additive
- **A005** Idempotency-Key on write endpoints with side-effects
- **A008** Observability — every new handler emits a span; every worker emits a heartbeat
- **A009** RBAC — protected-route wrapper + policy seed
- **A015** Design-First — D-doc exists for this task (this file references it)
- **L076** Task design under 500 lines = under-specified — make sure the design doc is rich enough before delegating
- **L116** Composition root wired — every new use-case / adapter / route appears in `main`

## 5.1 Estimate-label discipline

Every LoC estimate in §7 (Files You Will Touch) MUST be tagged:

- **`[state-scan]`** — counted via verified ground-state at task-spec author time (e.g. `wc -l src/file` returned 26 just now → "26 lines [state-scan]")
- **`[retro-approximated]`** — carried forward from prior retro/backlog/discovery doc without re-verification at task-spec time (must be upgraded to `[state-scan]` before delegating per `/next-task` Step 4)

When labels mix in the same row, distinguish per number — e.g. `~80-150 code [state-scan] + ~50-100 test-infra [retro-approximated]`. Why: prevents premise drift mid-task.

## 5.2 Default split-shippable for ≥M-scope tasks

Any task ≥M scope OR cascade-risk MUST default to a split-shippable structure with `.Xa` (safe sub-set) + `.Xb` (high-risk sub-set deferred or surgical) fallback baked in at task-spec time. Saves the retroactive amendment work otherwise absorbed mid-sprint.

Cascade-risk tags: hot-path edits to business-critical invariants · cross-track lock claims · type signature changes touching ≥3 callers · CI workflow strict-gate flips.

## 5.3 Dispatch transport fallback

When the design doc / task spec picks a delegation transport that's machine-locked (e.g. `claude -p` single-instance lock from a sibling session), the task spec MUST include an explicit fallback line:

> If `pgrep -f "<lock-pattern>"` ≥ 1 at dispatch-time, pivot to the project's standard Agent-tool dispatch with the same 7-block prompt body. Single-instance locks hold across sibling sessions on the same machine.

## 6. Prior Knowledge / Lessons

{Paste top 2 results from brain / memory search filtered to lessons / decisions if relevant. Include drawer title + 2-line excerpt each.}

## 7. Files You Will Touch

- `{repo}/src/{file1}.{ext}` — {what changes} — ~NN lines [state-scan|retro-approximated]
- `{repo}/src/{file2}.{ext}` — {what changes} — ~NN lines [state-scan|retro-approximated]
- `{repo}/tests/{file}.{ext}` — {what is added} — ~NN lines [state-scan|retro-approximated]

## 8. Completion Checklist

- [ ] Every AC implemented
- [ ] Every test case from section 4 exists and passes
- [ ] Component check passes (the project's build + test command)
- [ ] Wiring verified (new route mounted in `main` / new component in router / new use-case constructed in composition root)
- [ ] **Cross-module predicate audit** — if the task touches a handler module that has a sibling mirror in another module, grep BOTH for the predicate signature being modified · audit any defense-in-depth env/config flags paired with the predicate
- [ ] **Test invariant narrowness check** — for every "field=X in case Y" assertion in tests, distinguish "asserts contract" from "encodes defect"
- [ ] PROGRESS.md updated with outcome + key delta
- [ ] `git add` specific files → `git commit` with conventional message
- [ ] Do NOT push — the orchestrator handles the PR/merge

## 9. Reply Format

When you're done, reply with at most 5 lines:

```
SHA: <commit sha>
Files: <count>
Tests: <added>/<passed>/<failed>
AC: <met>/<total>
Deviations: <one-line, or "none">
```
```
