---
synthesis_source: ../../synthesis/sdlc-with-ai/test-theater-and-legacy-safe-tdd.md
track: sdlc-with-ai
target: core/docs/setup/test-discipline.md, core/.claude/rules/programming-fundamentals.md, core/docs/playbooks/post-delegation-review.md, core/.claude/rules/phase-matrix.md, core/docs/INDEX.md, core/.claude/skills/tdd/SKILL.md, core/.claude/rules/agent-pre-task-ritual.md
type: new-doc + rule-update + playbook-update + matrix-note + new-skill
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-05-31 (doc) · 2026-06-01 (/tdd skill follow-on)
---

## What changes
1. **`core/docs/setup/test-discipline.md`** (NEW) — the reference depth:
   the one principle (tests encode INTENT, not current output), the
   test-theater anti-pattern table, the greenfield bar (red→green, behavioral
   assertions, property/invariant testing, mutation as meta-check), the
   **legacy-safe characterization path** (pin current behavior first, approval/
   golden-master, seams, fitness functions — one test around the change site,
   never a blocked commit), and the **optional opt-in** enforcement hook
   (`nizos/tdd-guard`) with its legacy caveat + agent-config-security tie-in.
2. **`core/.claude/rules/programming-fundamentals.md`** — TDD pre-flight
   sharpened: intent-not-output, named theater anti-patterns, the legacy
   characterization branch, link to the doc.
3. **`core/docs/playbooks/post-delegation-review.md`** — Gate 4b gains a
   test-theater rejection step (when tests were added/changed) + a checklist
   note (`+pr-test-analyzer → reject test theater`).
4. **`core/.claude/rules/phase-matrix.md`** — A001 tie-in note: untested
   legacy (`refactor`/`fix`) → the "test first" phase is a characterization
   test, not a greenfield spec.
5. **`core/docs/INDEX.md`** — `test-discipline` setup-doc row.
6. **`core/.claude/skills/tdd/SKILL.md`** (NEW, 2026-06-01) — operationalizes
   the doc as a `/tdd` slash-command + auto-loading skill: a trigger-based
   (CSO) description so it fires when an agent is about to write a test, a
   **Step 0 mode-classification** (greenfield → red-green-refactor; untested
   legacy → characterization-first), the theater self-check, and a meta-check /
   Gate-4b handoff. Wired as an entry point from `programming-fundamentals.md`
   (TDD pre-flight), `agent-pre-task-ritual.md` Step 4 (skill activation),
   `phase-matrix.md` (A001 tie-in), and the INDEX skills cheat-sheet; the doc
   back-links to it. No placeholders → no installer change. **Turns a passive
   doc into discipline the agent actually runs** at the right moment.

## Why
See synthesis. A001 mandated TDD but never defined test *quality* (theater is
the dominant AI failure mode) nor handled the **legacy/no-tests** case — the
exact adoption concern. This adds both without making greenfield work heavier
and without ever blocking a commit on legacy code.

## Migration / install impact
- All targets are `template_owned` → ship on fresh install + `install.sh
  upgrade`. No placeholder/installer change.
- **Backward-compatible and non-blocking:** default posture is rule +
  review-gate (advisory), not a hard write-blocker. The only enforcement
  mechanism (a TDD hook) is opt-in and explicitly cautioned for legacy repos.
- `brain-hot.md` (A001) is `seed_then_user_extends` and was **not** touched —
  this reinforces A001, doesn't replace it.

## Validation
- `install.sh` (real install) exit 0; `test-discipline.md` ships; theater
  anti-patterns + characterization path present; phase-matrix + Gate 4b notes
  present; 0 stray placeholders; de-domain grep clean.

## Checklist
- [x] Respects `core/` de-domain-specification rule
- [x] Legacy-safe: characterization-first, never a blocked commit (the concern)
- [x] Enforcement hook is opt-in only, with a legacy caveat
- [x] Installer verification passed
- [x] Moved to `shipped/` + INDEX scoreboard + CHANGELOG entry

## Verification evidence (2026-05-31)
```
install exit=0
docs/setup/test-discipline.md ships (~8.6KB); characterization ×11, "test theater" ×5
Gate 4b "Test-theater check" present in shipped post-delegation-review.md
phase-matrix "characterization test" legacy note present
programming-fundamentals "Switch modes" legacy branch present
opt-in hook "NOT shipped by default" present (legacy-safe)
0 stray placeholders in touched files; de-domain grep clean
```

## Follow-on (2026-06-01): operationalized as the `/tdd` skill
```
core/.claude/skills/tdd/SKILL.md ships (install exit 0; present in target)
header has name + trigger/CSO description + ## Token budget (skill-authoring rule 4)
0 placeholders in SKILL.md (no .tmpl needed); de-domain grep clean
entry points wired: programming-fundamentals (TDD pre-flight blockquote),
  agent-pre-task-ritual Step 4, phase-matrix A001 tie-in, INDEX cheat-sheet row
test-discipline.md back-links to the skill (bidirectional)
INDEX counts reconciled: layer table 21, cheat-sheet 18 (was 17/16 — off-by-one fixed)
```
