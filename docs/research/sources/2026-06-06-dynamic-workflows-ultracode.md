---
url: (live Claude Code tool contract — primary; secondary blogs listed below)
type: research-study
date_found: 2026-06-06
date_processed: 2026-06-06
topics: [claude-code-core]
quality: 5
status: distilled
---

## TL;DR

Claude Code shipped **dynamic workflows** (the `Workflow` tool — a JS
orchestration script the runtime executes *outside the agent's context*: fan-out
via `agent()/parallel()/pipeline()`, budget-scaled, resumable, up to ~1000 agents
per run) and **ultracode** (a session mode in which authoring + running a Workflow
for every substantive task becomes the *standing default*, token cost no object).
This study asks how to apply it to our template **without eroding our rigor**
(default-single-agent §1.0, the human-verified 6-gate).

## Key takeaways (primary = the live tool contract)

- **Workflow = orchestration-as-code.** A script with `export const meta` +
  `agent / parallel / pipeline / phase / log`. Results live in script variables,
  not the context window; only the final synthesis returns to the session. The
  script (not the model turn-by-turn) holds the plan → repeatable + resumable.
- **`pipeline()` is the default; `parallel()` is a barrier.** Fan out → reduce →
  synthesize. Per-item pipelining beats a barrier unless a stage genuinely needs
  *all* prior results at once.
- **`budget` object + `+500k` directives.** `budget.total / spent() / remaining()`
  let a script scale fan-out/round-count to a hard token ceiling (loop-until-budget,
  loop-until-dry).
- **ultracode is session-scoped + user-opt-in.** It flips the default toward
  "always orchestrate"; it is NOT something a subagent should self-enable (runaway
  cost). For multi-phase work it runs several workflows in sequence.
- **dynamic `/loop` (`ScheduleWakeup`).** Self-paced iteration — the agent picks
  the next wake delay (poll CI/deploy) instead of a fixed interval. Re-fires the
  same prompt, so it must only pair with **idempotent, re-entrant** prompts, never
  one-shot commands.
- **Canonical pattern = "review across dimensions → adversarially verify each
  finding."** The tool's own worked example is exactly a review pipeline (dimensions
  → find → refute-vote → keep survivors) — the highest-fit use for our `/review`.
- **Quality patterns:** loop-until-dry, adversarial verify (N skeptics refute),
  perspective-diverse verify (distinct lenses), judge panel, completeness critic,
  multi-modal sweep, no-silent-caps (log what was dropped).

> **Source-reliability note.** The API + behavior above are taken from the **live
> `Workflow` / `ScheduleWakeup` tool contracts in-session** (authoritative). A
> companion research agent also surfaced secondary write-ups (an Anthropic
> "dynamic workflows" launch post, `code.claude.com/docs/.../workflows`,
> `.../scheduled-tasks`, Claude API `task_budget` beta, plus Medium/community
> guides). Those corroborate the primary contract but their exact URLs/dates are
> **unverified** — cited as corroboration only, not load-bearing.

## Secondary sources (unverified — corroboration only)

- code.claude.com/docs/en/workflows · code.claude.com/docs/en/scheduled-tasks
- code.claude.com/docs/en/costs · platform.claude.com/docs/en/build-with-claude/task-budgets
- claude.com/blog/introducing-dynamic-workflows-in-claude-code (date unconfirmed)

## Relevance to our template

Builds directly on [[autonomous-fanout-orchestration]]: that study set the
*when-not-to* gate (writes single-threaded, ~15× cost, brief fully, cap width);
this one adds the *substrate* (Workflow tool + ultracode) and the *seam* — use it
for READ/VERIFY/BREADTH, keep WRITES + the 6-gate human-verified. → drives
[[dynamic-workflows-and-ultracode]].
