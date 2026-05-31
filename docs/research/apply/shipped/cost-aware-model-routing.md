---
synthesis_source: ../../synthesis/claude-code-core/cost-aware-model-routing.md
track: claude-code-core
target: core/.claude/rules/sub-agent-workflow.md, core/.claude/agents/backend-engineer.md, core/.claude/agents/frontend-engineer.md, core/docs/setup/agent-delegation-best-practices.md
type: rule-update + agent-frontmatter-update + doc-sync
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-05-31
---

## What changes
1. **`core/.claude/rules/sub-agent-workflow.md`** — new **§1.5 Cost-aware
   model routing** (after §1, before §2): tier table mapping Opus / Sonnet /
   Haiku to work classes + the agents that default to each, the cost evidence
   (Haiku ~1/3 cost & 2×+ speed; Opus ≈ ~5× Sonnet; ties to the §1.0 ~15×
   multi-agent multiplier), an escalation rule (Sonnet first → Opus after ≥2
   failing-gate rounds), and per-dispatch overrides (`Agent` frontmatter,
   Workflow `opts.model` per stage, `effort` within a tier).
2. **`core/.claude/agents/backend-engineer.md` + `frontend-engineer.md`** —
   `model: opus` → `model: sonnet`, plus a body blockquote stating the
   cost-aware default + how to escalate to Opus.
3. **`core/docs/setup/agent-delegation-best-practices.md` §3** — cross-linked
   to §1.5; added Haiku-navigation, `effort`, and Workflow-`model` notes so the
   deep doc and the always-loaded summary stay in sync.

## Why
See synthesis. The engineers defaulted to Opus against the template's *own*
documented routing (§3 said Sonnet = implementation default), and the routing
guidance wasn't in the always-loaded rule. This makes routing conscious +
evidence-backed and removes the contradiction. orchestrator / design-doc-writer
/ onboarding-engineer intentionally **stay Opus** (planning / synthesis /
foundational authoring).

## Migration / install impact
- `sub-agent-workflow.md` + the delegation doc are `template_owned` → ship on
  fresh install + `install.sh upgrade`.
- **Agent files are also `template_owned`** → `install.sh upgrade --apply-safe`
  will change an installed project's `backend-engineer` / `frontend-engineer`
  default from `opus` to `sonnet`. **Upgrade-impact (flagged in CHANGELOG):**
  teams that want Opus engineers set `model: opus` in their own copy or
  dispatch with an explicit override. No placeholder/installer change; the
  `{{AGENT_PREFIX}}` token in the §1.5 table renders as usual.

## Validation
- `install.sh` (real install) exit 0; §1.5 present in shipped
  `sub-agent-workflow.md`; both engineers render `model: sonnet`; 0 stray
  placeholders in touched files; de-domain grep clean.

## Checklist
- [x] Respects `core/` de-domain-specification rule
- [x] Keeps Opus where judgment density warrants it (planning/synthesis agents)
- [x] Escalation path documented (no hard downgrade — overridable in one line)
- [x] Installer verification passed
- [x] Moved to `shipped/` + INDEX scoreboard + CHANGELOG entry

## Verification evidence (2026-05-31)
```
install exit=0
§1.5 "Cost-aware model routing" → present in shipped sub-agent-workflow.md (line 80)
backend-engineer + frontend-engineer → model: sonnet
  (orchestrator + design-doc-writer stay opus; senior-tech-lead stays sonnet)
Haiku "~1/3 the cost" evidence present; {{AGENT_PREFIX}} rendered → tsvc-orchestrator
0 stray placeholders in touched files; de-domain grep clean
```
