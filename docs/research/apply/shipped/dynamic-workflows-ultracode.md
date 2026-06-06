---
synthesis_source: synthesis/claude-code-core/dynamic-workflows-and-ultracode.md
target: core/.claude/skills/review/SKILL.md + core/.claude/workflows/** + core/.claude/rules/sub-agent-workflow.md
status: shipped
pr: local (branch feat/dynamic-workflows-ultracode; upgrade-eligible)
---

## What changes

Apply Claude Code's **dynamic workflows + ultracode** to the template **without
eroding the human-verified rigor**, as one A+B+C set shipped in 5 validator-green
commits:

- **C1** research notes (source + synthesis) establishing the seam: fan-out /
  ultracode for READ/VERIFY/BREADTH; writes + the 6-gate stay human-verified.
- **C2 (B)** ship `core/.claude/workflows/` — `fd-review-changes.js`
  (dimensions → find → 3-vote adversarial verify → CONFIRMED), `fd-understand-codebase.js`
  (parallel Explore → architecture map), README. Both placeholder-free + write
  nothing. Upgrade classifier: `.claude/workflows/local/**` = user_owned;
  `fd-*.js` = template_owned.
- **C3 (A)** `/review ultra` — a 5th `/review` mode that runs `fd-review-changes`.
  Wired into INDEX cheat-sheet + workflows pointer + CLAUDE.md.tmpl table.
- **C4 (C)** `§1.6 Dynamic workflows & ultracode` in `sub-agent-workflow.md` —
  ultracode flips §1.0's default for read/verify/breadth, invariants unchanged
  (writes single-threaded, 6-gate orchestrator-verified, no subagent self-enable);
  Workflow-vs-N×Agent decision, `+500k` budget directives, dynamic `/loop` caveat.
  phase-matrix A004 cross-ref.
- **C5** this loop close + CHANGELOG.

## Why (link to synthesis)

[`synthesis/claude-code-core/dynamic-workflows-and-ultracode.md`](../../synthesis/claude-code-core/dynamic-workflows-and-ultracode.md)
— the load-bearing point is that a Workflow returns *conclusions, not a merge-ready
diff*, so it AUGMENTS the 6-gate (parallel breadth + adversarial verification, fewer
false findings surviving) but never replaces it. Grounded in the live Workflow /
ScheduleWakeup tool contracts (primary) + [[autonomous-fanout-orchestration]].

## Migration / install impact

- New installs get `.claude/workflows/` + `/review ultra` directly.
- Existing installs: upgrade ships the `fd-*.js` scripts (template_owned) and never
  touches `.claude/workflows/local/**` (user_owned).
- No `install.sh` change needed — `copy_tree` ships the dir; scripts are
  placeholder-free so they skip the render pass.

## Validation

- `bash scripts/validate-skills.sh` green at every commit (0 warn / 0 fail).
- `./install.sh <tmp> --force` ships `.claude/workflows/{fd-review-changes.js,
  fd-understand-codebase.js,README.md}` with 0 leftover placeholders.
- `jq` confirms the upgrade classifier is valid JSON with `.claude/workflows/local/**`.
- review SKILL.md 211L (< 250), CLAUDE.md.tmpl 184L (< 200).
- Note: workflow scripts use the runtime's `export const meta` + top-level `return`
  format → not standalone-typecheckable; marked `// @ts-nocheck` (validated by shape,
  not `node --check`).

## Deferred (next phase)

- **D** wire `/onboard` scan to `fd-understand-codebase`.
- **E** `/work` parallel legs → `pipeline` (worktree) + orchestrator runs the 6-gate.
- **F** `/status watch` / `/ship watch` via dynamic `/loop`.
- `fd-audit-security.js` (Phase-7 loop-until-dry); validator extension to lint
  workflow `meta`.
