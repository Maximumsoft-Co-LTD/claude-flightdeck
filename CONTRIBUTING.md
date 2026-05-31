# Contributing to claude-flightdeck

Thanks for wanting to give back. This template gets better the more
real-world adoption feedback it absorbs. There are four ways to
contribute, lightest to heaviest.

## 1. Open an issue (zero effort, high value)

Use the structured forms — they route to the right label and ask the
right questions:

| Form | When |
|---|---|
| 🐞 Bug report | install.sh / a hook / a skill / CI broke |
| 📏 Rule feedback | an A-rule / N-rule / lesson was wrong / too strict / missing |
| 🧩 Preset request | you want a new stack preset (python-fastapi, rust-axum, …) |
| ⚙️ Skill feedback | a skill didn't trigger / did the wrong thing |
| ⛺ Onboarding feedback | a `/onboard` stage was confusing / a draft was off |

Every form asks for your **template version** (from
`.ai-workflows/manifest.json` or `./install.sh --version`) so we know
what you're on.

**Always redact secrets** before pasting output — tokens, keys,
`.env` values. The forms remind you.

## 2. Share your experience (Discussions)

For questions, show-and-tell, or "here's how my team adopted it",
use [Discussions](https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/discussions)
instead of an issue.

**Especially welcome:** a **sanitized** excerpt of your
`docs/spec/retros/onboarding.md` (the Stage 8 onboarding retro) or
your `/audit-query` digest. That data — which A-rules you dropped,
which gates fired most, which skills you actually used — is the
single highest-signal feedback we get. It tells us where the
template's defaults don't match reality. Redact project names +
internal identifiers first.

## 3. Send feedback from inside Claude Code (`/flightdeck-feedback`)

If you installed the template, the `/flightdeck-feedback` skill drafts
a structured issue from your session context + manifest version,
redacts it, shows you a preview, and opens it via `gh` (or prints a
prefilled URL if you don't have `gh`). Opt-in, one-shot — it never
phones home on its own. See
`core/.claude/skills/flightdeck-feedback/SKILL.md`.

## 4. Open a PR (the real contribution)

The highest-leverage contributions:

### Adding a preset
Follow [`docs/adding-new-preset.md`](docs/adding-new-preset.md). A
preset is mostly markdown — an engineer agent + an architectural rule
+ optional skill + setup doc. No registration step; the installer
picks it up by directory shape.

### Fixing / adding a rule
Rules live in `core/.claude/rules/`. Keep the format: **bold rule
name** · *Why:* · *How to apply:*. Every rule needs evidence — don't
add "best practice in general" rules without a concrete failure it
prevents.

### Improving a skill
Skills live in `core/.claude/skills/<name>/SKILL.md`. Must keep the
`## Token budget` section. Deep material goes in `references/`,
mechanical loops in `scripts/`.

**Description = triggers, not a summary (CSO).** The `description:`
frontmatter decides whether the model auto-loads the skill. Lead with
**when to use it** — concrete user phrases, slash-command names, and
failure *symptoms* (e.g. "after a subagent returns", "tests flaky",
"merge gone wrong"). Do NOT write a workflow summary: a description that
explains *how the skill works* makes the model think it already knows
enough and skip the skill body. (Adopted from superpowers'
`writing-skills` Claude-Search-Optimization rule.)

**Split when unwieldy (progressive disclosure).** Keep `SKILL.md` lean;
move content that is large or rarely-used-together into `references/`
(read on demand) so a trigger doesn't pay for tokens it won't use.
**Mark every script execute-vs-read** — say whether the model should
*run* it (deterministic op) or *read* it as reference. Both serve the
"smallest set of high-signal tokens" principle. Full guide (also shipped
to installed projects): [`core/docs/setup/skill-authoring.md`](core/docs/setup/skill-authoring.md).

### Ground rules for `core/`

1. **De-domain-specify.** No project-specific names in `core/` — no
   `idip-`, `agg-`, company-internal IDs. Tech-stack opinions go in
   `presets/`, never `core/`.
2. **Bump VERSION** when `core/` or `presets/` changes. The
   `contrib/pre-commit-version-guard.sh` hook enforces this. Semver:
   patch = fix, minor = feature, major = breaking.
3. **Update CHANGELOG.md** in the same PR.
4. **Evidence before assertions** (A003). The PR template asks for
   actual command output proving the change works.

### Local setup for contributors

```bash
git clone https://github.com/Maximumsoft-Co-LTD/claude-flightdeck.git
cd claude-flightdeck

# Optional: install the version-bump guard
ln -s "$(pwd)/contrib/pre-commit-version-guard.sh" .git/hooks/pre-commit

# Smoke-test any change with a scratch install
mkdir -p /tmp/cf-test
./install.sh /tmp/cf-test --preset go-hex --config <(cat <<'EOF'
PROJECT_NAME="CF Test"
PROJECT_SLUG=cf-test
AGENT_PREFIX=cf
TASK_ID_PREFIX=CF
TECH_STACK_DESC="Go 1.22"
BRAIN_PATH=""
EOF
) --force
grep -rln '{{[A-Z_]\{2,\}}}' /tmp/cf-test && echo "FAIL: placeholders" || echo "ok: clean"
```

## What we won't merge

- Always-on telemetry / phone-home hooks (privacy + token cost — see
  the feedback design philosophy: **pull, not push**)
- Project-specific content in `core/` (belongs in your own install,
  not the template)
- Skills without a token budget section
- Rules without evidence
- Changes that skip the VERSION bump (the guard will block them anyway)

## Code of conduct

Be kind, be concrete, assume good faith. This is tooling to make
AI-assisted development saner — keep the discourse the same way.
