---
name: ratify-rules
description: "Close the learning loop — harvest the ## Candidate A-rules that retros proposed, walk the operator through ratify / defer / drop on each, and land the ratified ones into brain-hot.md (next free A0##) + the lesson-trigger map. Use when the user says '/ratify-rules', 'ratify the candidate rules', 'promote that lesson to a rule', 'turn the retro lessons into rules', or after a sprint retro that left candidate A-rules awaiting a decision."
user_invocable: true
---

# /ratify-rules — Lesson → Rule Ratification (operator-gated)

The retro loop **proposes**; this skill **lands**. `sprint-retro-author`
writes recurring lessons into a retro's `## Candidate A-rules` section but —
by design — never edits `brain-hot.md` itself (A-rules are never
auto-applied). This skill is the operator's ratification gate: it gathers
those candidates, you decide on each, and the approved ones become permanent
project rules (`A011+`). That closes the loop from *lesson observed* →
*lesson enforced*.

## Token budget (MANDATORY)

- `Grep` `docs/project/retros/sprint-*.md` for `## Candidate A-rules` — do NOT
  full-Read every retro. Read ONLY the candidate section of each retro that
  has one (offset Read around the grep hit).
- One `Read` of `.claude/rules/brain-hot.md` (the `## Project-specific rules`
  section) to find the next free `A###` and check for duplicates.
- `Grep` `lesson-trigger-map.md` for an existing row before adding one.
- No subagents — this is a short interactive edit, not an exploration.

## Usage

- `/ratify-rules` — scan all retros for un-landed candidates, decide on each
- `/ratify-rules S<N>` — scope to a single sprint's retro
- `/ratify-rules A0##` — land one specific candidate by its proposed number

## Steps

1. **Gather candidates.** `Grep -n '## Candidate A-rules'`
   `docs/project/retros/sprint-*.md`. For each hit, Read just that section. A
   candidate already marked `ratified → A0##` or `dropped — …` is **done** —
   skip it. The live set is everything still labelled as a proposal.
2. **Filter to un-landed.** For each candidate, `Grep` `brain-hot.md`'s
   `## Project-specific rules` for the same rule (by gist / proposed number).
   Already present → mark the retro entry `ratified → A0## (already landed)`
   and skip. Don't double-land.
3. **Decide with the operator — one candidate at a time.** Show the proposed
   rule text + its provenance (which retro, the recurring lessons behind it,
   how many sprints it recurred). Ask the operator to choose:
   - **Ratify** — it earns a permanent rule (the bar: it recurred 2+ times or
     the operator deems it load-bearing).
   - **Defer** — keep watching; not enough signal yet. Leave the candidate as
     a proposal (optionally log it in `docs/project/FOLLOWUPS.md`).
   - **Drop / reword** — won't become a rule (or needs rewording first).
   Never ratify silently — the operator's call is the gate.
4. **Land each ratified rule:**
   1. **Pick the next free `A###`** — scan `## Project-specific rules` for the
      highest existing `A0##`; use the next integer. **No gaps** (document it
      if you must skip one). A011 is the first project rule.
   2. **Append to `brain-hot.md`** under `## Project-specific rules`, in the
      file's format: **bold short rule**, one sentence, optional
      `→ ./detail-file.md` link. Replace the `A011 — _your first project rule_`
      placeholders if they're still there.
   3. **Keep the section lean (≤ 30 lines).** If it would overflow, factor the
      detail into a dedicated `<slug>-local.md` rule file and leave a one-line
      pointer in `brain-hot.md` (the file's own guidance).
   4. **If the rule is mechanical** ("if touching X → apply Y"), add a row to
      [`../../../docs/setup/lesson-trigger-map.md`](../../../docs/setup/lesson-trigger-map.md)
      so it fires in the pre-task ritual, not just at review.
   5. **Mark the retro entry** `ratified → A0## (YYYY-MM-DD)` so it never
      re-surfaces as a live candidate.
5. **Record deferrals / drops** in the retro entry too (`deferred — <why>` /
   `dropped — <why>`), so the next `/ratify-rules` run doesn't re-prompt them.
6. **Commit** — `docs(rules): ratify A0## from sprint S<N> retro` (one commit;
   include the brain-hot edit + lesson-trigger-map row + retro annotations).

## Rules

- **Operator ratifies; the skill never auto-lands.** This mirrors the A-rule
  principle — a rule that fires on every task is too load-bearing to add
  without a human sign-off.
- **Recurrence is the bar.** A lesson that showed up once is a candidate, not
  a rule. 2+ occurrences (or an explicit operator call) earns `A011+`.
- **No gaps in `A###`.** Sequential from A011; if you skip, say why in the
  rule line.
- **Keep `brain-hot.md` lean.** It's auto-loaded every session — overflow the
  `## Project-specific rules` section into a `<slug>-local.md` file rather than
  letting it grow unbounded.
- **Mechanical rules also get a trigger-map row** — otherwise they only catch
  problems at Gate 4 instead of preventing them in the ritual.

## Where this sits in the loop

```
per-task mini-retro (A009)  →  /retro aggregates  →  sprint-retro-author drafts
   ## Candidate A-rules  →  /ratify-rules (operator gate)  →  brain-hot.md A011+
                                                           →  lesson-trigger-map row
```

## See also

- [`../retro/SKILL.md`](../retro/SKILL.md) — Step 9 surfaces recurring lessons; this skill lands them
- [`../../agents/sprint-retro-author.md`](../../agents/sprint-retro-author.md) — writes the `## Candidate A-rules` this skill consumes (it proposes, never lands)
- [`../../rules/brain-hot.md`](../../rules/brain-hot.md) — the `## Project-specific rules` (A011+) landing zone + format
- [`../../../docs/setup/lesson-trigger-map.md`](../../../docs/setup/lesson-trigger-map.md) — where mechanical rules also get a row
