---
synthesis_source: ../../synthesis/claude-code-core/security-review-as-a-skill.md
track: claude-code-core
target: core/.claude/skills/security-review/SKILL.md, core/.claude/rules/phase-matrix.md, core/docs/setup/agent-config-security.md, core/docs/INDEX.md
type: new-skill + rule-update + doc cross-link
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-06-01
---

## What changes
1. **`core/.claude/skills/security-review/SKILL.md`** (NEW) — operationalizes
   Phase 7 as a `/security-review` slash-command + auto-loading skill:
   - **Diff-aware** (Step 0 scopes the pending diff; stops if no trigger is hit
     — no manufactured findings).
   - **Semantic per-dimension** review across the 10-family taxonomy (Step 1),
     only the dimensions the diff touches; reasons about source→sink→reachable
     path, not regex.
   - **False-positive filtering as a first-class Step 2** (drops DoS /
     rate-limit / generic-validation / open-redirect / no-reachable-path) — the
     thing that keeps a security gate from becoming ignorable noise.
   - **Supply-chain (slopsquatting) dimension** — verify every new manifest
     dependency exists + is the intended package + is pinned; a package you
     can't confirm exists is a STOP (install-time RCE).
   - **Agent-config dimension** — runs the existing `agent-config-security.md`
     reviewer checklist (no duplication).
   - Severity + remediation per finding; PASS / FINDINGS / BLOCK verdict.
   - **Opt-in** prompt-injection PostToolUse hook noted (lasso-security/claude-hooks),
     NOT shipped — same posture as the tdd-guard hook.
2. **`core/.claude/rules/phase-matrix.md`** — Phase-7 section now says to invoke
   `/security-review`, and the trigger list gains **"new dependency added to a
   manifest"** (slopsquatting).
3. **`core/docs/setup/agent-config-security.md`** — notes the Phase-7 review now
   runs via `/security-review` (agent-config is one of its dimensions).
4. **`core/docs/INDEX.md`** — `/security-review` cheat-sheet row; counts
   reconciled (layer table 22; cheat-sheet 19).

## Why
See synthesis. Phase 7 was the only review phase with no runnable procedure —
in practice ad-hoc or skipped. This gives it a concrete, low-noise, diff-aware
procedure (same move as `/tdd` ← `test-discipline.md`), folds in the new
AI-specific **slopsquatting** vector our dependency-adding engineers are exposed
to, and reuses the agent-config checklist rather than duplicating it.

## Migration / install impact
- All targets `template_owned` → ship on fresh install + `install.sh upgrade`.
- **No placeholders** in the new skill → no `.tmpl`, no installer change.
- **Non-blocking by default:** it's a review-gate skill, not a write-blocker;
  the only enforcement surface (the injection hook) is opt-in and cautioned.
- De-domain-specified: generic vuln classes + generic manifest filenames only.

## Validation
- `install.sh` (real install) exit 0; `/security-review` ships; header has
  name + trigger/CSO description + `## Token budget`; 0 stray placeholders;
  de-domain grep clean; `site/` + `pages.yml` not shipped; Phase-7 + INDEX
  cross-refs present in the shipped target.

## Checklist
- [x] Respects `core/` de-domain-specification rule
- [x] FP-filtering is a mandatory step (anti-noise — the gate stays usable)
- [x] Slopsquatting dimension added (live install-RCE gap closed)
- [x] Reuses agent-config-security.md (no duplication)
- [x] Injection hook is opt-in only, with the agent-config caveat
- [x] Installer verification passed
- [x] Shipped + INDEX scoreboard + CHANGELOG entry
