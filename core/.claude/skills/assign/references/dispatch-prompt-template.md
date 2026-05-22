# Dispatch Prompt — Canonical Template

> Loaded by `/assign` Step 8 and `/next-task` Step 9.
>
> **This block is the BRIEF-FILE content, not the inline `prompt`.**
> Write it (with placeholders substituted) to
> `docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md`, then dispatch the
> agent with the short **pointer prompt** below. Pasting this whole
> template into the `Agent` `prompt` argument is what causes oversized
> prompts to stall — write the file instead. See
> [`docs/setup/file-based-dispatch.md`](../../../../docs/setup/file-based-dispatch.md).

## The pointer prompt (this is the inline `prompt`)

```
You are the impl engineer for <TASK_ID>.

Your brief: docs/designs/sprint-S<N>/_briefs/<TASK_ID>-impl.md
Read it FIRST — it is your complete task input (mandatory reads,
verification JSON, AC, touched-files matrix, test plan, output contract).
The dispatch prompt is short on purpose so it can't stall on an oversized
payload; the detail is in the brief.

Execute your pre-task ritual (.claude/rules/agent-pre-task-ritual.md),
emit the verification JSON BEFORE any code, do the work, and report back
per the output contract in your brief.
```

Dispatch shape:

```
Agent(subagent_type="<mapped agent>",
      description="impl for <TASK_ID>",
      prompt="<the pointer prompt above>",
      isolation="worktree")
```

## The brief-file template (write this to `_briefs/<TASK_ID>-impl.md`)

```
[MANDATORY READS]
- .claude/rules/agent-pre-task-ritual.md
- .claude/rules/brain-hot.md
- .claude/rules/phase-matrix.md
- .claude/rules/programming-fundamentals.md
- .claude/rules/git-workflow.md
- docs/designs/sprint-S<N>/D<NNN>-<slug>.md
- <any preset-specific rules: hex-boundaries.md, fsd-layers.md, etc.>

[VERIFICATION]
Before writing any code, emit a JSON object with this exact shape:
{
  "task_id": "<TASK_ID>",
  "type": "feat | fix | refactor | chore | docs | spike | release",
  "phase_list": [<phases from the phase matrix row for this type>],
  "files_will_touch": ["<path1>", "<path2>", ...],
  "design_doc_read": true,
  "applicable_rules": ["A001", "A002", "L036", ...]
}

This JSON proves you read the design doc + the rules BEFORE writing
code. The orchestrator will reject your work without it.

[TASK]
<task title>
<task description>

Acceptance criteria (from the design doc — verbatim):
- AC1: <copy-paste from design doc>
- AC2: ...

Touched files matrix (from the design doc):
- <file1> — <reason>
- <file2> — <reason>

Test plan (from the design doc):
- <unit test 1>
- <integration test 1>
- ...

[CROSS-CUTTING]
- 6-gate review WILL be run after you return (see post-delegation-gate)
- Live mini-retro WILL be required (append to docs/spec/retros/sprint-S<N>-tasks.md)
- DO NOT push to main; use branch feat/<task-id>-<slug>
- Tests BEFORE implementation (TDD) — A001 non-negotiable for feat/fix/refactor
- Multi-tenancy / RBAC checks if the task touches authn/authz surfaces
- Contract-first if the task touches an event / API contract

[AFTER COMPLETION]
- Stage and commit your work in the worktree
- DO NOT push (the orchestrator pushes after review)
- Update the sprint file row to [~] Partial or [x] Done
  (path: docs/spec/sprints/sprint-S<N>.md)
- Append a 6-field mini-retro to docs/spec/retros/sprint-S<N>-tasks.md:
  • what went well
  • what didn't
  • lessons (L### candidates if any)
  • design compliance verdict (followed-as-written / deviated-with-reason)
  • TDD verdict (red-first / late-tests / no-tests)
  • post-review fixes needed (yes/no + summary)

[OUTPUT CONTRACT]
Your final reply MUST LEAD with a status line, then include the rest:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
  • DONE — work complete, verified green, ready for the gates
  • DONE_WITH_CONCERNS — complete but you have doubts (state them; if about
    correctness/scope they must be resolved before review)
  • NEEDS_CONTEXT — you're missing information that wasn't in the brief
    (say exactly what); the orchestrator will supply it and re-dispatch
  • BLOCKED — you cannot complete (say what you tried + what help you need).
    It is ALWAYS OK to stop and say "this is too hard" — bad work is worse
    than no work; you will not be penalised for escalating.
- Files touched (path + line count)
- Rules applied (A### / L### list)
- Skills invoked (e.g., test-driven-development, verification-before-completion)
- Tests added / updated (file paths + assertion counts)
- Verification evidence (actual build + test command output, not summary)
- Branch + commit SHA
- Open issues (anything to flag to the senior-tech-lead / preset reviewer)
```

