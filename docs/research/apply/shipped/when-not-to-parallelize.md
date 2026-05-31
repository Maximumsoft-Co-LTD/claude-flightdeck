---
synthesis_source: ../../synthesis/claude-code-core/when-not-to-parallelize.md
track: claude-code-core
target: core/.claude/rules/sub-agent-workflow.md, core/docs/playbooks/parallel-conflict-prevention.md
type: rule-update + playbook-update
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-05-31
---

## What changes
1. **`core/.claude/rules/sub-agent-workflow.md`** — new **§1.0 "When NOT to
   use multi-agent"** placed *before* the §1 decision tree: states the ~15×
   token cost (Anthropic) and the context-fragmentation failure mode
   (Cognition + MAST), and the rule "default to ONE well-briefed agent;
   parallelize only when work is provably disjoint AND read-heavy/independent;
   compress long single tasks, don't split them."
2. **`core/docs/playbooks/parallel-conflict-prevention.md`** — new **Step 0
   "is multi-agent even the right call?"** before the 4 layers, cross-linking
   §1.0.

## Why
See synthesis. The template was strong on *how to parallelize safely* but had
no explicit, evidence-backed gate for *whether to parallelize at all*. This
adds it without reversing the existing "default to inline / serialize" stance.

## Migration / install impact
- Both files are in `core/` → ship on fresh install + via `install.sh upgrade`
  (template_owned). No placeholder / installer change.
- Backward-compatible; reinforces existing guidance.

## Validation
- `install.sh` (real install) exit 0; §1.0 + Step 0 present in shipped files;
  0 stray placeholders; de-domain grep clean.

## Checklist
- [x] Respects `core/` de-domain-specification rule (verified: idip/agg grep empty)
- [x] Keeps the "when parallel IS right" path intact (guides, doesn't ban)
- [x] Installer verification passed
- [x] Moved to `shipped/` + INDEX scoreboard + CHANGELOG entry

## Verification evidence (2026-05-31)
```
install exit=0
§1.0 "When NOT to use multi-agent" → present in shipped sub-agent-workflow.md
Step 0 "is multi-agent even the right call?" → present in shipped playbook
~15× cost evidence → present (3 matches)
0 stray placeholders in both files; de-domain grep clean
```
