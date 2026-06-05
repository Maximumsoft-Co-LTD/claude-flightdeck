# Delegation Checklist

> Run through this list every time you delegate a task via `Agent` (foreground), `Agent` + `run_in_background: true`, or `/work` (parallel fanout). Missing any item = zero-fix delegation broken.

## Pre-Delegation

- [ ] Brain / memory pre-search done (project tag, task keywords) — top 2 hits pasted into the task file
- [ ] Design doc exists at `docs/project/sprints/XX/designs/DXXX-{slug}.md` with the full AC section
- [ ] Sprint file row exists and references the design doc path
- [ ] Repo-local task file exists at `{repo}/.claude/tasks/{TG#}-{slug}.md` (or the project's task convention)
- [ ] Task file pastes the full AC and test plan (NOT just a link)
- [ ] Task file recaps the relevant A-rules (project-local rules that apply to this kind of work)
- [ ] Task file includes a Prior Knowledge / Lessons section
- [ ] Agent definition file exists at `.claude/agents/{agent-name}.md`
- [ ] Feature branch created: `git -C {repo} checkout -b feature/{{TASK_ID_PREFIX}}-XX-{slug}` (from the integration baseline branch, typically `dev`)

## Delegation Call — 7-Block Prompt Pattern (MANDATORY)

Every delegation prompt MUST include all 7 blocks below. Skipping blocks 1–3 (Context files / Verification JSON / numbered Task steps) is the most common failure mode — the agent skims the task file and hallucinates. The Verification JSON is the cheapest protection (one JSON print commits the agent to actually having read before coding).

```text
Agent(
  subagent_type: "{{AGENT_PREFIX}}-backend",  // or another specialized type
  prompt: '''
1. Read .claude/rules/agent-pre-task-ritual.md (the shared ritual)
2. Read .claude/rules/brain-hot.md (always-apply rules)
3. Read docs/setup/lesson-trigger-map.md (file → rule)
4. Read docs/project/sprints/XX/designs/{DXXX}.md (design doc — specification)
5. Read .claude/tasks/{TG#}-{slug}.md (task spec — FOLLOW EVERY LINE)

[VERIFICATION — output this JSON before any code]
{"ritual_read": true, "brain_hot_read": true, "trigger_map_read": true, "design_doc_read": true, "task_file_read": true, "key_points": [...], "will_write_tests_first": true}

[TASK]
Execute task from .claude/tasks/{TG#}-{slug}.md:
1. <numbered step>
2. <numbered step>
...

[KEY PATTERNS — follow existing code exactly]
- <file>: follow <Existing fn> pattern  (prevent reinvention)
- <file>: follow <Existing fn> pattern

[HARD CONSTRAINTS]
- <scope-lock, security, type rules, project rules as applicable>

[AFTER COMPLETION]
- Build + test must pass (project-specific commands listed in CLAUDE.md)
- Update sprint-XX.md row to [x] Done YYYY-MM-DD
- Stage + commit with message: "<type>(<scope>): <msg> ({TG#})"
- Do NOT push
- Reply with <3-line REPLY FORMAT from task file §5>
  ''',
)
```

### The 7 Blocks (and why each exists)

| # | Block | Purpose | Failure mode if skipped |
|---|---|---|---|
| 1 | **Context files** | Point at ritual + rules + design doc + task by path | Agent skims; misses A-rules + design constraints |
| 2 | **Verification JSON** | Force agent to confirm reads + key points | Agent generates code without actually reading |
| 3 | **Task steps** | Numbered imperative list | Agent writes arbitrary scope |
| 4 | **Key patterns** | Specific files + patterns to copy | Agent reinvents existing helpers |
| 5 | **Hard constraints** | Rules that CANNOT be violated | Scope creep, security holes |
| 6 | **After-completion gates** | build/test/commit format | Agent skips commit |
| 7 | **Report format** | Output contract for the orchestrator | Hard to verify what happened |

Shortened "READ X THEN EXECUTE" prompts are BANNED — they skip blocks 1–5.

**Task file + design doc separation**:
- **Task file** = imperative "do these steps" (action-oriented)
- **Design doc** = specification "why and what" (reference-oriented)
- Agent reads BOTH. Task file copies the critical AC + test plan inline so the agent has everything without cross-referencing, but the prompt still cites the design doc path so the agent can verify its interpretation.

## Post-Delegation

- [ ] `git -C {repo} diff HEAD --stat` — not empty (verification — agent ran but didn't actually commit will fail here)
- [ ] Every file changed is in the design doc's file list (or justified as an incidental support change)
- [ ] Every AC in the design doc has a matching implementation + test
- [ ] Build + test passes
- [ ] Wiring verified — new symbol / route / handler is referenced from the composition root / app bootstrap
- [ ] Smoke test passes — `/verify-dev` or the targeted subset
- [ ] Sprint file row status updated (`[x]` / `[~]`)
- [ ] Per-task retro appended to `docs/project/sprints/XX/tasks.md`
- [ ] Commit exists with conventional-commit message (agent should have made one; if not, make it yourself)
- [ ] Any new lessons saved to brain / memory
- [ ] Any new architectural decisions saved to brain / memory

## Common Pitfalls (lessons pre-learned)

| Symptom | Root cause | Fix |
|---|---|---|
| Agent returns with green tests but no commit | Agent skips `git commit` step | Commit yourself after verifying diff |
| Build passes locally but server 500s | New route not mounted in app bootstrap | Grep for the route registration, wire it |
| Tests pass but a numerical / business invariant is off | Project invariant rule violated — no simulation / verification run | Run the simulation / verification target, reject if outside tolerance |
| Frontend renders but data doesn't update | Null guard missing on response | Add `?? []` / `?? 0` guards |
| Shared / generated artifact changed but no codegen run | Contract changed; codegen not re-run | Re-run codegen; commit alongside |
