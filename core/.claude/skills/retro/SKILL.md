---
name: retro
description: "Use /retro to close the sprint, run a sprint retrospective, wrap up sprint N, or aggregate the live mini-retros from the board. Also: 'ratify the candidate rules', 'promote that lesson to a rule', 'turn the retro lessons into rules' → `/retro ratify`; 'archive old sprints', 'clean up old sprints' → `/retro archive`. Three modes in one skill: sprint close with auto-chained rule ratification, the stand-alone ratification gate, and sprint-folder archiving."
user_invocable: true
---

# /retro — Sprint Close · Rule Ratification · Archive

**Announce:** Using /retro …

**The retro fixes problems immediately — it does not just document them.**
Old `/ratify-rules` and `/archive` are gone; use `/retro ratify` and
`/retro archive`.

## Token budget

- One `Read` of `docs/project/sprints/S<N>/tasks.md` (`limit: 400`) — the
  primary input (the board holds the live mini-retros).
- One `Read` of `docs/project/backlog.md` — for the audit + the highest F#### ID.
- `scripts/backlog.sh sweep` + `index` — sprint-close backlog hygiene (closed
  `## Active` rows → cold archive; index regen). Deterministic bash, 0 LLM tokens.
- `Grep` for everything else (lesson recurrence, candidate rules, sprint scan).
- `Grep` one section of `../../rules/brain-hot.md` (ratify mode) — never full-Read.

---

## Mode 1 — `/retro` (sprint close + auto-chain ratify)

The live per-task mini-retros inside `docs/project/sprints/S<N>/tasks.md` are the
PRIMARY input. The full retro lands in `docs/project/sprints/S<N>/retro.md`. Two
HARD gates block close.

1. **Read the board** — `docs/project/sprints/S<N>/tasks.md`. Missing/empty =
   process loss; flag it in the retro.
2. **Read `docs/project/backlog.md`** — note the highest existing `F####`; open
   rows are candidates for reconciliation at the audit gate.
3. **Scan git log** since sprint open for each touched repo.
4. **Cross-cutting drift** — grep for invariants (contract drift, schema drift,
   observability gaps). Each drift = a finding.
5. **Gather** top wins + top issues (ask the user, or "auto").
6. **Create `docs/project/sprints/S<N>/retro.md`** from the template below.
7. **Classify every action item** — `fix NOW (this commit)` vs `defer (backlog
   row or follow-up)`.
8. **Execute every "fix now" item** — do NOT commit the retro until they land
   (update affected skills + rules in the same commit).

**HARD GATE — Backlog audit (drift blocks close):**
```bash
scripts/backlog.sh check        # Status enum + size cap — must exit 0
scripts/backlog.sh reconcile    # advisory: wip rows that look already-closed in S<N>
```
`check` must pass. Resolve every reconcile flag (set genuinely-shipped rows to
`done S<N>`; the sweep below moves them out). Cite: `Backlog audit: check ✓ · <N>
reconcile flag(s) resolved`.

