# {{PROJECT_NAME}} — Master Index

> **One-page cross-reference matrix.** Where to find every rule,
> skill, agent, playbook, hook, and setup doc. The goal: a senior
> engineer joining the team can locate any artifact in < 30 seconds.
>
> Reading order on day 1:
> 1. [`getting-started-tour.md`](./getting-started-tour.md) (day-in-the-life walkthrough)
> 2. [`../CLAUDE.md`](../CLAUDE.md) (non-negotiables N1-N6)
> 3. [`../.claude/rules/brain-hot.md`](../.claude/rules/brain-hot.md) (A001-A010 + L###)

## The 7 layers — where files actually live

| Layer | Path | What's there |
|---|---|---|
| 1. Root manual | [`../CLAUDE.md`](../CLAUDE.md) | Non-negotiables, dispatch routing table, workflow stage table |
| 2. Auto-loaded rules | [`../.claude/rules/`](../.claude/rules/) | brain-hot, agent-pre-task-ritual, phase-matrix, programming-fundamentals, git-workflow, lsp-first, sub-agent-workflow |
| 3. Specialized agents | [`../.claude/agents/`](../.claude/agents/) | orchestrator, design-doc-writer, senior-tech-lead, sprint-retro-author + preset agents |
| 4. User-invocable skills | [`../.claude/skills/`](../.claude/skills/) | 22 slash-commands driving the workflow |
| 5. Playbooks + setup docs | [`./playbooks/`](./playbooks/) + [`./setup/`](./setup/) | Deep operational documents linked from rules |
| 6. Templates + spec | [`./designs/_templates/`](./designs/_templates/) + [`./project/`](./project/) | Design templates, STATUS, backlog, sprints, retros |
| 7. Memory | [`../.claude/memory/`](../.claude/memory/) or `{{BRAIN_PATH}}` | Cross-sprint lessons, retros, decisions |

Full architecture rationale:
[`../../docs/control-plane-architecture.md`](../../docs/control-plane-architecture.md).

---

## Rules → who enforces them

| Rule | One-line | Enforced by |
|---|---|---|
| **A001** TDD by default | Failing test FIRST | Phase Matrix Phase 4; engineer preset agents; `superpowers:test-driven-development` |
| **A002** Zero-bug discipline | Ships green or doesn't ship | 6-gate review Gate 2 (build+test); `senior-tech-lead`; `pr-review-toolkit:silent-failure-hunter` |
| **A003** Verification before completion | Real build + real test output | 6-gate Gate 2; `superpowers:verification-before-completion` |
| **A004** 6-gate post-delegation review | Every coding agent passes 6 gates | `/post-delegation-gate` skill; `senior-tech-lead`; `pr-review-toolkit:*` |
| **A005** Design-doc-first | D-doc merged before code | `/next-task` + `/assign` skills; `design-doc-writer` agent |
| **A006** Subagent dispatch via `Agent` | Never `claude -p` | `.claude/rules/sub-agent-workflow.md`; all skills |
| **A007** Parallel safety (4-layer) | Path declare, worktree iso, contract-first, task graph | `/dispatch-parallel` Conflict Radar; `docs/playbooks/parallel-conflict-prevention.md` |
| **A008** STATUS+backlog source-of-truth | No deriving from chat | `/progress` skill; `/retro` audit; `docs/setup/index-discipline.md` |
| **A009** Live per-task mini-retro | Append before moving on | `/next-task` Step 7; `/retro --task`; orchestrator's pre-task ritual |
| **A010** LSP-first navigation | Semantic = LSP, text = grep | `.claude/rules/lsp-first.md`; agent pre-task ritual Step 4 |
| **A011+** Project-local | Your A### rules | `.claude/rules/brain-hot.md` "Project-specific rules" section |
| **N1** Architecture boundary | The project's own (learned at onboard) | `.claude/rules/code-style.md`; 6-gate Gate 3 (`senior-tech-lead`) |
| **N2** Contract-first | Contract commit precedes consumers | `docs/playbooks/contract-first.md`; 6-gate Gate 5 |
| **N3** 6-gate review | (= A004) | (see A004) |
| **N4** Parallel conflict prevention | (= A007) | (see A007) |
| **N5** Test-first | (= A001) | (see A001) |
| **N6** Separation of Duties | `PR-APPROVER` trailer for regulated work | `.github/CODEOWNERS`; `docs/setup/separation-of-duties.md` |

## Lessons (L###) that bite often

| Lesson | Trigger | See |
|---|---|---|
| **L020** Selector contract | Any UI + E2E task | D-doc selector map; `/design-review` |
| **L035** Touched-files matrix | Any task dispatched | D-doc; `/dispatch-parallel` Conflict Radar |
| **L036** Live per-task mini-retro | After every task | A009; `/retro --task` |
| **L076** D-doc ≥500L for non-trivial | Pre-impl D-doc | `docs/designs/_templates/DESIGN_TEMPLATE.md` |
| **L087** Backlog sync per-task | Task done | A008; `docs/setup/index-discipline.md` |
| **L101** Evidence-based | Any fix / diagnosis | A003; `superpowers:systematic-debugging` |
| **L116** Composition-root wiring | Post-delegation | 6-gate Gate 5 |
| **L147** LSP-first | All semantic queries | A010; `.claude/rules/lsp-first.md` |
| **L149** AC type-contradiction scan | Pre-D-doc | `design-doc-writer` agent ritual |
| **L156** LSP type verification | Pre-D-doc code paste | `design-doc-writer` agent ritual |
| **L182** Visual fidelity ≠ structural | After FE sprint | `/design-review` |

---

## Skills cheat-sheet (19 slash-commands)

| Skill | When to use | Sister skill | Writes |
|---|---|---|---|
| [`/discover`](../.claude/skills/discover/SKILL.md) | Capture a raw feature idea | `/promote` | `docs/project/ideas/D###-slug.md` |
| [`/promote`](../.claude/skills/promote/SKILL.md) | Graduate discovery → backlog row | `/discover` | `docs/project/backlog.md` row |
| [`/next-task`](../.claude/skills/next-task/SKILL.md) | Pick + dispatch next sprint task | `/assign` | dispatch + 6-gate review |
| [`/assign`](../.claude/skills/assign/SKILL.md) | Dispatch a specific task ID | `/next-task` | dispatch + 6-gate review |
| [`/dispatch-parallel`](../.claude/skills/dispatch-parallel/SKILL.md) | Run 2+ agents in parallel (with Conflict Radar) | `/assign` | N parallel commits |
| [`/tdd`](../.claude/skills/tdd/SKILL.md) | Write an intent-bearing test; legacy → characterization-first | (none) | test files (red → green) |
| [`/post-delegation-gate`](../.claude/skills/post-delegation-gate/SKILL.md) | 6-gate review on a returned agent | (none) | review log on PR |
| [`/design-review`](../.claude/skills/design-review/SKILL.md) | UI fidelity gate after FE sprint | (none) | `docs/project/reviews/sprint-S<N>-design-review.md` |
| [`/security-review`](../.claude/skills/security-review/SKILL.md) | Phase-7 security pass on the diff (+ slopsquatting) | (none) | findings + PASS/BLOCK verdict |
| [`/progress`](../.claude/skills/progress/SKILL.md) | Mid-sprint dashboard (read-only) | (none) | (status print) |
| [`/retro`](../.claude/skills/retro/SKILL.md) | Sprint close + backlog audit | `/ratify-rules` | `docs/project/retros/sprint-S<N>.md` |
| [`/ratify-rules`](../.claude/skills/ratify-rules/SKILL.md) | Land retro `## Candidate A-rules` into `brain-hot.md` (operator-gated) | `/retro` | `brain-hot.md` A011+ · trigger-map row |
| [`/archive`](../.claude/skills/archive/SKILL.md) | Move old sprints to `historical/` | (none) | moves under `docs/project/sprints/historical/` |
| [`/document`](../.claude/skills/document/SKILL.md) | Sync API / contract docs from code | (none) | API doc files |
| [`/index-refresh`](../.claude/skills/index-refresh/SKILL.md) | Refresh slim INDEX files | (none) | INDEX files |
| [`/changelog`](../.claude/skills/changelog/SKILL.md) | Build CHANGELOG.md from git history | (none) | `CHANGELOG.md` |
| [`/deploy-preflight`](../.claude/skills/deploy-preflight/SKILL.md) | Read-only deploy-readiness scan | `/deploy` | (report) |
| [`/deploy`](../.claude/skills/deploy/SKILL.md) | Drive a deployment through 5 phases | `/deploy-preflight` | deploy artifacts |
| [`/recover`](../.claude/skills/recover/SKILL.md) | Undo a partial dispatch / orphan worktree | (none) | (restored state) |

## Agents cheat-sheet (core)

| Agent | When to dispatch | Reads first | Writes to |
|---|---|---|---|
| [`{{AGENT_PREFIX}}-orchestrator`](../.claude/agents/orchestrator.md) | Pick next task; orchestrate sprint phase | `docs/project/STATUS.md` + backlog | dispatch decisions; updates STATUS |
| [`design-doc-writer`](../.claude/agents/design-doc-writer.md) | Author ≥500L zero-fix design doc | task brief + area CLAUDE.md | `docs/designs/sprint-S<N>/D<NNN>-<slug>.md` |
| [`senior-tech-lead`](../.claude/agents/senior-tech-lead.md) | Cross-service / architectural review | task D-doc + relevant CLAUDE.md | review notes on PR |
| [`sprint-retro-author`](../.claude/agents/sprint-retro-author.md) | Sprint close + retro write | sprint files + live mini-retros | `docs/project/retros/sprint-S<N>.md` |
| _Preset engineers_ (after `--preset`) | Implementation of a service feature | preset rule + design doc | code + tests |

## Built-in agents (always available)

| Agent | When |
|---|---|
| `Explore` | Read-only multi-file search; up to "very thorough" |
| `general-purpose` | Catch-all multi-step task |
| `pr-review-toolkit:code-reviewer` | Gate 4b — convention adherence |
| `pr-review-toolkit:silent-failure-hunter` | Gate 4b — silent error / inadequate handling |
| `pr-review-toolkit:type-design-analyzer` | Gate 4b — type design quality |
| `pr-review-toolkit:pr-test-analyzer` | Gate 4b — test coverage gap (if tests touched) |
| `pr-review-toolkit:comment-analyzer` | Gate 4b — comment accuracy (if comments touched) |
| `feature-dev:code-architect` | Greenfield architectural blueprint |

---

## Playbooks (the deep operational docs)

| Playbook | When you read it | What it answers |
|---|---|---|
| [`post-delegation-review`](./playbooks/post-delegation-review.md) | After every coding agent returns | The 6 gates — Inspect / Build+Test / Boundary / Spec-compliance (4a) → Quality (4b) / Wiring / Smoke |
| [`parallel-conflict-prevention`](./playbooks/parallel-conflict-prevention.md) | Before `/dispatch-parallel` | The 4-layer Conflict Radar — path / worktree / contract / dep graph |
| [`contract-first`](./playbooks/contract-first.md) | Any cross-service interface change | Contract commit first, code follows |
| [`failure-recovery`](./playbooks/failure-recovery.md) | After a partial dispatch / mid-merge abort | Recovery decision tree; what `/recover` walks you through |

## Setup docs (the "how it works" surface)

| Doc | When you read it |
|---|---|
| [`plugin-dependencies`](./setup/plugin-dependencies.md) | First time — install the required `pr-review-toolkit` + `superpowers` plugins |
| [`workflow-master`](./setup/workflow-master.md) | First time — the end-to-end S1-S7 pipeline |
| [`workflow-rules`](./setup/workflow-rules.md) | First time — the universal rules across stages |
| [`lesson-trigger-map`](./setup/lesson-trigger-map.md) | Before touching unfamiliar code — "if touching X → apply L###" |
| [`test-discipline`](./setup/test-discipline.md) | Writing tests — intent over theater; the legacy-safe characterization path |
| [`index-discipline`](./setup/index-discipline.md) | Skill authoring — how slim INDEX files stay in sync |
| [`zero-fix-task-template`](./setup/zero-fix-task-template.md) | Authoring a non-trivial D-doc |
| [`delegation-checklist`](./setup/delegation-checklist.md) | Before dispatching a subagent |
| [`file-based-dispatch`](./setup/file-based-dispatch.md) | Dispatching with a long task spec (write a brief file, don't inline) |
| [`agent-delegation-best-practices`](./setup/agent-delegation-best-practices.md) | When delegation feels off |
| [`integration-branch-strategy`](./setup/integration-branch-strategy.md) | Setting up branch protection / merge flow |
| [`deployment-workflow`](./setup/deployment-workflow.md) | First deploy on this project |
| [`settings-merge`](./setup/settings-merge.md) | Re-installing the template into an existing project |
| [`skill-authoring`](./setup/skill-authoring.md) | Authoring/improving a `SKILL.md` — triggers (CSO), progressive disclosure, token budget |
| [`permission-profiles`](./setup/permission-profiles.md) | Choosing `--profile restricted\|standard\|permissive` |
| [`secret-handling`](./setup/secret-handling.md) | Any secret-touching change |
| [`agent-config-security`](./setup/agent-config-security.md) | Changing `.claude/settings*.json` / `.mcp.json` / hooks — committed config is executable |
| [`compliance-mapping`](./setup/compliance-mapping.md) | Auditor walks in |
| [`separation-of-duties`](./setup/separation-of-duties.md) | Regulated work (N6) |
| [`multi-team-deployment`](./setup/multi-team-deployment.md) | Setting up an org fork |
| [`audit-trail`](./setup/audit-trail.md) | SIEM ingestion / forensics |
| [`ci-integration`](./setup/ci-integration.md) | Wiring CI to the template |

## Hooks

| Hook | Trigger | What it does | File |
|---|---|---|---|
| `secret-redact.sh` | PreToolUse on `Bash\|Write\|Edit\|MultiEdit` | Blocks obvious secret leaks (exit 2 on match) | [`../.claude/hooks/secret-redact.sh`](../.claude/hooks/secret-redact.sh) |
| `lint.sh` | PostToolUse on `Write\|Edit\|MultiEdit` | Runs project's linter; surfaces output to agent | [`../.claude/hooks/lint.sh`](../.claude/hooks/lint.sh) |
| `audit.sh` | PostToolUse + SubagentStop on `Agent` | Appends a JSONL record to `docs/project/audit/YYYY-MM.jsonl` | [`../.claude/hooks/audit.sh`](../.claude/hooks/audit.sh) |

---

## Common workflows

### Starting a new sprint

1. `/discover <feature idea>` → captures `D###-slug.md`
2. `/promote D###` → moves it to `docs/project/backlog.md`
3. (Sprint planning) edit `docs/project/sprints/sprint-S<N>.md` — pick tasks, assign fanout waves
4. `/next-task` → dispatches first task with D-doc gate

### Fixing a bug

1. `/next-task` (or `/assign <task>`) — picks the fix
2. Phase Matrix says: type=fix → regression test FIRST (Phase 4)
3. Implementation agent commits, returns
4. `/post-delegation-gate` → 6 gates
5. Live mini-retro (A009) appended to `sprint-S<N>-tasks.md`

### Shipping a UI feature

1. `/next-task` picks the feature
2. `design-doc-writer` creates D-doc with selector map (L020)
3. Implementation agent codes TDD-first
4. `/post-delegation-gate` 6 gates
5. **`/design-review`** — 3-lens visual fidelity (L182)
6. Mini-retro + commit + next

### Auditing the last sprint

1. `/progress` — read-only dashboard
2. Open `docs/project/retros/sprint-S<N>.md` — the closing retro
3. Open `docs/project/retros/sprint-S<N>-tasks.md` — the live mini-retros
4. Grep `docs/project/audit/YYYY-MM.jsonl` for the sprint's `task_id`
   prefix
5. Open `docs/project/FOLLOWUPS.md` — deferred items + acknowledgements

### Closing a sprint

1. `/progress` — confirm all tasks `[x]` or `[B]`-blocked
2. `/retro` — sprint close + backlog audit (HARD gate)
3. Manual: review FOLLOWUPS; ack any P1/P2 with PR-APPROVER trailer
4. `/archive` (if old sprints accumulate)

### Setting up org-wide adoption

1. Fork upstream `AI-Workflows` to `<org>/ai-workflows-internal`
2. Add `core/.claude/rules/org-rules.md.tmpl` with your A100+ rules
3. Customise `core/.github/CODEOWNERS.tmpl` with your real teams
4. Tag a version; have all teams install from the fork
5. See [`./setup/multi-team-deployment.md`](./setup/multi-team-deployment.md)

### Onboarding a new senior engineer

1. Read [`./getting-started-tour.md`](./getting-started-tour.md) — Monday-Friday walkthrough
2. Read [`../CLAUDE.md`](../CLAUDE.md) §N1-N6 — non-negotiables
3. Skim [`../.claude/rules/brain-hot.md`](../.claude/rules/brain-hot.md) — A001-A010
4. Run `/next-task` against the current sprint (paired with someone)
5. Read the [`./playbooks/post-delegation-review.md`](./playbooks/post-delegation-review.md) — the 6-gate ritual

---

## Spec surfaces (sources of truth)

| Path | What | Source-of-truth for |
|---|---|---|
| [`./project/STATUS.md`](./project/STATUS.md) | Single-pane current state | "what sprint are we in" |
| [`./project/STATUS-archive.md`](./project/STATUS-archive.md) | Historical STATUS prose | Past sprint snapshots |
| [`./project/backlog.md`](./project/backlog.md) | All work, ever | "is this idea already tracked" |
| [`./project/FOLLOWUPS.md`](./project/FOLLOWUPS.md) | Deferred items + ack | "what got pushed past sprint close" |
| `./project/ideas/D###-slug.md` | Pre-backlog ideas | Discovery before commitment |
| `./project/sprints/sprint-S<N>.md` | Active sprint task table | Tasks, fanout waves, dependencies |
| `./project/retros/sprint-S<N>-tasks.md` | Live per-task mini-retros (A009) | Per-task learnings while context is hot |
| `./project/retros/sprint-S<N>.md` | Sprint close retro | Audited sprint outcome |
| `./project/audit/YYYY-MM.jsonl` | Agent dispatch audit JSONL | Compliance evidence (CC7.1 / AU-2) |
| `./project/reviews/sprint-S<N>-design-review.md` | UI fidelity gate report | `/design-review` output |
| `./designs/sprint-S<N>/D<NNN>-<slug>.md` | Per-task design doc | Source-of-truth for the task's how |

---

## Templates (writing-quality enforcement)

| Template | For |
|---|---|
| [`./designs/_templates/DESIGN_TEMPLATE.md`](./designs/_templates/DESIGN_TEMPLATE.md) | ≥500L zero-fix D-doc (feat tasks) |
| [`./designs/_templates/DESIGN_LIGHT_TEMPLATE.md`](./designs/_templates/DESIGN_LIGHT_TEMPLATE.md) | Light D-doc (fix / refactor) |
| [`./designs/_templates/DESIGN_REVIEW_CHECKLIST.md`](./designs/_templates/DESIGN_REVIEW_CHECKLIST.md) | `/design-review` 3-lens checklist |
| [`./designs/_templates/SELF_REVIEW_CHECKLIST.md`](./designs/_templates/SELF_REVIEW_CHECKLIST.md) | Self-review before submitting PR |
| [`./designs/_templates/SIZE_TIERS.md`](./designs/_templates/SIZE_TIERS.md) | When to use LIGHT vs FULL |
| [`./designs/_templates/BACKLOG_ENTRY_TEMPLATE.md`](./designs/_templates/BACKLOG_ENTRY_TEMPLATE.md) | Format of a backlog row |

---

## See also

- [`./getting-started-tour.md`](./getting-started-tour.md) — day-in-the-life walkthrough
- [`../CLAUDE.md`](../CLAUDE.md) — the orchestrator's manual (≤200L)
- [`../README.md`](../README.md) — quick start
- [`../../docs/control-plane-architecture.md`](../../docs/control-plane-architecture.md) — why the 7 layers
- [`../../docs/how-to-customize.md`](../../docs/how-to-customize.md) — what to edit safely
- [`../../docs/adding-new-preset.md`](../../docs/adding-new-preset.md) — extending the template
