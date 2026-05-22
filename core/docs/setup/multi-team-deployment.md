# Multi-Team / Org-Fork Deployment

> How a multi-team org adopts AI-Workflows once, customises it once,
> and rolls those customisations to every project. The pattern is a
> **forked template** plus a thin `org-rules.md` layer above each
> project's local A011+ rules.
>
> **Core principle**: the AI-Workflows template is the universal floor;
> your org fork is the team-specific floor on top; each project's
> `brain-hot.md` A011+ section is the project-specific floor on top of
> that. Three layers, all visible, none surprising.

## The pattern

```
                ┌──────────────────────────────────┐
                │  upstream/AI-Workflows           │   universal template
                │  (this repo)                     │   — workflow, agents, skills
                └──────────────────┬───────────────┘
                                   │ fork once
                                   ↓
                ┌──────────────────────────────────┐
                │  <org>/ai-workflows-internal     │   org fork
                │  + core/.claude/rules/org-rules  │   — team-shared A### rules
                │  + your-org-specific presets     │   — org's stack opinions
                │  + ORG-CODEOWNERS template       │   — org reviewer teams
                └──────────────────┬───────────────┘
                                   │ ./install.sh
                                   ↓
                ┌──────────────────────────────────┐
                │  any project repo                │   project install
                │  + .claude/rules/brain-hot.md    │   — A011+ project rules
                │  + .claude/agents/<prefix>-*     │   — project-specific agents
                │  + docs/spec/                    │   — the live sprint
                └──────────────────────────────────┘
```

The upstream template ships an empty `org-rules.md.tmpl` slot — your
fork fills it in. Projects installed from the fork pick up your org
rules automatically.

## The `org-rules.md.tmpl` slot

Your fork's `core/.claude/rules/org-rules.md.tmpl` is auto-loaded
beside `brain-hot.md`. Suggested shape:

```markdown
# {{PROJECT_NAME}} — Org-shared rules (auto-loaded)

> Org-wide rules that sit above project-local A011+. Numbered A100+
> so they don't collide with template A001-A010 or project A011+.

## A100 — _(your first org rule, e.g. "All public APIs versioned via OpenAPI v3.1, contracts live at contracts/openapi/")_

## A101 — _(your second, e.g. "All services emit OpenTelemetry traces to the shared collector at otel-collector.<org>.svc.cluster.local")_

## A102 — _(e.g. "All schema migrations land via Flyway, version files in <service>/db/migrations/")_

## A103 — _(security: where the org's secrets live; what SIEM ingests audit.jsonl)_
```

Keep the file short — 20-30 lines. If a rule needs more, link to a
dedicated doc in your fork's `docs/setup/`.

## Project installs from the org fork

```bash
# Instead of the upstream template, projects clone & install your fork:
git clone git@github.com:<org>/ai-workflows-internal.git
cd ai-workflows-internal
./install.sh ~/code/<new-project> --preset go-hex --brain-path git@github.com:<org>/team-brain.git
```

Behavior:

- The org's `org-rules.md.tmpl` is copied alongside `brain-hot.md.tmpl`
  during the core/ copy step.
- The org's `ORG-CODEOWNERS.tmpl` lands at `.github/CODEOWNERS` with
  org reviewer teams already filled in.
- Org-specific presets in your fork's `presets/<org-name>/` are
  available to `--preset`.

## Upgrade path — pull org changes into a project

```bash
# In the project repo (which was installed from the fork):
cd ~/code/<existing-project>

# Pull the latest fork:
cd /tmp && git clone git@github.com:<org>/ai-workflows-internal.git
cd ~/code/<existing-project>

# Re-install (soft-merge preserves project customizations):
/tmp/ai-workflows-internal/install.sh . --config .ai-workflows/manifest.json

# Or use the dedicated upgrade flow once you have it:
/tmp/ai-workflows-internal/install.sh upgrade .
```

The soft-merge ([`settings-merge.md`](./settings-merge.md)) preserves
the project's `.claude/settings.json` customisations; new org rules
or new foundation hooks land alongside as `.foundation.json` snippets
for hand-merge.

## External Brain integration

