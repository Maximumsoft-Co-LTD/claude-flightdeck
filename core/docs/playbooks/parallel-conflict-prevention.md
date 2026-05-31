# Playbook — Parallel Conflict Prevention (4-Layer)

> Operator playbook. The deep-dive that [`CLAUDE.md`](../../CLAUDE.md) §N5 and [`.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §3.3 point to. Execute the 4 layers **before** dispatching 2+ coding subagents in the same message.
>
> **Core principle**: parallel speed is only worth it when the work is provably disjoint. If you can't prove disjointness in under a minute, **serialize** — a clobbered worktree costs far more than the sequential run.

## Step 0 — First question: is multi-agent even the right call?

Before the 4 layers, clear the prior gate in
[`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §1.0:
parallel subagents cost ~**15×** the tokens of a single agent and their top
failure mode is **context fragmentation** (independent agents making
conflicting assumptions). Parallelize only when the work is **provably
disjoint AND read-heavy/independent**. If decisions in one stream constrain
another, or the streams share state → **keep it single-agent or serialize.**
The 4 layers below assume you've already decided parallel is worth it.

## Why this exists

Two subagents writing the same file in the same tree race on `.git/index` and silently eat each other's work; cross-service imports introduced in parallel pass each agent's own tests but break the boundary. The 4 layers are a pre-flight gate that lets multi-stream sprints fan out safely to disjoint paths.

## The 4 layers (run in order)

| Layer | Question it answers | Tool |
|---|---|---|
| 1. Path declaration + overlap grep | "Do any two agents touch the same path?" | `git status` / `git diff --stat` per branch + manual overlap check |
| 2. Worktree isolation | "Can their filesystem writes collide?" | `Agent(isolation: "worktree")` **+ the submodule caveat below** |
| 3. Contract-first | "Do they share an external interface?" | [`contract-first.md`](contract-first.md) — land the contract commit first |
| 4. Task dependency graph | "Must one finish before another starts?" | `TaskCreate` + `addBlocks` / `addBlockedBy` |

If **any** layer fails to clear → **SERIALIZE** (run the agents one after another, full 6-gate review between each).

---

## Layer 1 — Path declaration + overlap grep

**Rule**: every parallel subagent declares its allowed touched-paths matrix upfront (in its task design doc and in its dispatch prompt). The orchestrator greps for overlap before dispatch.

**How to apply**:

```bash
# 1. List each agent's declared paths. Example fan-out:
#    W1 -> infrastructure/observability/
#    W2 -> contracts/  +  shared/contracts/
#    W4 -> deployments/
# 2. Confirm the live tree has no pending changes already sitting in those paths:
git status -s infrastructure/observability/ contracts/ shared/contracts/ deployments/
# 3. Mechanical overlap check — sort the declared prefixes; any shared prefix = overlap:
printf '%s\n' \
  "infrastructure/observability/" \
  "contracts/" \
  "shared/contracts/" \
  "deployments/" | sort | uniq -d        # any output = duplicate prefix = STOP
```

**What overlap looks like**: two agents both list (or nest under) the same directory — e.g. one owns `service-a/internal/usecase/` and another owns `service-a/internal/` (the second is a superset).

**On overlap detected**: SERIALIZE. Do not try to "coordinate" two agents on a shared path — that's what the dependency graph (Layer 4) is for, or it means the work should be one agent.

---

## Layer 2 — Worktree isolation (and the submodule caveat)

**Rule**: each parallel coding subagent gets `isolation: "worktree"` so its filesystem writes can't collide.

```text
[Single message — N Agent calls dispatched together]
Agent(description: "W1 ...", subagent_type: "backend-engineer", isolation: "worktree", prompt: "...")
Agent(description: "W4 ...", subagent_type: "senior-devops-engineer", isolation: "worktree", prompt: "...")
```

### The submodule caveat

**Meta-repo git worktrees do NOT populate submodules.** A worktree created off the meta-repo gives you the meta tree but **empty submodule directories**. This splits parallel work into two regimes:

| Agent's work touches… | Isolation model |
|---|---|
| A **submodule's own code** (e.g. `service-a/internal/...`, `shared/contracts/...`) | Work in the **live submodule checkout**. Each submodule is its own git repo → that IS the isolation boundary. Two agents touching **different submodules** are naturally isolated (different `.git`). Two agents in the **same** submodule must serialize (or use a worktree of that submodule, not the meta-repo). |
| **Meta-repo-only paths** (e.g. `contracts/`, `deployments/`, `infrastructure/`, `docs/`, `.claude/`) | Either (a) `isolation: "worktree"` off the meta-repo (fine — no submodule content needed), OR (b) the **no-commit / orchestrator-commits-serially** model below. |

### No-commit, orchestrator-commits-serially (the model used for meta-repo fan-out)

When several agents write **disjoint meta-repo paths in the same tree**, the cleanest race-free model is:

1. Each agent **writes its files but does NOT `git commit`** (avoids the `.git/index` race between siblings writing the same tree).
2. The orchestrator, after each agent returns, runs the 6-gate review and **commits serially** — one commit per workstream, in a deterministic order.

> This is exactly why a playbook-authoring agent is told "do NOT commit" — a sibling agent is writing a disjoint `docs/` / `.claude/` path in the same tree at the same time, and serial orchestrator commits keep the index uncontended.

**On caveat hit** (an agent reports empty submodule dirs in its worktree): re-dispatch that agent to work in the live submodule checkout instead, and serialize against any other agent touching the same submodule.

---

## Layer 3 — Contract-first (A003)

**Rule**: if any parallel agent touches an event / message shape or REST / RPC API shape, the contract change MUST land first, in its own commit, **before** the parallel code agents run. Full flow: [`contract-first.md`](contract-first.md).

**How to apply**: pull the contract edit out of the parallel batch. Commit `contracts/events/<topic>.json` (or `contracts/openapi/<service>.yaml`) standalone. THEN dispatch the producer agent and the consumer agent in parallel — both now build against a committed, stable contract.

---

## Layer 4 — Task dependency graph

**Rule**: model "B needs A's output" as an explicit dependency. **Never dispatch a blocked task.**

```text
TaskCreate(id: "W2", title: "contracts + language mirror")
TaskCreate(id: "W3", title: "consumer that uses the new contract")
addBlockedBy(task: "W3", blockedBy: "W2")     # W3 cannot start until W2 lands
# W1 and W4 have no blockers -> dispatch in parallel; W3 waits for W2.
```

**How to apply**: build the graph before dispatch. Dispatch only the **unblocked** frontier in parallel. When a blocker completes (and passes its 6-gate review), unblock and dispatch the next frontier.

---

## Decision: parallelize or serialize?

```text
                 ┌─────────────────────────────────────────────┐
2+ coding tasks  │ Layer 1: any path overlap?         → YES → SERIALIZE
incoming    ───► │ Layer 2: same submodule, no isolation? → YES → SERIALIZE
                 │ Layer 3: shared contract not yet committed? → land contract first, THEN parallel the rest
                 │ Layer 4: any task blocked by another?      → dispatch only the unblocked frontier
                 └─────────────────────────────────────────────┘
                 All clear → dispatch the disjoint set in ONE message (N Agent calls).
```

**When in doubt, serialize.** The 6-gate review (run between serial dispatches) is cheaper than reconstructing clobbered work.

## Copy-paste pre-flight checklist

```text
Parallel dispatch pre-flight — sprint S__  workstreams: __________

[ ] Layer 1  Each agent's touched-paths matrix declared; `sort | uniq -d` on prefixes = empty; live tree clean in those paths
[ ] Layer 2  Submodule-code agents → live checkout, one agent per submodule (serialize if same submodule)
             Meta-repo-only agents → isolation:"worktree" OR no-commit + orchestrator commits serially
[ ] Layer 3  Any shared event/REST contract committed FIRST (own commit) before code agents run
[ ] Layer 4  Dependency graph built (TaskCreate + addBlockedBy); only the unblocked frontier dispatched
[ ] Dispatch  All N independent Agent calls in a SINGLE message
[ ] Fan-in   6-gate review per returned agent; orchestrator commits serially; bump submodule pointers
```

## What to NEVER do

- Dispatch two coding subagents in parallel without isolation (worktree for meta-repo work, or distinct submodule checkouts). Conflicts eat work.
- Assume a meta-repo worktree contains submodule code — it does not (Layer 2 caveat).
- Run two agents against the **same submodule** in parallel.
- Dispatch a task that is `blockedBy` another still-in-flight task.
- Parallelize a producer + consumer before their shared contract commit has landed (A003 / Layer 3).

## Related

- [`../../CLAUDE.md`](../../CLAUDE.md) §N5 — the 4-layer skeleton this expands; §N7 — multi-repo / submodule discipline.
- [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §3.3 (parallel dispatch), §3.4 (`SendMessage` follow-up), §5 (never-do).
- [`contract-first.md`](contract-first.md) — Layer 3 detail.
- [`post-delegation-review.md`](post-delegation-review.md) — the 6-gate review run on each returned agent at fan-in.