## Worked example 1 — `feat` task

```
[MANDATORY READS]
- .claude/rules/agent-pre-task-ritual.md
- .claude/rules/brain-hot.md
- .claude/rules/phase-matrix.md
- .claude/rules/programming-fundamentals.md
- .claude/rules/git-workflow.md
- docs/designs/sprint-S04/D012-add-tenant-invites.md
- .claude/rules/hex-boundaries.md

[VERIFICATION]
Before writing any code, emit a JSON object with this exact shape:
{
  "task_id": "TG-S04.12",
  "type": "feat",
  "phase_list": [1, 2, 3, 4, 5, 6, "7 (auth-trigger)", 8, 10, 11, 12],
  "files_will_touch": [
    "internal/domain/tenant/invite.go",
    "internal/app/tenant/create_invite.go",
    "internal/app/tenant/create_invite_test.go",
    "internal/adapter/repo/postgres/invite_repo.go",
    "internal/adapter/http/tenant_handler.go",
    "migrations/20260520_create_tenant_invites.sql"
  ],
  "design_doc_read": true,
  "applicable_rules": ["A001", "A002", "A005", "L036", "L116"]
}

[TASK]
TG-S04.12 — Add tenant-invite use-case + HTTP endpoint

Acceptance criteria (verbatim from D012):
- AC1: POST /api/tenants/{id}/invites accepts {email, role}; returns 201 + invite_id
- AC2: 403 if caller's tenant != path tenant (cross-tenant guard)
- AC3: 409 if email already invited and pending
- AC4: Migration applied + idempotent

Touched files matrix: <as above>

Test plan (from §Tests of D012):
- Unit: invite domain (3 cases — valid, duplicate, invalid role)
- Unit: use-case (4 cases — success, cross-tenant, duplicate, invalid)
- Integration: handler end-to-end via test container (success + 403 path)

[CROSS-CUTTING]
- 6-gate review (post-delegation-gate) will run after you return
- This touches authn/authz → security review trigger (Phase 7)
- Append mini-retro to docs/spec/retros/sprint-S04-tasks.md
- Branch: feat/TG-S04.12-tenant-invites
- Tests BEFORE implementation — A001 non-negotiable

[AFTER COMPLETION]
- Commit your work (do not push)
- Update sprint-S04.md row TG-S04.12 → [x] Done
- Append the 6-field mini-retro

[OUTPUT CONTRACT]
<standard contract>
```

## Worked example 2 — `fix` task

