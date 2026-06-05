# Sending feedback upstream

This project was scaffolded from the **claude-flightdeck** control-plane
template. The template improves the more real-world adoption signal it
absorbs — which A-rules you dropped, which gates fired most, where the
defaults didn't match your stack. This doc is how you send that signal
back to the maintainers.

## Why feedback matters

The template ships opinionated defaults (6-gate review, design-first,
the A001–A010 hot rules, the size tiers). Those defaults were lifted
from two codebases. They are *guesses* about your project until a real
adoption cycle either confirms or contradicts them. Your retro, your
dropped rules, your "this skill never triggered" report — that is the
only thing that tells the maintainers where the template is wrong.

You lose nothing by sending it, and the next project that installs the
template inherits the fix.

## The fastest path: prefilled issue URLs

The canonical repo has structured issue forms. Each one routes to the
right label and asks the right questions. Click straight through:

| What | Prefilled link |
|---|---|
| 🐞 Bug (install / hook / skill / CI broke) | <https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/issues/new?template=bug_report.yml> |
| 📏 Rule feedback (an A/N-rule was wrong / too strict / missing) | <https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/issues/new?template=rule_feedback.yml> |
| 🧩 Preset request (new stack — python-fastapi, rust-axum, …) | <https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/issues/new?template=preset_request.yml> |
| ⚙️ Skill feedback (a skill didn't trigger / did the wrong thing) | <https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/issues/new?template=skill_feedback.yml> |
| ⛺ Onboarding feedback (a `/onboard` stage was confusing) | <https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/issues/new?template=onboarding_feedback.yml> |

Every form asks for your **template version**. Read it from your install
manifest:

```bash
jq -r .version .ai-workflows/manifest.json
# or, from the template checkout:
./install.sh --version
```

**Always redact secrets** before pasting any output — tokens, keys,
`.env` values, internal hostnames. The forms remind you, but it's on you.

## From inside Claude Code: `/flightdeck-feedback`

If you'd rather not leave your editor, run the skill:

```
/flightdeck-feedback
```

It asks the feedback type, reads your manifest for version context,
drafts a structured issue body from your session, **redacts secrets**,
shows you a **preview**, and then opens the issue via `gh` (or prints a
prefilled URL if you don't have `gh` installed). It is **opt-in and
one-shot** — it runs only when you invoke it, and it never sends without
showing you the preview first.

## High-signal: share your retro

The single most useful thing you can send is a **sanitized** excerpt of
your Stage-8 onboarding retro (`docs/project/retros/onboarding.md`) or your
`/audit-query` digest. That data is pure signal:

- which A-rules you ratified vs dropped
- which of the 6 gates fired most (and which never did)
- which skills you actually used vs ignored
- where `/onboard` drafts were off

Paste it into a **GitHub Discussion** (not an issue) — it's a
conversation, not a bug:

<https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/discussions>

Pure data, zero LLM cost. **Redact project names, internal identifiers,
and secrets first.**

## The golden rule: pull, not push

Feedback from this template is **never automatic**. Nothing phones home.
No hook, no CI step, no background process ships your data anywhere. The
flow is always:

1. *You* decide to send feedback.
2. You see a **preview** of exactly what will be sent.
3. You confirm.

This is a deliberate **privacy + token-cost** decision. The maintainers
will not merge always-on telemetry. The only token cost is the one-shot
`/flightdeck-feedback` invocation (~5–10k tokens), and only when you ask
for it.

## For org-forks

If your organization forked the template into an internal repo, feedback
should route to *your* fork, not the public canonical repo. Update the
repo reference in the `/flightdeck-feedback` skill so its prefilled URLs
and `gh` calls target your fork:

```
.claude/skills/flightdeck-feedback/SKILL.md
```

Change the `Maximumsoft-Co-LTD/claude-flightdeck` references to your
fork's `owner/repo`. The issue forms ship in your fork's
`.github/ISSUE_TEMPLATE/`, so the prefilled-URL paths stay the same.

## See also

- `CONTRIBUTING.md` (in the template repo) — the full contribution guide
  (issue / discussion / in-Claude skill / PR paths, `core/` ground rules)
- `.claude/skills/flightdeck-feedback/SKILL.md` — the in-editor feedback
  skill
- `docs/setup/multi-team-deployment.md` — coordinating multiple teams /
  forks on the same template
