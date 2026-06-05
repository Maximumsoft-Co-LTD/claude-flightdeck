# Permission Profiles

> Three foundation `.claude/settings.json` shapes you can pick at
> install time via `./install.sh --profile <name>`. Profile choice
> determines the **starting** Bash allow-list (and the deny-list);
> project customizations layer on top via the
> [soft-merge](./settings-merge.md) on re-install.
>
> **Core principle**: start tighter than you think you need. Add a
> permission when an agent needs it; don't pre-grant a broader pattern
> than the task requires. The audit hook records every tool call, so
> escalations are visible in `docs/project/audit/*.jsonl` after the fact.

## The three profiles at a glance

| Profile | `permissions.allow` shape | `permissions.deny` | Typical use |
|---|---|---|---|
| **restricted** | `Bash(ls *)`, `Bash(cat *)`, `Bash(grep *)`, `Bash(rg *)`, `Bash(find *)`, `Bash(git status …)`, `Bash(git diff …)`, `Bash(git log …)`, `Bash(git show …)`, `Bash(git branch …)`, `Bash(git rev-parse …)`, `Bash(jq *)` | _(none)_ | Audit / pair-programming / first-day onboarding; investigations on a sensitive repo; demo sessions |
| **standard** _(default)_ | restricted-set **plus** `Bash(go *)`, `Bash(make *)`, `Bash(git *)`, `Bash(gh *)`, `Bash(docker *)`, `Bash(docker-compose *)`, `Bash(npm *)`, `Bash(pnpm *)`, `Bash(npx *)`, `Bash(curl *)`, `Bash(mkdir *)`, `Bash(touch *)`, `Bash(chmod *)`, `Bash(test *)`, `Bash(awk *)`, `Bash(sed *)`, `Bash(echo *)`, `Bash(head *)`, `Bash(tail *)` | _(none — relies on agent + reviewer discipline)_ | Day-to-day dev. The control-plane assumes this baseline. |
| **permissive** | `Bash(*)` | `Bash(rm -rf /*)`, `Bash(rm -rf ~*)`, fork-bomb shape, `curl \| sh`, `wget \| bash`, `dd if=*`, `mkfs.* *` | Long autonomous runs in an isolated sandbox / VM / container; experimental skill development; throwaway worktrees |

All three profiles ship the same hook block:

- **PreToolUse** `Bash|Write|Edit|MultiEdit` → `.claude/hooks/secret-redact.sh`
  (blocks obvious secret leaks — see
  [`secret-handling.md`](./secret-handling.md))
- **PostToolUse** `Write|Edit|MultiEdit` → `.claude/hooks/lint.sh`
- **PostToolUse** `Agent` + **SubagentStop** `Agent` →
  `.claude/hooks/audit.sh` (writes `docs/project/audit/YYYY-MM.jsonl`)

## Decision matrix — when to pick which

| Situation | Profile |
|---|---|
| First install on a regulated codebase (SOC2 / HIPAA / FedRAMP) | `restricted` — escalate per task |
| Agent driving an unfamiliar codebase for the first time | `restricted` — observe before granting |
| Day-to-day greenfield dev | `standard` |
| Established team with a mature 6-gate review habit | `standard` |
| Sandbox VM with no host-FS access, no creds, throwaway | `permissive` |
| Background `loop` / scheduled agent (`/schedule`) with no human in the loop | **never** `permissive` — use `standard` with a tighter `deny` list |
| Live production-adjacent debugging session | `restricted` until you know what you need |
| Long-running autonomous research (no merge / no write to repo) | `restricted` (read-only) |

## Escalation path — restricted → standard → permissive

The expected lifecycle:

1. **Install with `--profile restricted`.** Run the agent. Watch which
   Bash patterns it needs.
2. **Add specific patterns** to `.claude/settings.json` `permissions.allow`
   as the work demands them — `Bash(make build)`, `Bash(make test)`,
   `Bash(docker compose up *)`. Resist the urge to `Bash(make *)`
   unless you've already seen 3+ different `make` targets the agent
   uses legitimately.
3. **When `restricted` + your additions look indistinguishable from
   `standard`**, switch by re-installing with `--profile standard`.
   The soft-merge preserves your additions.
