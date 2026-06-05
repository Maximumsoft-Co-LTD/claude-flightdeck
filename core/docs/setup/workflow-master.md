# {{PROJECT_NAME}} — Workflow Master

> The end-to-end pipeline for running a sprint. Single source of truth for "what stage am I in, what artifact lands here, which skill drives it". Adapt freely to your project — the stage table and per-stage discipline are universal; the skill names map to `.claude/skills/` and the agent names map to `.claude/agents/`.

## Stages (Discovery → Sprint → Design → Implement → Review → Retro)

| Stage | Goal | Driver | Artifact | Rule(s) |
|---|---|---|---|---|
| **S1 Discovery** | Capture a user need / external requirement; classify it; seed a backlog row | `/discover` skill | `docs/project/ideas/D###-slug.md` + new row in `docs/project/backlog.md` | A008 |
| **S2 Sprint planning** | Break discovery + backlog into a coherent sprint with task table + fanout waves | manual + `/promote` + orchestrator agent | `docs/project/sprints/sprint-S<N>.md` (status board + dependency waves + cross-task contracts) | A008 |
| **S3 Design (per task)** | Author **D-doc per A005** BEFORE any code edit / agent dispatch | `/next-task` skill + `design-doc-writer` agent (for non-trivial tasks) | `docs/designs/sprint-S<N>/D<NNN>-<slug>.md` (LIGHT or FULL template) | **A005** |
| **S4 Implement** | TDD / impl following the D-doc + apply lesson-trigger-map rules | `Agent()` dispatch (foreground) OR `/dispatch-parallel` (fanout) | code in your services + tests | A001 / A002 / A003 / A010 |
| **S5 Review (6-gate)** | Verify the dispatch result against the 6-gate review BEFORE merge | `/post-delegation-gate` skill + parallel reviewers | review log appended to PR or inline | root CLAUDE.md §N3 |
| **S6 Per-task retro (live)** | While context is hot, append a 6-field mini-retro to the sprint's task-retro file | manual write or `/retro --task` | `docs/project/retros/sprint-S<N>-tasks.md` (append-only) | **A009** |
| **S7 Sprint close + audit** | Aggregate task retros → full retro; **audit backlog for 0 mismatch** | `/retro` skill + `sprint-retro-author` agent | `docs/project/retros/sprint-S<N>.md` + STATUS-archive move | **A008** |

## Per-sprint timing (single-dev baseline — tune to team size)

- **S1 Discovery**: 0–2h (most work after the first few sprints is design-spec-driven, not discovery-driven)
- **S2 Planning**: 1h (backlog → sprint file; identify fanout waves)
- **S3 Design (per task)**: 30min–2h per task depending on complexity (light vs full template)
- **S4 Implement**: bulk of the sprint (1–5 days for a single-dev fanout sprint of 8–12 tasks)
- **S5 Review**: 10–30min per task (6-gate)
- **S6 Per-task retro (live)**: 5min per task while the context is still loaded — do NOT defer
- **S7 Sprint close**: 30min retro write + backlog audit + STATUS move

## The "single-dev fanout sprint" playbook

1. **Sprint pre-flight** — read `docs/project/STATUS.md` track row + `docs/project/sprints/sprint-S<N>.md`. Confirm the active sprint via the 🚀 marker (A008).
2. **Author per-task D-docs** (A005). One D-doc may cover multiple sibling tasks if they share source-of-authority (e.g., all UX/A11y tasks driven from a single gate report).
3. **Fanout decision** — for each task: small surgical → inline in main session; medium → single `Agent()` foreground; multi-independent → `/dispatch-parallel` with worktree isolation + Conflict Radar.
4. **Per task or wave**:
   - dispatch (or inline impl)
   - 6-gate review (root CLAUDE.md §N3 gates 1–6)
   - if gate-4 (parallel quality reviewers) finds P1/P2 issues → fix in-session, re-run that gate
   - LIVE mini-retro (A009) — 5min, append to `sprint-S<N>-tasks.md`
   - commit + push
   - update sprint file row `[ ] Not Started` → `[x] Done` / `[~] Partial`
   - **immediately sync backlog row to `done S<N>`** (A008)
5. **Sprint close** — `/retro` aggregates mini-retros + runs the backlog-audit grep (mismatch ≠ 0 → blocker). Move STATUS prose to archive in the SAME commit (per A008 update protocol).

## Cross-track contracts (when one task's output feeds another)

- Event schemas / message contracts — N2 contract-first (separate commit BEFORE consumers)
- REST / RPC contracts — N2 same rule
- Cross-repo ports — declared interface doc + N1 boundary (the implementing plane is out of scope of this repo)

## Doc sync

`/document` skill runs on demand to verify Design Doc ↔ sprint file ↔ STATUS.md ↔ backlog.md drift. The four tiers must agree on: task status, AC list, applied rules, touched-files matrix. Drift detected at sprint close = blocker.

## Escape hatches

- A task that blows up mid-sprint → mark `[B] Blocked — <reason>` in the sprint file (do NOT delete). `/retro` audits these.
- A D-doc missed before impl (A005 violation) → STOP, author the D-doc retroactively, annotate the impl commit with `refs D<NNN>` trailer. Sprint retro flags it as process-loss per A005.
- A gate-4 reviewer reports a finding too costly to fix in-session → file as `{{AGENT_PREFIX}}-DR-FU-<n>` backlog row + label severity (P1/P2/P3); only P1 blocks merge.

## Skills cheat-sheet (canonical names)

| Stage | Skill |
|---|---|
| Discovery | `/discover` |
| Promote backlog row → sprint | `/promote` |
| Pick next task in sprint | `/next-task` |
| Author D-doc | `design-doc-writer` (agent, not skill) — invoked by `/next-task` |
| Single foreground dispatch | `Agent()` directly |
| **Parallel fanout** | `/dispatch-parallel` |
| Post-dispatch 6-gate review | `/post-delegation-gate` |
| Design fidelity (UI work) | `/design-review` |
| Mid-sprint dashboard | `/progress` |
| Sprint retro + close | `/retro` |
| Archive old sprint files | `/archive` |
| Verify local dev stack | `/verify-dev` |

## Related

- Root: [`../../CLAUDE.md`](../../CLAUDE.md) — §N1–N6 non-negotiables + ## Workflow ToC
- Rules: [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) — A001-A010 (canonical) + A011+ project-local
- Mechanical lesson map: [`lesson-trigger-map.md`](lesson-trigger-map.md) — file touched → A###/L### applied
- Hot rules brain dump: [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) — top-priority rules auto-loaded
- Pre-task ritual (for agents): [`../../.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md)
