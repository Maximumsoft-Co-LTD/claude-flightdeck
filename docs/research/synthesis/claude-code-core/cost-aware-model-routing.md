---
topic: cost-aware-model-routing
track: claude-code-core
sources:
  - ../../sources/2026-05-31-anthropic-haiku-4-5.md
  - ../../sources/2026-05-31-anthropic-effort-param.md
  - ../../sources/2026-05-31-augmentcode-model-routing.md
supporting:
  - https://arxiv.org/abs/2406.18665   # RouteLLM — learned hard→strong / easy→cheap routing
  - https://platform.claude.com/docs/en/build-with-claude/prompt-caching
date: 2026-05-31
confidence: high
---

## Pattern observed
Three independent signals converge on the same rule: **match the model tier
to the judgment density of the work, and default to the cheapest tier that
clears your quality gates.**
- **Anthropic pricing/positioning:** Haiku 4.5 = near-frontier coding at ~1/3
  cost & 2×+ speed; Opus ≈ ~5× Sonnet. The intra-family gradient is roughly an
  order of magnitude — model tier is a real cost lever.
- **Anthropic `effort` param:** a *second* axis — dial intelligence vs
  cost/latency within one model before swapping tiers.
- **Practitioner routing (Augment) + RouteLLM (academic):** Opus = planning,
  Sonnet = implementation, Haiku = navigation; learned routers send hard→strong
  and easy→cheap. Same shape from practice and research.

**The template contradicted itself.** `agent-delegation-best-practices.md` §3
already said "Sonnet = implementation DEFAULT", yet every coding agent's
frontmatter was `model: opus` (`backend-engineer`, `frontend-engineer`,
`design-doc-writer`, `orchestrator`, `onboarding-engineer`). So the highest-
volume agents (the two engineers) were pre-paying for Opus on every feature,
against our own documented guidance, and the routing advice lived only in a
read-on-demand doc — not in the always-loaded `sub-agent-workflow.md` rule.

## Why it matters for our SDLC
Implementation is the highest-frequency delegated work in a sprint. Defaulting
the engineers to Opus is the single largest avoidable cost, and it compounds
with the ~15× multi-agent multiplier (see [[when-not-to-parallelize]]).
Sonnet-with-a-design-doc is exactly the regime where the 6-gate review +
zero-fix D-doc are the quality net — the engineer isn't doing unsupervised
hard reasoning. So the cost saving carries **no quality regression** for the
common case, and hard tasks still have a one-line escalation to Opus.

## Proposed template change
- **Type:** rule-update + agent-frontmatter-update + doc-sync
- **Target file(s):**
  - `core/.claude/rules/sub-agent-workflow.md` — new **§1.5 Cost-aware model
    routing**: tier table (Opus/Sonnet/Haiku) with per-agent defaults + cost
    evidence + escalation rule + per-dispatch / Workflow `model` / `effort`
    overrides.
  - `core/.claude/agents/backend-engineer.md` + `frontend-engineer.md` —
    `model: opus` → `model: sonnet`, with a body note explaining the default +
    escalation path.
  - `core/docs/setup/agent-delegation-best-practices.md` §3 — cross-link to
    §1.5 + add Haiku navigation, `effort`, and Workflow `model` notes; keep the
    two in sync.
- **Friction-or-quality:** **cost** (primary) + **clarity**. Removes an
  internal contradiction; reserves Opus for planning/synthesis/foundational
  authoring (orchestrator, design-doc-writer, onboarding-engineer stay Opus).

## Counter-evidence / risks
- A very hard codebase may want Opus engineers. Mitigation: it's a *default*,
  overridable in one line, with an explicit escalation rule ("≥2 rounds without
  passing → Opus"). Agent files are `template_owned` → an upgrade will apply
  the new default, so the CHANGELOG flags it as an upgrade-impact item.

## Status
- [x] Proposed
- [x] In `apply/shipped/`
- [x] Shipped
