---
topic: context-discipline-as-design-constraint
track: claude-code-core
sources:
  - ../../sources/2026-05-30-anthropic-agent-skills-authoring.md
  - ../../sources/2026-05-30-anthropic-context-engineering.md
date: 2026-05-30
confidence: high
---

## Pattern observed
Across both Anthropic primary sources, the same thesis recurs: **the scarce
resource for an agent is not capability but attention/context, and the job
of good tooling is to deliver "the smallest set of high-signal tokens" at
each step.** Skills operationalize this via *progressive disclosure*
(metadata always-loaded; bodies and extra files pulled on demand), and
context engineering generalizes it (finite attention budget, "context rot",
just-in-time retrieval, compaction, structured note-taking, subagent
isolation).

Our template already embodies much of this implicitly — the 30-rule
`brain-hot.md` cap, the `## Token budget` skill requirement, trigger-based
(CSO) skill descriptions, the orchestrator/subagent split, LSP-first
navigation. What's missing is (a) the **rationale** stated in one place, and
(b) two specific authoring rules the official guidance makes explicit that
ours leaves implicit.

## Why it matters for our SDLC
This touches the whole lifecycle, but most concretely the **design** and
**review** stages: a skill or CLAUDE.md that bloats context silently
degrades every downstream task. Making context discipline an explicit,
checkable design constraint (not folklore) is the highest-leverage way to
keep the template's edge as the ecosystem adds more skills/agents/MCP tools.

## Proposed template change
- **Type:** doc-update + rule-update
- **Target file(s):** `CONTRIBUTING.md` ("Improving a skill"), `CLAUDE.md`
  (skill-header rule #4), and `METHODOLOGY.md` here (cite the rationale).
- **Sketch:** Add two explicit skill-authoring rules backed by the primary
  sources —
  1. **Split-when-unwieldy:** when a `SKILL.md` grows large or contains
     paths "rarely used together," move them to referenced files
     (progressive disclosure) instead of one fat file.
  2. **Execute-vs-read intent:** every script a skill ships must say whether
     Claude should *run* it or *read* it as reference.
  And add a one-line pointer to the context-engineering "smallest set of
  high-signal tokens" principle as the *why* behind the existing
  `## Token budget` requirement.
- **Friction-or-quality:** **quality** — fewer mis-triggering / context-bloating
  skills shipped, with a citable standard reviewers can point to.

## Counter-evidence / risks
- Our template is architecture-agnostic in `core/`; keep the new rules
  process-level (no stack specifics).
- Risk of over-documenting: these should be 2-3 tight bullets, not an essay —
  the sources are the long-form reference.

## Status
- [x] Proposed (this note exists)
- [x] Shipped as scope (b) → [../../apply/shipped/context-discipline-skill-authoring-rules.md](../../apply/shipped/context-discipline-skill-authoring-rules.md)
  — new `core/docs/setup/skill-authoring.md` (ships) + CONTRIBUTING + CLAUDE.md rule 4.
