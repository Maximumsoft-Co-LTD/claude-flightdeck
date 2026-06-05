# Sub-agent + Agent Teams Workflow (auto-loaded · MANDATORY)

> **Purpose:** route work to specialized subagents to minimize
> main-session context burn and stay coherent across a long sprint.
> This project uses Claude Code's native **subagent** feature
> (`Agent` tool with `subagent_type=...`) and the **Team** feature.
> It does NOT use `claude -p`.
>
> **Why no `claude -p`:** external process per task means no shared
> memory, no introspection of agent state, brittle output parsing,
> and slower iteration than in-session subagents.

---

## §0 Announce the discipline

When you invoke a discipline skill or gate (`/work`, `/review gates`,
`/review design`, `/retro`), **open with one line naming it**: e.g. *"Using
/review gates to run the 6 gates on this diff."* This signals to
the user which discipline is active and makes a skipped step visible.
(Adopted from the superpowers "announce at start" convention.)

## §1.0 When NOT to use multi-agent (read before §1)

Multi-agent is a tool with a real, named cost and failure mode — not a
default. Before fanning out, clear this gate:

- **Cost:** parallel subagents cost on the order of **~15× the tokens** of a
  single-agent run (Anthropic, multi-agent research system). Pay it only when
  the parallel work genuinely earns it.
- **Top failure mode — context fragmentation:** independent subagents make
  *conflicting assumptions not prescribed upfront*, producing output a final
  agent can't cleanly reconcile (Cognition, "Don't Build Multi-Agents"; MAST
  taxonomy — 14 multi-agent failure modes, mostly inter-agent misalignment,
  NeurIPS 2025).

→ **Default to ONE well-briefed agent with continuous context.** Reach for
parallel subagents only when the work is **(a) provably disjoint** (see
[`../../docs/playbooks/parallel-conflict-prevention.md`](../../docs/playbooks/parallel-conflict-prevention.md))
**AND (b) read-heavy or independent** (e.g. parallel `Explore`, independent
file reviews). A task with shared state, or where one stream's decisions
constrain another's → **serialize, or keep it single-agent.** For long single
tasks, *compress* context (summarize decisions so far), don't *split* it.

## §1 When to delegate vs inline

```
Task incoming
    ↓
1. Will it produce >5k tokens of file / grep output?
   → YES: subagent_type=Explore (read-only) — preserves main-session context
   → NO:  continue
    ↓
2. Will it author a structured doc (sprint plan, retro, design doc, compliance matrix)?
   → YES: a project-local agent matching the doc class (sprint-retro-author,
          design-doc-writer) OR general-purpose with a structured prompt
    ↓
3. Does it require multiple parallel investigations (3+ files / topics, independent)?
   → YES: dispatch N parallel subagents in a SINGLE message (multiple Agent
          tool calls in one block). Each gets isolation="worktree" if writes are expected.
   → NO:  continue
    ↓
4. Is it implementation of a feature?
   → YES (server-side): `backend-engineer`
   → YES (client-side): `frontend-engineer`
   → YES (infra, k8s-helm installed): `k8s-engineer`
   → NO:  continue
    ↓
5. Is it cross-service / cross-area / architectural decision?
   → YES: senior-tech-lead for review;
          feature-dev:code-architect (built-in) for greenfield design
   → NO:  default to inline (main session)
```

**Default to inline when in doubt.** Subagent dispatch has overhead;
use it when the work matches §1.1-6 patterns OR when context
preservation outweighs that overhead.

## §1.5 Cost-aware model routing

Once you've decided to delegate, pick the **cheapest model tier that can
do the job well** — don't burn the top tier on mechanical work. Model
price spans roughly an order of magnitude (Opus ≈ ~5× Sonnet; Haiku 4.5 ≈
**~1/3 the cost and 2×+ the speed** of a frontier model at near-frontier
coding — Anthropic). Combined with the ~15× multi-agent multiplier in
§1.0, model tier is the single biggest cost lever you control per dispatch.

| Tier | Use it for | Agents that default to it |
|---|---|---|
| **Opus** | Planning / orchestration, design-doc synthesis, root-cause ranking, foundational authoring — work where a wrong call cascades | `{{AGENT_PREFIX}}-orchestrator`, `design-doc-writer`, `onboarding-engineer` |
| **Sonnet** (default for code) | Implementation against a clear design doc, code review, retro, sprint hygiene, smoke runs — high-volume work with the 6-gate net underneath | `backend-engineer`, `frontend-engineer`, `senior-tech-lead`, `sprint-retro-author` |
| **Haiku** | Bulk rename, pattern grep, 1-line mechanical edits, read-heavy navigation / `Explore` fan-out — low-judgment, high-throughput | (dispatch-time override; no agent defaults here yet) |

