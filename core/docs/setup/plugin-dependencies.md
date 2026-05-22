# Plugin Dependencies

> {{PROJECT_NAME}}'s control plane leans on **two Claude Code plugins**.
> Install them before your first sprint. `/onboard` Stage 0 checks for them
> and warns if either is missing.

## What you need

| Plugin | Status | Why |
|---|---|---|
| **`pr-review-toolkit`** | **Required** | Gate 4b of the 6-gate review dispatches its reviewers (`code-reviewer`, `silent-failure-hunter`, `type-design-analyzer`, `pr-test-analyzer`, `comment-analyzer`). The review chain can't run as written without it. |
| **`superpowers`** | **Strongly recommended** | The A-rules invoke its skills: `test-driven-development` (A001), `verification-before-completion` (A003), `systematic-debugging` (fix flow), plus `using-git-worktrees` / `dispatching-parallel-agents` / `brainstorming`. |

Both are published in the official Claude Code plugin marketplace
(`claude-plugins-official`).

## Install

In Claude Code:

```
/plugin
```

Open the **`claude-plugins-official`** marketplace and install:

- `superpowers`
- `pr-review-toolkit`

(They install under `~/.claude/plugins/`; readiness is recorded in
`~/.claude/plugins/installed_plugins.json`, which `/onboard` reads.)

## If a plugin is missing — what degrades

The template is written so it doesn't hard-crash without them, but you lose
guarantees:

- **`pr-review-toolkit` missing** → Gate 4b can't dispatch its specialist
  reviewers. Fall back to the built-in **`feature-dev:code-reviewer`** plus a
  `senior-tech-lead` quality pass. This is **degraded** — silent-failure and
  type-design coverage are weaker. Install the plugin to restore full Gate 4b.
- **`superpowers` missing** → the `superpowers:*` skill invocations no-op, but
  the disciplines are still described inline: the A-rules in
  [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) and the
  excuse→reality tables in [`discipline-red-flags.md`](discipline-red-flags.md)
  carry TDD / verification / debugging. You lose the rigorous skill prompts,
  not the rules.

## Verify they're installed

`/onboard` Stage 0 prints a `Plugins:` line and warns on anything missing.
To check directly:

```bash
jq -r '.plugins | keys[]' ~/.claude/plugins/installed_plugins.json \
  | grep -E '^(superpowers|pr-review-toolkit)@'
```

Two lines = both present. (Honor `CLAUDE_CONFIG_DIR` if you've relocated
`~/.claude`.)

## See also

- [`../../.claude/skills/onboard/SKILL.md`](../../.claude/skills/onboard/SKILL.md) — Stage 0 plugin check
- [`../playbooks/post-delegation-review.md`](../playbooks/post-delegation-review.md) — Gate 4b (where `pr-review-toolkit` is used)
- [`discipline-red-flags.md`](discipline-red-flags.md) — the disciplines that `superpowers` skills reinforce