The `BRAIN_PATH` install variable accepts either a local path or a
git URL:

```bash
# Local Obsidian vault:
./install.sh ./target --brain-path ~/Obsidian/team-brain

# Org-shared brain repo (cloned on first session):
./install.sh ./target --brain-path git@github.com:<org>/team-brain.git
```

When `BRAIN_PATH` is a git URL, the project's
`.claude/rules/brain-hot.md` footer points at the URL; the agent's
pre-task ritual reads from a clone (your fork is responsible for
shipping the clone-on-first-session glue — typically a tiny SessionStart
hook or a make target).

Org-level brains are the right place for:

- L### lessons that recur across multiple teams (production incidents,
  cross-cutting refactors)
- Org-wide coding examples / golden-path implementations
- Approved provider templates (e.g. "this is how we do Postgres at
  <org>")

Keep team-specific lessons in a separate brain to avoid noise.

## Naming conventions for `AGENT_PREFIX`

Multiple teams in the same monorepo or org can collide on agent
names. Convention:

```
<team>-<project>          ← agent prefix
e.g.  payments-checkout   →  payments-checkout-orchestrator
      identity-portal     →  identity-portal-orchestrator
      platform-runtime    →  platform-runtime-orchestrator
```

When the project lives in its own repo, `AGENT_PREFIX = <project>`
suffices. The cross-team prefix is only needed when:

- Multiple teams share a monorepo
- Agents are registered into a shared registry (e.g. Claude Agent SDK
  multi-project setup)
- An org-wide `/dispatch-parallel` could route across team boundaries

## Quick start — set up a new org in 4 steps

```bash
# 1. Fork upstream/AI-Workflows to <org>/ai-workflows-internal
gh repo fork anthropics/AI-Workflows --org <org> --fork-name ai-workflows-internal --clone

# 2. Create the org-rules slot
cd ai-workflows-internal
cat > core/.claude/rules/org-rules.md.tmpl <<'EOF'
# {{PROJECT_NAME}} — <org> shared rules

## A100 — <first org rule>

## A101 — <second org rule>
EOF

# 3. Customise the CODEOWNERS template with your org teams
sed -i.bak \
  -e 's/@{{PROJECT_SLUG}}-platform/@<org>\/platform/g' \
  -e 's/@{{PROJECT_SLUG}}-pm/@<org>\/pm/g' \
  -e 's/@{{PROJECT_SLUG}}-security/@<org>\/security/g' \
  core/.github/CODEOWNERS.tmpl
rm core/.github/CODEOWNERS.tmpl.bak

# 4. Commit + tag a version, then publish
git add -A
git commit -m "<org>: bootstrap fork — org-rules slot + CODEOWNERS teams"
git tag v0.1.0-<org>
git push origin main --tags
```

Now every project under `<org>` installs from
`git@github.com:<org>/ai-workflows-internal.git` and inherits the org
shape.

## Anti-patterns

- ❌ **Editing `brain-hot.md`** in your fork to add A100+ rules.
  Use the `org-rules.md.tmpl` slot — keeps the template's A001-A010
  separable from your org rules. Diffs against upstream stay clean.
- ❌ **Forking each project independently** with hand-customised
  rules. The whole point of the org fork is one place to roll out
  changes.
- ❌ **Storing the org's secret-handling cheatsheet in
  `org-rules.md`**. Rules go in `org-rules.md`; reference data goes
  in your fork's `docs/setup/`.
- ❌ **`BRAIN_PATH` pointing to a private gist or chat thread.**
  Brains must be auditable + checkout-able. A git repo or an
  Obsidian vault are the only sane choices.

## Related

- [`secret-handling.md`](./secret-handling.md) — what org-level
  secret policy looks like at A103 / A104
- [`compliance-mapping.md`](./compliance-mapping.md) — controls
  that benefit from a single-org policy file
- [`settings-merge.md`](./settings-merge.md) — how project
  installs absorb fork updates without losing local customisations
- [`../../.github/CODEOWNERS.tmpl`](../../.github/CODEOWNERS.tmpl)
  — the reviewer-team placeholder you customise per-org