**Escalation rule (don't pre-pay for intelligence):** start at the tier in
the table. If a Sonnet implementation agent stalls — **≥2 rounds without
passing its gates** — *then* re-dispatch on Opus. Ambiguous task → Sonnet
first, escalate only on evidence. This is cheaper in aggregate than
defaulting everything to Opus "to be safe."

**How to override per dispatch** (the table is a default, not a ceiling):
- **`Agent(...)`** — the agent's frontmatter `model:` is the default; a hard
  task can be sent to a higher tier by dispatching the same role with an
  explicit model, or by bumping the frontmatter for that project.
- **Workflow scripts** — set `opts.model` per stage: cheap models for
  read-heavy verify / `Explore` stages, reserve Opus for the synthesis
  stage. Omit it to inherit the session model (the right default most of
  the time).
- **`effort`** (low / med / high / xhigh) trades intelligence vs
  cost/latency *within* one model — reach for it before jumping a whole tier.

> Deeper matrix (work-type → delegate? → model, with context-budget
> triggers): [`../../docs/setup/agent-delegation-best-practices.md`](../../docs/setup/agent-delegation-best-practices.md) §2-3.
> That doc is the canonical detail; this table is the always-loaded summary
> — keep them in sync if you change a default.

## §2 Available subagent types

### Project-local agents (in `.claude/agents/`)

Core (always available):

| Subagent | Use for | Reads first |
|---|---|---|
| `<prefix>-orchestrator` | Pick next task; orchestrate a sprint phase; multi-step PM work | `docs/project/sprints/S<N>/tasks.md` + backlog |
| `backend-engineer` | Any server-side feature (handler, use-case/service, data access, migration, worker, producer/consumer). Architecture-agnostic — conforms to the project's style | `.claude/rules/code-style.md` + area CLAUDE.md + design doc |
| `frontend-engineer` | Any client-side feature (page, component, state, form, API call, i18n). Architecture-agnostic — conforms to the app's style | `.claude/rules/code-style.md` + area CLAUDE.md + design doc |
| `design-doc-writer` | Author a ≥500-line zero-fix design doc per task | task brief + relevant area CLAUDE.md |
| `senior-tech-lead` | Cross-service design review; architectural decisions; post-delegation Gate 3 boundary review | task design doc + relevant CLAUDE.md |
| `sprint-retro-author` | Author sprint close retro | sprint files + live mini-retros |

Preset agents (only appear after `--preset` install):

| Preset | Agents |
|---|---|
| `k8s-helm` | `k8s-engineer` |
| _custom (you authored)_ | _its own agents — see `docs/adding-new-preset.md`_ |

> The core engineers are **convention-driven**: they read
> `.claude/rules/code-style.md` (generated by `/onboard`) and match the
> codebase's real structure rather than imposing an architecture. Teams that
> want an opinionated architecture (hex, FSD, …) can author a custom preset
> that adds a specialized engineer + its boundary rule.

### Built-in agents (always available)

| Subagent | Use for |
|---|---|
| `Explore` | Read-only file / symbol / keyword search; up to "very thorough" breadth |
| `general-purpose` | Catch-all multi-step task that doesn't fit a specialist |
| `feature-dev:code-architect` | Design + implementation blueprint for a feature |
| `feature-dev:code-explorer` | Deep-trace existing feature code paths |
| `feature-dev:code-reviewer` | Code review with confidence-based filtering |
| `pr-review-toolkit:code-reviewer` | Project-convention adherence review |
| `pr-review-toolkit:silent-failure-hunter` | Hunt silent failures + inadequate error handling |
| `pr-review-toolkit:type-design-analyzer` | Type design quality |
| `pr-review-toolkit:pr-test-analyzer` | Test coverage gap analysis |
| `pr-review-toolkit:comment-analyzer` | Comment accuracy / rot |
| `pr-review-toolkit:code-simplifier` | Simplify after a logical chunk |
| `claude-code-guide` | How-to questions about Claude Code itself |

## §3 Dispatch patterns

> **File-based dispatch (default for non-trivial work).** Do NOT paste a
> long spec into `prompt` — oversized inline prompts can stall/hang the
> dispatch. Write the spec to a **brief file**
> (`docs/project/sprints/S<N>/designs/_briefs/<TASK_ID>-<role>.md`) and pass a
> short pointer prompt. The agent reads its brief first (pre-task ritual
> Step 0). Inline only for a tiny (~≤30-line) instruction. Full
> convention: [`../../docs/setup/file-based-dispatch.md`](../../docs/setup/file-based-dispatch.md).

### §3.1 Single subagent, foreground (most common)

```
# 1. Write the brief file (full spec: reads-first, AC, matrix, test plan, contract)
Write docs/project/sprints/S<N>/designs/_briefs/{{TASK_ID_PREFIX}}-S02.03-impl.md  <full spec>

# 2. Dispatch with a SHORT pointer prompt
Agent(
  description: "Implement {{TASK_ID_PREFIX}}-S02.03 (some handler)",
  subagent_type: "<engineer-of-choice>",
  prompt: "You are the impl engineer for {{TASK_ID_PREFIX}}-S02.03.
           Your brief: docs/project/sprints/S<N>/designs/_briefs/{{TASK_ID_PREFIX}}-S02.03-impl.md
           Read it FIRST, run your pre-task ritual, report per your output contract."
)
```

Blocks until done. Use when you need the output before proceeding.

### §3.2 Single subagent, background

```
Agent(
  description: "Run nightly recon",
  subagent_type: "general-purpose",
  prompt: "<full task spec>",
  run_in_background: true
)
```

Use when the work is long-running and you have unrelated work to do
meanwhile. **Do NOT poll** — the harness notifies you when it
completes.

### §3.3 Parallel subagents (independent work)

Write **one brief file per agent** first
(`_briefs/<TASK_ID>-impl.md`), then dispatch each with a short pointer
prompt in a single message:

```
[Single message containing N Agent tool calls]
Agent(... pointer to _briefs/<A>-impl.md ..., isolation: "worktree")
Agent(... pointer to _briefs/<B>-impl.md ..., isolation: "worktree")
Agent(... pointer to _briefs/<C>-impl.md ..., isolation: "worktree")
```

All N run in parallel. Each gets an isolated git worktree so changes
can't collide on the filesystem.

**Before dispatching parallel agents**, verify:

1. **Path declaration**: each agent's allowed paths are non-overlapping
   (grep current branch for any pending changes in those paths).
2. **Task dependencies**: use `TaskCreate` + `addBlocks` /
   `addBlockedBy` if any agent must finish before others can start.
3. **Contract-first**: if agents touch a shared contract (event, REST
   shape), the contract change must merge first in a separate commit.

If overlap detected → SERIALIZE (run one after the other) instead of
parallel.

### §3.4 Send a follow-up to a running subagent

```
SendMessage(
  to: "<agent name or ID>",
  message: "Additional context: <...>"
)
```

Resumes the same agent with full context. New `Agent(...)` calls start
a fresh agent with no memory of prior runs — only use when starting
over.

## §4 The 6-gate post-delegation review (MANDATORY)

After every coding subagent returns, run ALL six gates before merge.
Codified in [`../../CLAUDE.md`](../../CLAUDE.md) §N3 + full playbook at
[`../../docs/playbooks/post-delegation-review.md`](../../docs/playbooks/post-delegation-review.md).

1. **Inspect** — `git diff --stat` + `git diff <changed-files>`. Never
   trust the subagent's "done" claim without reading the diff.
2. **Build + Test** — real build + real test in every touched area.
3. **Boundary** — dispatch `senior-tech-lead` to check the diff against the
   project's own conventions (`code-style.md` + area CLAUDE.md), backed by an
   import/lint grep where mechanical. (A custom preset may ship its own
   boundary reviewer.)
4. **Spec-compliance (4a) → Quality (4b)** — 4a FIRST: read the code
   against the D-doc AC list; confirm every AC is built and nothing extra
   (over/under-build). THEN 4b: single message with
   `pr-review-toolkit:code-reviewer`, `:silent-failure-hunter`,
   `:type-design-analyzer` (add `:pr-test-analyzer` if tests touched,
   `:comment-analyzer` if comments touched). 4a gates 4b.
5. **Wiring (L116)** — composition root has the new code; migrations
   applied; instrumentation emits; topics created; contracts updated.
6. **Integration smoke** — real system, golden path, end-to-end. UI
   changed? Add `/review design` for visual fidelity.

Failure at any gate → fix → re-run that gate. Do not skip gates.

## §5 What to NEVER do

- ❌ Use `claude -p`. Use `Agent(subagent_type=...)` instead.
- ❌ Dispatch two coding subagents in parallel without git worktree
  isolation. Conflicts will eat work.
- ❌ Skip the 6-gate review.
- ❌ Let a subagent self-review replace the gate (self-review is part
  of step 1, not the whole review).
- ❌ Trust a subagent's "tests passing" summary without re-running
  tests yourself.
- ❌ Dispatch a subagent without giving it the relevant rules + design
  doc — it has no prior context.

## §6 Token budget guidance

| Mode | Typical |
|---|---|
| Inline implementation (main session) | 50-150k context if 5+ files touched |
| Single foreground subagent | 30-80k for the subagent; 5-10k summary in main |
| 3 parallel `Explore` subagents | 90-150k total across subagents; ~15k summary back |
| Post-delegation review (3-5 reviewers parallel) | 40-80k total |

When main session is approaching 50% context budget, prefer delegating
new work to subagents over inlining.

## §7 Related

- [`../../CLAUDE.md`](../../CLAUDE.md) §N3 — 6-gate review
- [`../../CLAUDE.md`](../../CLAUDE.md) §N4 — parallel conflict prevention
- [`./agent-pre-task-ritual.md`](./agent-pre-task-ritual.md) — what every dispatched agent must do
- [`./brain-hot.md`](./brain-hot.md) — the 10 always-apply rules
- [`../../docs/playbooks/post-delegation-review.md`](../../docs/playbooks/post-delegation-review.md) — full 6-gate playbook
- [`../../docs/playbooks/parallel-conflict-prevention.md`](../../docs/playbooks/parallel-conflict-prevention.md) — full 4-layer playbook
