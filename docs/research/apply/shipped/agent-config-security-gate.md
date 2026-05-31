---
synthesis_source: ../../synthesis/claude-code-core/committed-agent-config-is-a-supply-chain-surface.md
track: claude-code-core
target: core/.claude/rules/phase-matrix.md, core/docs/setup/agent-config-security.md, core/docs/setup/permission-profiles.md, core/docs/setup/secret-handling.md
type: rule-update + doc-update
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-05-31
---

## What changes
1. **`core/.claude/rules/phase-matrix.md` — Phase 7 (Security review) triggers:**
   add a bullet so the security gate fires on any diff touching
   `.claude/settings*.json`, `.mcp.json`, `.claude/hooks/*`, or introducing
   the keys `ANTHROPIC_BASE_URL` / `enableAllProjectMcpServers`.
2. **NEW `core/docs/setup/agent-config-security.md`:** canonical trust-model
   doc — committed `.claude/` config is executable; the three CVE vectors;
   the review rule + reviewer checklist.
3. **`core/docs/setup/permission-profiles.md`:** add a "config is executable"
   callout near the auditor's-check section + link the new doc.
4. **`core/docs/setup/secret-handling.md`:** add `ANTHROPIC_BASE_URL`
   redirection to the anti-patterns list + link the new doc.

## Why
See synthesis. Committed agent config is a CVE-class RCE/exfil surface
(CVE-2025-59536); our template ships that exact surface with no review
trigger. This makes the existing security gate fire when it changes.

## Migration / install impact
- All edits are in `core/` → ship to every project via `install.sh` and to
  existing projects via `install.sh upgrade` (phase-matrix + setup docs are
  `template_owned`, so upgraders pick it up).
- No installer/placeholder change. No new `.tmpl` vars. The JSON settings
  templates are **not** edited (JSON can't carry comments; the guidance lives
  in docs + the phase-matrix trigger instead).
- Backward-compatible: only adds a trigger + docs.

## Validation
- `install.sh` dry-run into /tmp → new doc + edited files present; no stray
  `{{PLACEHOLDER}}`.
- `grep -n "ANTHROPIC_BASE_URL" core/.claude/rules/phase-matrix.md` shows the
  trigger added.
- De-domain check: new doc + trigger contain no `idip`/`agg`/tech-stack terms.

## Checklist
- [x] Respects `core/` de-domain-specification rule (verified: grep for idip/agg/IDIP = empty)
- [x] No skill/agent header rules affected
- [x] Installer verification passed (`install.sh` exit 0; new doc + trigger ship; 0 stray placeholders)
- [x] Moved to `shipped/` + INDEX scoreboard updated + CHANGELOG `## Unreleased` entry

## Verification evidence (2026-05-31)
```
install exit=0
docs/setup/agent-config-security.md → shipped (4670 bytes)
phase-matrix.md ANTHROPIC_BASE_URL trigger → present (1 match)
stray {{PLACEHOLDER}} in changed files → none
de-domain grep (idip|aggegator|IDIP-|TG-AGG) → none
```