```
[MANDATORY READS]
- .claude/rules/agent-pre-task-ritual.md
- .claude/rules/brain-hot.md
- .claude/rules/phase-matrix.md
- .claude/rules/programming-fundamentals.md
- .claude/rules/git-workflow.md
- docs/designs/sprint-S04/D015-fix-cascade-delete.md

[VERIFICATION]
{
  "task_id": "TG-S04.15",
  "type": "fix",
  "phase_list": [1, "2⚠ (light)", 3, "4 (regression FIRST)", 5, 6, 8, "10⚠", 11, 12],
  "files_will_touch": [
    "internal/app/tenant/delete_test.go",       # regression test (commits first)
    "internal/app/tenant/delete.go"
  ],
  "design_doc_read": true,
  "applicable_rules": ["A001", "A002", "A005"]
}

[TASK]
TG-S04.15 — Fix: cascade delete leaves orphan invites

Bug summary: deleting a tenant does not delete its pending invites.
Reproduces in staging at the user_id=tnt_abc tenant.

Acceptance criteria (verbatim from D015):
- AC1: Failing regression test commits in its own commit FIRST
- AC2: Tenant delete cascades to tenant_invites (FK or app-level loop)
- AC3: Test now passes; no new dangling rows after delete

[CROSS-CUTTING]
- NO fix without root cause: invoke superpowers:systematic-debugging
  (reproduce → isolate → root cause) BEFORE changing code. A symptom
  patch that doesn't name the root cause will be rejected at the gate.
- 3-strikes: if 3 fix attempts fail, STOP — report BLOCKED and question
  the architecture; do not attempt fix #4.
- Regression test commits BEFORE the fix (so /post-delegation-gate
  can verify "failed pre-fix, passes post-fix")
- 6-gate review will run after you return
- Mini-retro must address: how did this bug ship past A002 zero-bug?

[AFTER COMPLETION]
<as above; type=fix>

[OUTPUT CONTRACT]
<standard contract>
```

## Worked example 3 — `refactor` task

```
[MANDATORY READS]
- .claude/rules/agent-pre-task-ritual.md
- .claude/rules/brain-hot.md
- .claude/rules/phase-matrix.md
- .claude/rules/programming-fundamentals.md
- .claude/rules/git-workflow.md
- docs/designs/sprint-S04/D018-extract-invite-policy.md
- .claude/rules/hex-boundaries.md

[VERIFICATION]
{
  "task_id": "TG-S04.18",
  "type": "refactor",
  "phase_list": [1, "2⚠ (behavior-equiv note)", 3, "4 (behavior-equiv check — no new behavior tests)", 5, 6, 8, "10⚠", 11, 12],
  "files_will_touch": [
    "internal/domain/tenant/invite_policy.go",    # NEW — extracted
    "internal/app/tenant/create_invite.go",       # now calls policy
    "internal/app/tenant/create_invite_test.go"   # unchanged behaviors
  ],
  "design_doc_read": true,
  "applicable_rules": ["A002", "A005", "L036"]
}

[TASK]
TG-S04.18 — Refactor: extract invite-validation policy from use-case

Goal: move duplicate-detection + role-validation rules out of
create_invite use-case into a domain-level InvitePolicy. No
user-visible behavior change.

Acceptance criteria (verbatim from D018):
- AC1: Existing test suite passes UNCHANGED (no new behavior tests)
- AC2: InvitePolicy is the single source of truth for invite rules
- AC3: D018 §Behavior-equivalence note attached + design doc updated

[CROSS-CUTTING]
- This is type=refactor — DO NOT add new behavior tests
- Behavior-equivalence: every existing test must pass without
  modification
- If you need to modify a test, that's a signal you're changing
  behavior — STOP and re-tag as feat or fix

[AFTER COMPLETION]
<as above; type=refactor>

[OUTPUT CONTRACT]
<standard contract>
```

## Substitution checklist (before writing the brief file)

When the orchestrator instantiates this template into the brief file,
every `<...>` placeholder MUST be replaced with a concrete value from
the task row + design doc. The orchestrator does NOT write a brief with
unresolved placeholders — that breaks the subagent's pre-task ritual.

- [ ] `<TASK_ID>` — exact ID from the sprint row
- [ ] `<N>` — sprint number
- [ ] `<NNN>` — design doc number
- [ ] `<slug>` — kebab-case task slug
- [ ] `<task title>` — exact title from the sprint row
- [ ] `<task description>` — copy from the design doc
- [ ] AC list — verbatim from the design doc
- [ ] Touched files matrix — verbatim from the design doc
- [ ] Test plan — verbatim from the design doc
- [ ] Type — from the sprint row's `Type:` slot
- [ ] phase_list — from the phase-matrix row matching the type

## See also

- `repo-to-agent-mapping.md` — pick the right `subagent_type`
- `blocked-task-recovery.md` — what to do if the design doc is partial
  or `blockedBy` isn't done
- `verification-json-schema.md` — strict schema for the verification
  object
