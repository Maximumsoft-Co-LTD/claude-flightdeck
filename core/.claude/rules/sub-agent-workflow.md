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

When you invoke a discipline skill or gate (`/next-task`, `/assign`,
`/dispatch-parallel`, `/post-delegation-gate`, `/design-review`,
`/retro`), **open with one line naming it**: e.g. *"Using
/post-delegation-gate to run the 6 gates on this diff."* This signals to
the user which discipline is active and makes a skipped step visible.
(Adopted from the superpowers "announce at start" convention.)

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
4. Is it implementation of a service feature (use-case + adapter + tests)?
   → YES: the matching preset engineer (e.g. go-hexagonal-engineer,
          frontend-fsd-engineer, vue-engineer, k8s-engineer)
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

## §2 Available subagent types

### Project-local agents (in `.claude/agents/`)

Core (always available):

| Subagent | Use for | Reads first |
|---|---|---|
| `<prefix>-orchestrator` | Pick next task; orchestrate a sprint phase; multi-step PM work | `docs/spec/STATUS.md` + backlog |
| `design-doc-writer` | Author a ≥500-line zero-fix design doc per task | task brief + relevant area CLAUDE.md |
| `senior-tech-lead` | Cross-service design review; architectural decisions; post-delegation audit | task design doc + relevant CLAUDE.md |
| `sprint-retro-author` | Author sprint close retro | sprint files + live mini-retros |

Preset agents (appear after `--preset` install — examples):

| Preset | Agents |
|---|---|
| `go-hex` | `go-hexagonal-engineer`, `hexagonal-reviewer`, `kafka-pipeline-engineer`, `observability-engineer` |
| `nextjs-fsd` | `frontend-fsd-engineer` |
| `vue-pinia` | `vue-engineer` |
| `k8s-helm` | `k8s-engineer` |

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
> (`docs/designs/sprint-S<N>/_briefs/<TASK_ID>-<role>.md`) and pass a
> short pointer prompt. The agent reads its brief first (pre-task ritual
> Step 0). Inline only for a tiny (~≤30-line) instruction. Full
> convention: [`../../docs/setup/file-based-dispatch.md`](../../docs/setup/file-based-dispatch.md).

### §3.1 Single subagent, foreground (most common)

```
# 1. Write the brief file (full spec: reads-first, AC, matrix, test plan, contract)
Write docs/designs/sprint-S<N>/_briefs/{{TASK_ID_PREFIX}}-S02.03-impl.md  <full spec>

# 2. Dispatch with a SHORT pointer prompt
Agent(
  description: "Implement {{TASK_ID_PREFIX}}-S02.03 (some handler)",
  subagent_type: "<engineer-of-choice>",
  prompt: "You are the impl engineer for {{TASK_ID_PREFIX}}-S02.03.
           Your brief: docs/designs/sprint-S<N>/_briefs/{{TASK_ID_PREFIX}}-S02.03-impl.md
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
3. **Boundary** — dispatch the preset architectural reviewer (e.g.
   `hexagonal-reviewer` for go-hex). If no preset reviewer, run the
   project's architectural lint.
4. **Spec-compliance (4a) → Quality (4b)** — 4a FIRST: read the code
   against the D-doc AC list; confirm every AC is built and nothing extra
   (over/under-build). THEN 4b: single message with
   `pr-review-toolkit:code-reviewer`, `:silent-failure-hunter`,
   `:type-design-analyzer` (add `:pr-test-analyzer` if tests touched,
   `:comment-analyzer` if comments touched). 4a gates 4b.
5. **Wiring (L116)** — composition root has the new code; migrations
   applied; instrumentation emits; topics created; contracts updated.
6. **Integration smoke** — real system, golden path, end-to-end. UI
   changed? Add `/design-review` for visual fidelity.

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
