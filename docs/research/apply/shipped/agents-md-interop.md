---
synthesis_source: ../../synthesis/adjacent-tools/agents-md-cross-tool-interop-via-pointer.md
track: adjacent-tools
target: core/AGENTS.md, core/.flightdeck-upgrade.json, install.sh, core/CLAUDE.md.tmpl, README.md
type: new-file + installer-wiring + doc-update
status: shipped
pr: "local commit (main); install.sh upgrade-eligible"
date: 2026-05-31
---

## What changes
1. **NEW `core/AGENTS.md`** — thin pointer to `CLAUDE.md` for cross-tool
   agents (Codex/Cursor/Copilot/Gemini CLI/…), plus the stable
   non-negotiables. No placeholders (copied verbatim). Single source of
   truth stays `CLAUDE.md`.
2. **`core/.flightdeck-upgrade.json`** — `AGENTS.md` added to
   `seed_then_user_extends` (upgrade never auto-overwrites a user-extended
   copy).
3. **`install.sh`** — `$TARGET/AGENTS.md` added to the re-install backup loop
   (preserved like `CLAUDE.md`).
4. **`core/CLAUDE.md.tmpl` + `README.md`** — note that AGENTS.md is a pointer
   and CLAUDE.md is canonical; AGENTS.md added to the "What you get" tree.

## Why
See synthesis. `CLAUDE.md` is read only by Claude Code; AGENTS.md is the
Linux-Foundation cross-tool standard (~21 tools, 60k+ repos) with empirical
benefit (~28% runtime / ~16% tokens). The template's rules should bind every
agent on the repo, not just Claude Code.

## Migration / install impact
- `core/AGENTS.md` ships on fresh install (copied verbatim). Existing
  projects get it via `install.sh upgrade` — classified
  `seed_then_user_extends`, so it's flagged NEEDS-MERGE rather than clobbered
  if the user already has one.
- No new placeholder / no `sed` change (AGENTS.md is plain, not `.tmpl`).
- Re-install backs up an existing AGENTS.md (same path as CLAUDE.md).
- Backward-compatible.

## Validation
- `install.sh` dry-run + real install into /tmp → `AGENTS.md` present at
  target root, points to CLAUDE.md, 0 placeholders.
- `jq . core/.flightdeck-upgrade.json` parses; `AGENTS.md` in
  `seed_then_user_extends`.
- De-domain check on `core/AGENTS.md` (no idip/agg/tech-stack).

## Checklist
- [x] Respects `core/` de-domain-specification rule
- [x] No skill/agent header rules affected
- [x] Installer verification passed
- [x] Moved to `shipped/` + INDEX scoreboard + CHANGELOG entry

## Verification evidence (2026-05-31)
```
jq: AGENTS.md ∈ seed_then_user_extends → OK
fresh install exit=0; AGENTS.md present at target root; → CLAUDE.md (8 refs);
  0 stray placeholders; de-domain grep clean
re-install (no --force): user's customized AGENTS.md preserved at
  AGENTS.md.backup-20260531-103215 (not clobbered)
```
