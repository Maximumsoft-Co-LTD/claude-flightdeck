# `.claude/workflows/` — dynamic workflow library

> **Why this exists.** Claude Code's `Workflow` tool runs a JavaScript
> orchestration script *outside* the agent's context — fan-out via
> `agent()/parallel()/pipeline()`, budget-scaled, resumable, up to ~1000 agents
> per run. This folder ships **reusable, version-controlled workflow scripts** so
> every install gets at-scale review/understand orchestration for free, invokable
> by name. A skill runs one with `Workflow({ name: "fd-review-changes", args })`.

## The one rule that makes this safe

Dynamic workflows are for **READ-heavy · VERIFY-heavy · BREADTH** work (review,
audit, research, understand a codebase). They are **not** a way to parallelize
*writes*, and they do **not** replace human judgment:

- **Writes stay single-threaded.** Parallel writes carry conflicting implicit
  decisions — keep them serial unless paths are provably disjoint + worktree-isolated
  (see [`../rules/sub-agent-workflow.md`](../rules/sub-agent-workflow.md) §1.0/§1.6).
- **A workflow returns conclusions, not a merge-ready diff.** It can *augment* the
  6-gate (produce a high-confidence findings list) but never *replace* it — the
  orchestrator still re-runs build/test (Gate 2) and owns the merge decision
  ([`../../docs/playbooks/post-delegation-review.md`](../../docs/playbooks/post-delegation-review.md)).
- **ultracode is user-opt-in + session-level.** A subagent must never self-enable
  it (runaway cost).

## Workflow (the tool) vs N × `Agent`

| Reach for a **Workflow script** when… | Plain `Agent()` calls are enough when… |
|---|---|
| >~10 parallel units, or a loop-until-dry / loop-until-budget | a handful of independent investigations (use §3.3: N agents in one message) |
| results should stay **out** of the main context | you need the output back in context to act on immediately |
| the orchestration is **repeatable** (save + rerun) | it's a one-off |

## Shipped scripts (`fd-` = flightdeck, template-owned)

| Script | Powers | Returns |
|---|---|---|
| [`fd-review-changes.js`](fd-review-changes.js) | `/review ultra` — dimensions → find → adversarial-verify → CONFIRMED | findings list (not a verdict) |
| [`fd-understand-codebase.js`](fd-understand-codebase.js) | `/onboard` at scale (deferred wiring) — parallel Explore → architecture map | structured map (writes nothing) |

Each is **placeholder-free** (reads the diff / areas at runtime via `args`) and
**writes nothing** — the calling skill persists any report. That keeps them
architecture-agnostic and re-runnable.

## Your own workflows

Put project-specific workflow scripts under **`.claude/workflows/local/`**. That
path is `user_owned` in the upgrade classifier, so `install.sh upgrade` never
touches it. Avoid the `fd-` prefix (reserved for template-shipped scripts, which
upgrade *does* manage so you get improvements).

## Authoring notes

- Start every script with `export const meta = { name, description, phases }`
  (pure literal — no variables/among the fields). `name` should match the filename.
- Default to `pipeline()` (no barrier between stages); use `parallel()` only when a
  stage genuinely needs *all* prior results at once.
- `Date.now()` / `Math.random()` / argless `new Date()` are unavailable (they break
  resume) — vary by index, pass timestamps via `args`, stamp after the run.
- Scale to a `+500k`-style budget with `budget.total / remaining()`.
- Full contract: the `Workflow` tool description in-session.
