# Agent-Config Security — committed `.claude/` config is executable

> **Core principle**: anything in `.claude/settings*.json`, `.mcp.json`, or
> `.claude/hooks/` that is committed to the repo **runs on the machine of
> every teammate who opens the project in Claude Code.** Treat changes to
> these files as a code-execution surface — review them like you review CI
> config, not like ordinary docs.

## Why this file exists

Coding-agent config is not inert data. Hooks run shell commands, MCP servers
launch processes, and settings can redefine environment variables — all
triggered when someone opens the repo. Three of these were assigned CVEs
(CVE-2025-59536 / CVE-2026-21852) precisely because a **repo-committed**
config could execute attacker code or steal credentials around the trust
dialog. The attack flow is simply: *clone repo → Claude Code reads `.claude/`
→ code runs.*

This control plane **ships** that surface by design — a hook block in
`settings.<profile>.json`, the `.claude/hooks/*.sh` scripts, and an
`.mcp.json`. The hooks we ship are benign (secret-redact / lint / audit), and
that is exactly the point: the risk is not our scripts, it is that **anyone
who can write to these committed files gains code execution on everyone
else.** A teammate, a malicious PR, or a compromised dependency that edits
`.claude/settings.json` is an RCE on the whole team.

## The three vectors to guard (from CVE-2025-59536 / CVE-2026-21852)

| Vector | Where | What it does |
|---|---|---|
| **Hook RCE** | `.claude/settings*.json` `hooks` block (esp. `SessionStart`) | Shell command runs automatically on Claude Code init |
| **MCP auto-enable bypass** | `.mcp.json` + `enableAllProjectMcpServers` in settings | A server launches *before* the trust dialog is read |
| **Credential exfiltration** | `ANTHROPIC_BASE_URL` (or other env override) in settings | API traffic + auth headers routed to attacker infrastructure |

Anthropic added a runtime mitigation (stronger trust dialog, deferred network
ops, MCP approval enforcement). That protects the **first open** — it does
**not** protect against ongoing in-repo edits by a trusted-but-compromised
actor. Workflow discipline is the second layer.

## The rule

1. **Changes to `.claude/settings*.json`, `.mcp.json`, or `.claude/hooks/*`
   fire the Phase 7 security review** (see
   [`../../.claude/rules/phase-matrix.md`](../../.claude/rules/phase-matrix.md)).
   No agent-config change merges without it.
2. **Never commit these keys from project config:**
   - `ANTHROPIC_BASE_URL` (or any `*_BASE_URL` redirect of the model API)
   - `enableAllProjectMcpServers: true`
   - a hook `command` that pipes the network to a shell, or references a
     script outside `$CLAUDE_PROJECT_DIR/.claude/`
3. **Hook scripts are reviewed like production code** — they run with the
   developer's privileges. Pin them to `$CLAUDE_PROJECT_DIR/.claude/hooks/`,
   keep them readable, and diff them on every change.
4. **MCP servers are opt-in and pinned** — approve each server explicitly;
   never rely on auto-enable. Prefer pinned versions/SHAs for third-party
   servers (supply-chain trust).

## Reviewer checklist (Phase 7, when an agent-config file changed)

- [ ] **Hook block diff** — every `command` points inside
  `$CLAUDE_PROJECT_DIR/.claude/hooks/`; no new `SessionStart` shell that
  fetches+executes; `secret-redact.sh` still present on PreToolUse.
- [ ] **No env redirect** — `grep` the diff for `ANTHROPIC_BASE_URL` /
  `*_BASE_URL` / `enableAllProjectMcpServers`. Any hit is a finding.
- [ ] **`.mcp.json` diff** — every server is intended, named, and (for
  third-party) version/SHA-pinned; no auto-enable.
- [ ] **Hook script diff** — read the actual script; no `curl … | sh`, no
  exfil of env vars, no writes outside the repo.
- [ ] **Provenance** — the change has a task ID / reason, like any
  permission-allow-list addition (see
  [`permission-profiles.md`](./permission-profiles.md)).

## Related

- [`permission-profiles.md`](./permission-profiles.md) — the three
  `settings.json` profiles + the auditor's allow-list review
- [`secret-handling.md`](./secret-handling.md) — `ANTHROPIC_BASE_URL` exfil +
  the `secret-redact.sh` PreToolUse hook
- [`separation-of-duties.md`](./separation-of-duties.md) — when an
  agent-config change needs a named human approver
- [`../../.claude/rules/phase-matrix.md`](../../.claude/rules/phase-matrix.md)
  — Phase 7 security-review triggers (now includes agent-config files)
- [`../playbooks/post-delegation-review.md`](../playbooks/post-delegation-review.md)
  — Gate 1 (inspect diff) + the security gate this feeds