4. **`permissive`** is for sandboxes only. If you're picking it for a
   real project, ask yourself why; the standard + per-task additions
   should suffice for 95% of work.

## Adding a specific permission to a restricted profile

`.claude/settings.json` is the live, editable surface. Edit the
`permissions.allow` array directly:

```jsonc
{
  "permissions": {
    "allow": [
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(grep *)",
      // … restricted baseline …
      "Bash(make test)",      // ← added for {{TASK_ID_PREFIX}}-S03.04
      "Bash(make build)"      // ← added for {{TASK_ID_PREFIX}}-S03.05
    ]
  }
}
```

Conventions for additions:

- **Most-specific first.** `Bash(make test)` is safer than `Bash(make *)`.
  Add the wildcard only when you've seen 3+ distinct invocations.
- **Comment the reason.** A trailing JSONC comment with the task ID
  that motivated the grant makes the audit trivial.
- **Time-box generosity.** If you granted `Bash(curl *)` for one
  task, revoke it at sprint close unless another task needs it.

## Reviewing the allow-list (auditor's check)

When a security reviewer or PR auditor opens `.claude/settings.json`:

1. **Diff against the profile foundation** (`.claude/settings.foundation.json`
   when present, or `core/.claude/settings.<profile>.json.tmpl` in
   the template repo). Every line outside the foundation is a
   deliberate addition — confirm there's a task ID or comment.
2. **Grep `docs/project/audit/*.jsonl` for the most-used Bash patterns**
   in the last sprint. Patterns the agent never used can usually be
   removed.
3. **Look for shape-changing additions** — `Bash(*)`, `Bash(rm *)`,
   `Bash(sudo *)`. None of these belong outside a sandbox. If you
   see them, escalate via [`separation-of-duties.md`](./separation-of-duties.md).
4. **Confirm the hook block matches the foundation.** A target that
   removed `secret-redact.sh` from PreToolUse is a finding — the hook
   is non-negotiable across all three profiles.
5. **Treat the hook block + any env override as a code-execution
   surface.** A new `SessionStart` shell, a hook `command` pointing
   outside `$CLAUDE_PROJECT_DIR/.claude/`, an `ANTHROPIC_BASE_URL`
   redirect, or `enableAllProjectMcpServers` is an RCE/exfil finding —
   committed agent config runs on every teammate's machine
   (CVE-2025-59536 class). Diffs to these files fire the Phase 7
   security review. Full trust model + checklist:
   [`agent-config-security.md`](./agent-config-security.md).

## What `permissive` deliberately denies

Even at the most permissive end, the foundation denies a small set of
obviously destructive shapes:

```
"Bash(rm -rf /*)"        — filesystem wipe
"Bash(rm -rf ~*)"        — home-directory wipe
"Bash(:(){ :|:& };:)"    — classic fork bomb
"Bash(curl * | sh)"      — pipe-curl-to-shell (supply-chain risk)
"Bash(curl * | bash)"    — same
"Bash(wget * | sh)"      — same
"Bash(wget * | bash)"    — same
"Bash(dd if=* of=/dev/*)" — raw disk overwrite
"Bash(mkfs.* *)"         — filesystem reformat
```

These are not exhaustive. Treat them as the **minimum** guard for a
sandbox, not as a substitute for running `permissive` inside an
actual sandbox.

## Re-install with a different profile

```bash
./install.sh ./target --profile restricted --force
# OR (preserves customizations via soft-merge):
./install.sh ./target --profile standard
```

With `--force`, the foundation `settings.json` overwrites the current
file. Without `--force`, the soft-merge preserves your customizations
and writes the new foundation to `.claude/settings.foundation.json`
side-by-side for hand-merge — see
[`settings-merge.md`](./settings-merge.md) for the merge recipe.

## Related

- [`secret-handling.md`](./secret-handling.md) — the PreToolUse hook
  that all three profiles ship
- [`settings-merge.md`](./settings-merge.md) — how the installer
  preserves customizations across re-installs
- [`separation-of-duties.md`](./separation-of-duties.md) — when an
  allow-list change requires a named human approver
- [`compliance-mapping.md`](./compliance-mapping.md) — which controls
  this profile choice maps to (SOC2 CC6.1, ISO 27001 A.9 / A.12, etc.)
