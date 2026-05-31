# Authoring a Skill

> How to write a `.claude/skills/<name>/SKILL.md` that the model actually
> loads at the right time and that doesn't bloat context. The guiding
> principle, from Anthropic's own guidance, is to deliver **"the smallest
> set of high-signal tokens that maximize the likelihood of your desired
> outcome"** — a skill is a tool for *just-in-time* context, not a place to
> dump everything.

## The four rules

### 1. Header: `name`, `description`, `## Token budget` — all required

Every `SKILL.md` ships these. The `name` + `description` are **preloaded
into the system prompt** — they are the only thing the model sees when
deciding whether to load the skill. The `## Token budget` section forces you
to state what the skill is allowed to pull into context.

### 2. Description = triggers, not a summary (CSO)

The `description:` decides whether the model auto-loads the skill, so lead
with **when to use it** — concrete user phrases, slash-command names, and
failure *symptoms* (e.g. "after a subagent returns", "tests flaky", "merge
gone wrong"). Do **not** write a workflow summary: a description that
explains *how the skill works* makes the model think it already knows enough
and skip the skill body. (Claude-Search-Optimization.)

### 3. Split when unwieldy — progressive disclosure

Structure a skill "like a well-organized manual: a table of contents, then
specific chapters, then a detailed appendix." Keep `SKILL.md` lean; move
content that is **large, or rarely used together**, into referenced files the
model pulls **on demand**:

- `references/` — deep material the model reads when it needs it.
- `scripts/` — mechanical loops the model runs.

Moving rarely-co-used paths out of the main file directly cuts the tokens a
trigger pays for. If `SKILL.md` is growing past "a page you'd actually read
start-to-finish," split it.

### 4. State execute-vs-read intent for every script

For each script a skill ships, say explicitly whether the model should
**execute** it (a deterministic operation — run it, don't read it) or **read**
it as reference (an example/pattern — read it, don't run it). Ambiguity wastes
context and causes the model to do the wrong one.

## Why (the rationale to cite in review)

These rules all serve one constraint: **context is a finite, degrading
resource** ("context rot" — more tokens eventually *lower* quality). A skill
that loads everything up front, or triggers when it shouldn't, spends the
attention budget on low-signal tokens. Progressive disclosure + sharp
triggers + a stated token budget are how a skill stays high-signal.

(Primary sources: Anthropic *Equipping agents for the real world with Agent
Skills* and *Effective context engineering for AI agents*.)

## Authoring checklist

- [ ] `name` + trigger/symptom-based `description` (CSO) + `## Token budget`.
- [ ] `SKILL.md` is lean; large / rarely-co-used material is in `references/`.
- [ ] Every script is marked **execute** or **read**.
- [ ] The token budget names what the skill pulls into context (and what it
      deliberately does *not*).

## Related

- [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md)
  — when to route work to a skill vs a subagent
- [`agent-config-security.md`](./agent-config-security.md) — if your skill
  ships hooks/scripts, they're an execution surface; review them
- [`lesson-trigger-map.md`](./lesson-trigger-map.md) — mapping triggers to
  the rules a skill should enforce