**HARD GATE — Follow-ups verification (this sprint's rows must not stay `open`):**
- `Grep docs/project/backlog.md '## Follow-ups'` — every `F####` row referencing
  this sprint must end `in-progress`, `consumed-by:<task-id>`, or `wont-do
  (reason)`. `open` = process loss; return the gap to `sprint-retro-author`.
- Cite: `Follow-ups: X consumed · Y new · Z still open · 0 sprint-touched rows left open`.

**Backlog sweep (mechanism, not vigilance — keeps `backlog.md` lean):**
```bash
scripts/backlog.sh sweep        # terminal ## Active rows → archive/backlog-archive.md
scripts/backlog.sh index        # regenerate backlog-index.md from the hot file
```
Run both in the SAME commit as step 12. `sweep` is idempotent and one-line-per-item;
detail stays in the sprint file + `ideas/D<NNN>-*.md` + git — never copied into the
archive (that is what keeps it thin). `## Active` is left **open/wip-only**. The
shipped CI gate (`scripts/backlog.sh check`, wired into
`.github/workflows/ai-workflow-validation.yml`) fails the next PR if a closed/blob
row lingers — and catches the inverse drift too (a shipped item mislabeled
`open`/`verified`). Rule + rationale:
[`../../../docs/setup/index-discipline.md`](../../../docs/setup/index-discipline.md)
"The hot/cold split".

9. **Recurring-lesson promotion** — a finding recurring 2+ times → `sprint-retro-author`
   drafts it under `## Candidate A-rules` in the retro (proposes only; never
   edits `../../rules/brain-hot.md` directly).
10. **Update affected skills + rules** — same commit as fix-now items.
11. **Mark the sprint done in the board** + MOVE its Glance prose into
    `docs/project/sprints/S<N>/retro.md` in the SAME commit (each board is
    self-contained — there is no cross-sprint STATUS).
12. **Commit** — `docs(retro): close sprint S<N>; backlog audit clean; fix-now shipped`.
13. **AUTO-CHAIN ratify** — immediately run Mode 2 (surface candidate A-rules;
    operator-gated before any `brain-hot.md` edit).

**Retro file** (template lives at `../../../docs/project/_templates/retro.md.tmpl`):
sprint header · per-task summary (aggregated mini-retros) · what went well ·
what didn't (root cause each) · drift findings · follow-ups touched · action
items · backlog audit result · `## Candidate A-rules`.

---

## Mode 2 — `/retro ratify` (operator-gated rule landing)

Harvests `## Candidate A-rules` from the latest retro (or all) and walks the
operator through ratify / defer / drop. **Operator ratifies; this never
auto-lands rules.** Forms: `/retro ratify` · `/retro ratify S<N>` · `/retro ratify A0##`.

1. **Gather candidates** — `Grep -n '## Candidate A-rules' docs/project/sprints/*/retro.md`;
   read only the candidate section of each hit. Skip entries already
   `ratified → A0##` or `dropped`.
2. **Filter to un-landed** — for each, `Grep ../../rules/brain-hot.md`
   `## Project-specific rules` for the same gist; already present → mark
   `ratified → A0## (already landed)` and skip.
3. **Decide with the operator, one at a time** — show proposed rule text +
   provenance (which retro, recurrence count). Operator chooses Ratify / Defer /
   Drop-reword. Never ratify silently.
4. **Land each ratified rule:** pick the next free `A###` (highest + 1, no gaps);
   append to `../../rules/brain-hot.md` under `## Project-specific rules` in the
   file's format (**bold short rule**, one sentence, optional `→ ./detail.md`);
   keep that section ≤30 lines (overflow → `<slug>-local.md` + pointer); if the
   rule is mechanical, add a row to `../../../docs/setup/lesson-trigger-map.md`;
   mark the retro entry `ratified → A0## (YYYY-MM-DD)`.
5. **Record deferrals/drops** in the retro entry.
6. **Commit** — `docs(rules): ratify A0## from sprint S<N> retro`.

Loop: `per-task mini-retro → /retro aggregates → sprint-retro-author drafts ## Candidate A-rules → /retro ratify (operator gate) → brain-hot.md A011+`.

---

## Mode 3 — `/retro archive` (move old sprint folders to historical/)

Keeps `docs/project/sprints/` lean — archive everything older than the 3 most
recent sprints. Uses `git mv` (nothing deleted); always confirm first. Forms:
`/retro archive` · `/retro archive S<N>` · `/retro archive list` · `/retro archive restore S<N>`.

1. **Plan** — `scripts/backlog.sh archive-sprints --keep 3` (dry-run) prints the
   closed sprints it would roll to `historical/` (closed = has a `retro.md`).
2. **Show preview** — that dry-run output IS the preview. **Confirm with the user.**
3. **Execute** — `scripts/backlog.sh archive-sprints --keep 3 --apply` runs the
   `git mv` → `docs/project/sprints/historical/S<N>/` + appends
   `historical/INDEX.md` rows. (Equivalent manual `git mv` is fine if you prefer
   per-file confirmation.)
6. **Commit** — `docs(archive): move sprints older than the active window to historical/`.

Restore reverses the moves. **Never delete** (always `git mv`); never archive a
still-open sprint just because it's old; never touch `docs/designs/_templates/`.

---

## Cross-cutting rules

- "Didn't go well" items = process bugs — fix them NOW, this commit.
- Every lesson reaches `../../rules/brain-hot.md` only via the ratify gate
  (never hand-edited in Mode 1).
- Both HARD gates are non-negotiable. Operator ratifies; the skill never
  auto-lands rules.

## See also

- [`../../rules/brain-hot.md`](../../rules/brain-hot.md) — `## Project-specific rules` (A011+) landing zone
- [`../../agents/sprint-retro-author.md`](../../agents/sprint-retro-author.md) — writes `## Candidate A-rules`; proposes, never lands
- [`../../../docs/setup/lesson-trigger-map.md`](../../../docs/setup/lesson-trigger-map.md) — mechanical rule → trigger map
