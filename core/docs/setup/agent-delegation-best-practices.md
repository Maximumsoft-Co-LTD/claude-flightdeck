# Agent Delegation — Best Practices

> When + how to delegate to keep main context light. Read on demand.
> Companion to `delegation-checklist.md` (this file = WHEN, that file = HOW 7-block brief).

## §1 Core principle

**Main = orchestrator + reviewer + decision-maker. Agents = read/write laborers.** Before any task that opens a file >500 lines or uses tools ≥10 rounds → ask "can I delegate this?"

## §2 Decision matrix

| Work type | Delegate? | Model | Note |
|---|---|---|---|
| Mechanical code edit (spec is clear) | Yes | Sonnet | low judgment |
| TDD test scaffolding | Yes | Sonnet | pattern-based |
| Sprint hygiene (rows / INDEX / backlog flip) | Yes | Sonnet | mechanical |
| Long test / build runs | Yes | Sonnet | binary output |
| Simulation / numerical runs | Yes | Sonnet | long-running, bounded |
| Research deep-dive (bundle + corpus + design doc) | Yes | Opus | synthesis |
| Cross-module audit | Yes | Opus | wide context |
| Codebase exploration ≥3 areas | Yes | Explore × 1-3 | read-only |
| Live browser capture / play-through | No (MAIN) | — | live-context only |
| Reverse-engineering initial decode | No (MAIN) | — | wire-protocol scope emerges |
| Wire-protocol probing (curl + DevTools) | No (MAIN) | — | scope emerges |
| Decision / path selection | No (MAIN) | — | user-facing |
| Memory drawer writes | No (MAIN) | — | 1-line, faster solo |
| Post-delegation review | No (MAIN) | — | trust-but-verify |
| Visual frame audit | No (MAIN) | — | qualitative judgment |

**Rule of thumb**: if you can't tell the agent which file to read → don't delegate.

## §3 Model selection

> Always-loaded summary of this section lives in
> [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md)
> §1.5 (with per-agent defaults + cost evidence). Keep the two in sync.

- **Haiku** — bulk rename, pattern grep, 1-line edits, read-heavy navigation / `Explore` fan-out (~1/3 cost, 2×+ speed)
- **Sonnet** — implementation w/ spec, TDD, sprint hygiene, smoke tests, sims, code review (DEFAULT for code)
- **Opus** — design docs, hypothesis ranking, cross-component synthesis, root-cause analysis, planning/orchestration

Ambiguous → Sonnet first; escalate to Opus only after Sonnet runs ≥2 rounds
without passing. Before jumping a whole tier, try the `effort` param
(low/med/high) to trade intelligence vs cost *within* one model. In Workflow
scripts, set `opts.model` per stage (cheap for verify/Explore, Opus for
synthesis); omit to inherit the session model.

## §4 Context-budget triggers

| Main % | Action |
|---|---|
| <50% | normal — delegate by reason (parallel work, large files) |
| 50-70% | delegate aggressively — Reads >300 L, multi-grep, Bash batches → agent |
| 70-85% | MUST delegate; main = orchestration only |
| >85% | STOP + warn user `/compact` or `/clear` |

**Hot-spot files** (always delegate Read of):
- Any file >5 K lines — Grep first, narrow Read via agent
- Any spec doc >1 K lines — Grep TOC + targeted section
- Any data dump (JSONL / CSV) — filter-script via agent
- Any big sprint / backlog file — use the slim index (per L154)
- Any big test file — offset+limit, never full

## §5 Brief template (7-block, MANDATORY)

Every Agent invocation:
1. **Why this exists** — user direction (verbatim) + prior-session context
2. **Repo / file map** — exact file:line + size + read-only vs write list
3. **Staged steps** — numbered + time estimates
4. **Hard constraints** — DO NOT list (push? deploy? scope-lock?)
5. **Reuse patterns** — commit shas, helpers, fixtures
6. **After-completion gates** — exact commands (build, test, git diff stat, grep counts)
7. **Report format** — under N words, fields (SHA, test count, deviations)

Full template: `delegation-checklist.md` §"Delegation Call".

## §6 Project rule overlay (always include in brief when relevant)

When a project has rules that bite for the kind of task you're delegating, paste them inline so the agent doesn't have to guess. Examples:

- Architectural-boundary rule (A001) — grep gate the agent should run before commit
- Contract-first rule (A003) — produce the contract commit first, then the consuming code
- Observability rule (A008) — every new handler must emit a span / metric
- Verification rule (L141) — `git diff HEAD --stat` non-empty before reporting done

Boilerplate to paste into a sensitive brief:
> "Per <rule-ID>: <one-line rule>. Before commit: <one-line gate>."

## §7 Parallel vs sequential

- **Single message, N Agent calls** — independent work, no shared files (max 3)
- **Sequential** — output A is input to B
- **Explore × 1-3 parallel** — mapping unknown codebase pre-implementation
- **Same-file edits** — strictly sequential

## §8 Post-delegation review (expanded)

1. `git log --oneline -3` — confirm commit landed
2. `git diff HEAD~N HEAD --stat` — file scope == brief
3. `git show <sha> -- <key-file>` — read the actual diff (not the stat)
4. Component test — the project's `test` command scoped to the changed module
5. Cross-check predicate vs design AC line-by-line
6. Verify wiring (composition root / app bootstrap)
7. Mark task completed

**Red flags**: extra files outside scope · unauthorized test additions · indirect proxies without commit-message documentation.

## §9 Anti-patterns

- Agent pushes commits (security, must surface)
- Agent deploys to live (irreversible, live system)
- Agent decides path selection (decision = user-facing)
- Agent does live browser capture (live-context only)
- Read in main first, then delegate-with-Read (double-cost)
- Spawn >3 parallel agents (harness throttle + main can't review)

## §10 Self-audit (every ~10 turns)

- Estimate context %
- "What I did in the last 5 turns — could it have been delegated?"
- If yes → save a lesson for future similar work

## Cross-refs

- `delegation-checklist.md` — 7-block HOW reference
- `workflow-master.md` — 7-stage sprint workflow (S1-S7)
