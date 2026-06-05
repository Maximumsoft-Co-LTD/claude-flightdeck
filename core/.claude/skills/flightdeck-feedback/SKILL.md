---
name: flightdeck-feedback
description: "Send structured feedback about the claude-flightdeck template back to the canonical repo — bug, rule misfire, preset request, skill issue, or onboarding feedback. Reads your install manifest for version context, redacts secrets, shows a preview, then opens a GitHub issue via gh (or prints a prefilled URL). Opt-in, one-shot — never phones home on its own. Use when the user says '/flightdeck-feedback', 'report a bug in the template', 'send feedback upstream', 'this rule is wrong', 'request a preset'."
user_invocable: true
---

# /flightdeck-feedback — Send feedback upstream

Open a structured issue against the canonical claude-flightdeck template
repo — a template bug, a rule that misfired, a preset you want, a broken
skill, or onboarding friction.

> **This is PULL feedback — it only runs when you invoke it, and always
> shows a preview before sending. It never sends anything automatically.**

## Token budget (MANDATORY)

- One-shot: ~5-10k tokens total. No passive cost — the skill does
  nothing unless invoked. There is no hook, no background poll.
- Read `.ai-workflows/manifest.json` **once** (small — version + commit +
  presets + placeholders).
- Read `docs/project/retros/onboarding.md` with `limit: 100` **only** for
  `onboarding`-type feedback — skip it for every other type.
- Do NOT scan the codebase or Read large files. Feedback is about the
  **template**, not the user's project. If you find yourself grepping
  source, you're off-track.

## Invocation

| Form | Effect |
|---|---|
| `/flightdeck-feedback` | Interactive — asks the feedback type first |
| `/flightdeck-feedback bug` | Skip the type question — template bug |
| `/flightdeck-feedback rule` | Skip — a rule misfired / is wrong |
| `/flightdeck-feedback preset` | Skip — request a new preset |
| `/flightdeck-feedback skill` | Skip — a skill is broken / unclear |
| `/flightdeck-feedback onboarding` | Skip — onboarding wizard feedback |
| `/flightdeck-feedback --url-only` | Don't use `gh`; print a prefilled issue URL to click |

## Canonical repo

Feedback routes to **`Maximumsoft-Co-LTD/claude-flightdeck`** (hardcoded
below). See [`## For org-forks`](#for-org-forks) if your team forked it.

## Steps

1. **Read manifest.** Read `.ai-workflows/manifest.json` → extract
   `version`, `source_commit`, `presets`, `profile`. If the file is
   missing, note *"not installed via flightdeck — version unknown"* and
   continue with empty values (still useful feedback).
2. **Determine feedback type.** From the subcommand arg, or — if none —
   `AskUserQuestion` with the 5 types below. Map each to its issue-form
   name + label:

   | Type | Issue form | Label |
   |---|---|---|
   | bug | `bug_report.yml` | `bug` |
   | rule | `rule_feedback.yml` | `rule-feedback` |
   | preset | `preset_request.yml` | `preset-request` |
   | skill | `skill_feedback.yml` | `skill-feedback` |
   | onboarding | `onboarding_feedback.yml` | `onboarding-feedback` |

3. **Gather specifics.** `AskUserQuestion` (≤4 questions) tailored to the
   type — mirror the GitHub form's KEY fields, don't re-ask everything:
   - **bug** — what broke · what you expected · minimal repro steps · which file/skill.
   - **rule** — which rule ID (A### / L### / B###) · what misfired · proposed wording.
   - **preset** — stack/framework · what it should scaffold · why core can't cover it.
   - **skill** — which skill · what was confusing/broken · expected behavior.
   - **onboarding** — which stage · what stalled · suggestion. (Only here: read `docs/project/retros/onboarding.md` `limit: 100` for context.)
4. **Draft the issue body.** Structured markdown matching the form's
   sections, plus an auto-included environment block:

   ```markdown
   ## Environment
   Template version: <version> · commit: <source_commit> ·
   presets: <presets> · profile: <profile> · OS: <uname -sr>
   ```

   Run `uname -sr` to fill OS. Title format: `[<type>] <one-line summary>`.
5. **REDACT (mandatory).** Scan the FULL drafted body (title + body +
   environment) for secrets and replace every match with `[REDACTED]`:
   - Env-var-name regex (from `secret-redact.sh`):
     `([A-Z][A-Z0-9_]*_(TOKEN|KEY|SECRET|PASSWORD|PASSWD|PWD))|(AWS|GCP|AZURE|OPENAI|ANTHROPIC|GITHUB|GH)_[A-Z0-9_]+`
   - Strip anything that looks like a file path containing `secret`,
     `credential`, or `.env`.
   - State in the preview: *"Secret redaction ran — N match(es) replaced."*
6. **PREVIEW + confirm.** Show the user the COMPLETE drafted issue (title
   + body + the redaction note) and ask: **"Send this? [send / edit /
   cancel]"**. NEVER send without an explicit `send`. On `edit`, take the
   user's revisions and re-run steps 5-6. On `cancel`, stop — write
   nothing, send nothing.
7. **Send** (only after `send`). Two paths:
   - **gh available + authed** (`command -v gh && gh auth status`):
     ```bash
     gh issue create \
       --repo Maximumsoft-Co-LTD/claude-flightdeck \
       --title "<title>" --body "<body>" --label "<label>"
     ```
     Report the issue URL `gh` returns.
   - **Else, or `--url-only`:** construct + print a prefilled URL:
     ```
     https://github.com/Maximumsoft-Co-LTD/claude-flightdeck/issues/new?template=<form>.yml&title=<urlencoded-title>
     ```
     Note that the URL can only prefill **title + template** — the
     GitHub issue form will still ask for the structured fields, so tell
     the user to paste the drafted body sections into the form.

## Redaction guarantee

A trust feature, stated plainly:

- **What gets scanned:** the entire drafted issue — title, body, and the
  auto-generated environment block — using the same secret regex the
  `secret-redact.sh` hook uses, plus path-based stripping of
  `secret`/`credential`/`.env` references.
- **Preview is mandatory.** You always see the exact text — post-redaction
  — before anything leaves your machine.
- **Nothing sends automatically.** No hook, no background job, no
  telemetry. The only egress is the `gh issue create` (or the URL you
  click) that you explicitly approve at step 6.

## For org-forks

If your team forked claude-flightdeck into your own org, change the
`Maximumsoft-Co-LTD/claude-flightdeck` repo reference in this SKILL.md to
your fork's path (in `## Canonical repo`, the step 7 `gh` command, and the
step 7 URL) so feedback routes internally instead of to the public
upstream.

## See also

- [`CONTRIBUTING.md`](../../../../CONTRIBUTING.md) — how upstream triages incoming feedback
- [`.github/ISSUE_TEMPLATE/`](../../../../.github/ISSUE_TEMPLATE/) — the 5 issue forms this skill targets
- [`.claude/hooks/secret-redact.sh`](../../hooks/secret-redact.sh) — source of the redaction regex reused at step 5
- [`audit-query`](../audit-query/SKILL.md) — the data-sharing-via-discussions pattern (share aggregate audit digests upstream the same opt-in, preview-first way)
