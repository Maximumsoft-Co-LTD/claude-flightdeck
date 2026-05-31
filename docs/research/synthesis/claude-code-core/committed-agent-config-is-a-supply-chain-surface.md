---
topic: committed-agent-config-is-a-supply-chain-surface
track: claude-code-core
sources:
  - ../../sources/2026-05-31-cve-2025-59536-claude-config-rce.md
supporting:
  - https://owasp.org/www-project-mcp-top-10/
  - https://labs.cloudsecurityalliance.org/research/csa-research-note-ai-coding-tool-rce-cicd-attack-surface-202/
  - https://www.anthropic.com/engineering/claude-code-sandboxing
  - https://owasp.org/www-project-agentic-skills-top-10/skill-development-guide
date: 2026-05-31
confidence: high
---

## Pattern observed
Committed agent configuration — `.claude/settings.json` (hooks, env
overrides), `.mcp.json`, and the hook scripts they call — is **executable
input that runs on the machine of anyone who opens the repo.** This is now
a named, CVE-class attack surface (CVE-2025-59536 / CVE-2026-21852: hooks
RCE, MCP auto-enable bypass, `ANTHROPIC_BASE_URL` key exfiltration), and
the same theme recurs across OWASP MCP Top 10, OWASP Agentic Skills Top 10
(registry poisoning), and the CSA CI/CD attack-surface note. Anthropic's
own mitigation was a stronger trust dialog + deferred network ops — a
runtime guard, not a workflow guard.

Our template **ships exactly this surface**: `core/.claude/settings.*.json.tmpl`
(a full hook block), `core/.claude/hooks/{secret-redact,lint,audit}.sh`, and
`core/.claude/.mcp.json.tmpl`. So every installed project is taught to commit
hook-bearing config + executable hook scripts. Our hooks are benign — but we
provide **no workflow gate or doc** establishing that *changes to those files
are a code-execution surface to be reviewed like CI config.* A teammate (or a
compromised dependency / PR) editing `.claude/settings.json` can run code on
every other developer's machine, and nothing in our control plane flags it.

## Why it matters for our SDLC
This is the **review (S5) + security-trigger** stage. The template's whole
value proposition is "process discipline that ships safe-by-default." A
control plane that normalizes committing executable agent config without
making that surface a review trigger is shipping a latent supply-chain risk
to every consumer. Closing it is pure risk reduction with no friction cost —
it only fires the security gate we already have when those specific files
change.

## Proposed template change
- **Type:** rule-update + doc-update (new doc)
- **Target file(s):**
  - `core/.claude/rules/phase-matrix.md` — add `.claude/settings*.json`,
    `.mcp.json`, `.claude/hooks/*`, and the keys `ANTHROPIC_BASE_URL` /
    `enableAllProjectMcpServers` to the **Phase 7 (Security review) triggers**.
  - `core/docs/setup/agent-config-security.md` — NEW canonical doc: the trust
    model (committed `.claude/` config = executable), the three CVE vectors,
    and the review rule.
  - `core/docs/setup/permission-profiles.md` — extend the "auditor's check"
    with the trust-model callout + link.
  - `core/docs/setup/secret-handling.md` — add `ANTHROPIC_BASE_URL` exfil to
    anti-patterns + link the new doc.
- **Friction-or-quality:** **quality / risk** — turns an unguarded RCE surface
  into one that auto-fires the existing security gate. Zero new friction on
  normal work (only triggers when those specific files change).

## Counter-evidence / risks
- Anthropic already added a runtime trust dialog — but that protects the
  *first open*, not ongoing in-repo edits by a trusted-but-compromised actor,
  and it's not a substitute for *our* template teaching the discipline.
- Must stay de-domain-specified in `core/` (generic file patterns only).
- Keep it proportionate: a trigger + one doc, not a heavyweight process.

## Status
- [x] Proposed (this note)
- [x] Promoted to `apply/proposed/` → [agent-config-security-gate.md](../../apply/proposed/agent-config-security-gate.md)
- [x] Shipped → [../../apply/shipped/agent-config-security-gate.md](../../apply/shipped/agent-config-security-gate.md)
