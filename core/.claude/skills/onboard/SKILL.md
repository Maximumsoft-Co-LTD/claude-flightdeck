---
name: onboard
description: "Setup wizard for a freshly-installed claude-flightdeck. Walks 8 stages — topology detection, codebase scan, team interview, git-history mining, document drafting, A-rule ratification, state capture, first-feature handoff — to bring Claude Code from 'template installed' to 'fully understands this project'. Use right after `install.sh` ('how do I get started', 'set up the workflow', 'onboard the project', '/onboard'). Subcommands: /onboard refresh (re-run on existing install), /onboard scan (Stage 1 only), /onboard rules (Stages 3+5), /onboard retro (post-first-sprint reflection)."
user_invocable: true
---

# /onboard — Project Onboarding Wizard

Bring Claude Code + the control plane from "template installed" to
"fully understands this project". 8 stages, ~4-6 hours interactive,
hybrid (auto-do mechanical work · prompt only for context the user
alone has).

## Token budget (MANDATORY)

- Stages 0-1 use Bash scripts (topology) + ONE parallel Explore
  dispatch — no full file Reads in the main session.
- Stage 2 interview uses `AskUserQuestion` (≤4 per round) — never
  free-form prose questions.
- Stage 3 mining uses 3 parallel Explore agents — output stages
  to `_onboard-staging/` for the drafting agent, never read back
  into main context.
- Stage 4 drafting is delegated to `onboarding-engineer` agent —
  do not re-read the drafts in main context; trust its summary.
- Stage 5 ratification reads only `_onboard-staging/a-rule-candidates.md`
  with `limit: 200`.
- Stage 6 state capture uses `AskUserQuestion` + paste-friendly
  textboxes — no scanning of foreign tools (Jira / Linear) in-session.
- **Hard cap: 50k tokens** main-session context across all 8 stages
  for a medium project.

## Subcommands

- `/onboard` — fresh full wizard (Stages 0-7). Stage 8 (retro) runs
  separately after the first sprint closes.
- `/onboard refresh` — re-onboard mode. Skip stages whose input
  hasn't changed; re-mine git history; present DELTA only.
- `/onboard scan` — Stage 1 only. Regenerate
  `docs/setup/codebase-orientation.md`. Cheap; safe to re-run
  whenever the codebase shape changes substantially.
- `/onboard rules` — Stages 3+5 only. Re-mine git history for new
  A-rule candidates + ratify.
- `/onboard retro` — Stage 8 only. After the first sprint closes,
  reflect on what worked / didn't in the wizard itself; refine the
  control plane.

## Stage 0 — Pre-flight (auto)

```bash
# Topology probe (languages / frameworks / areas / plugins / sibling installs)
.claude/skills/onboard/scripts/detect-topology.sh "$PROJECT_DIR"
```

Before proceeding, confirm the required plugins are installed (`pr-review-toolkit`
required, `superpowers` recommended) — see
[`../../../docs/setup/plugin-dependencies.md`](../../../docs/setup/plugin-dependencies.md)
§Verify for the one-line check.

Read the topology JSON. Branch on:

- `existing_install: true` → switch to `/onboard refresh` mode unless
  user explicitly asked for full re-run.
- `git_repo: false` → warn the operator; mining stages will be
  empty (no signal). Suggest `git init` if appropriate.
- `git_commits < 10` → warn that A-rule mining will produce few
  candidates; greenfield projects benefit less from Stage 3.
- `sibling_installs: [...]` non-empty → flag for Stage 4
  inheritance prompt (see `references/multi-repo-coordination.md`).
- `frameworks: [...]` → these (next / vue / react / …) tell the Stage 3
  code-style sampler which UI files to sample. No architecture is chosen
  from them — the core engineers conform to whatever the code does.
- `presets_recommended` → only the shipped infra preset (`k8s-helm`) is
  ever recommended, and only when Chart.yaml/charts are present. If it's
  recommended but not installed, suggest re-running `install.sh --preset
  k8s-helm`. There is no backend/frontend architecture preset to pick — the
  core `backend-engineer` / `frontend-engineer` handle those by reading the
  codebase (see Stage 3 + `docs/setup/conform-to-codebase.md`).
- **`plugins` → required-plugin readiness (DO NOT skip this check).** The
  workflow depends on two Claude Code plugins (install via `/plugin` →
  `claude-plugins-official`; see `docs/setup/plugin-dependencies.md`):
  - `pr-review-toolkit: false` → **blocking-ish**: Gate 4b (quality review)
    dispatches its reviewers. Without it, warn loudly and tell the operator
    the gate falls back to the built-in `feature-dev:code-reviewer` +
    `senior-tech-lead` (degraded). Strongly recommend installing it first.
  - `superpowers: false` → **warn**: A001/A003 + the fix flow invoke its
    skills (TDD / verification / systematic-debugging). Without it those
    won't auto-invoke, but the inline A-rules + `discipline-red-flags.md`
    still apply. Recommend installing it.

Report Stage 0 summary as the first interactive checkpoint:

```
== Stage 0: Pre-flight ==
Topology: monorepo (areas: backend, frontend)
Languages: go, typescript    Frameworks: next
Git: 247 commits in last 6 months
Existing install: no
Sibling installs: ../service-billing (1 found)
Presets: none required (core is architecture-agnostic; k8s-helm only if you deploy via Helm)
Plugins: superpowers ✓ · pr-review-toolkit ✗ ← REQUIRED for Gate 4b
  ⚠ install pr-review-toolkit (/plugin → claude-plugins-official) before the first sprint,
    or the 6-gate review falls back to feature-dev:code-reviewer (degraded).
Proceed? [Y/n]
```

## Stage 1 — Codebase scan (1 Explore agent, ~5 min)

Dispatch ONE Explore agent (read-only) with this brief:

```
Scan this project's codebase. Return a structural map that will become
docs/setup/codebase-orientation.md (a Stage 1 staging artifact). Cover:
1. Top-level architecture — directory roles, languages, frameworks.
2. Module / area boundaries — which folders own which concerns.
3. Top 10 most-edited files in last 6 months (`git log` churn).
4. External integrations — APIs, databases, queues, third-party SDKs.
5. Test patterns — frameworks, layout, current coverage.
6. Build / CI commands that ACTUALLY run (Makefile / package.json /
   .github/workflows).
7. Anything that looks like an unwritten convention.
Write to docs/setup/codebase-orientation.md (~600-800 words).
```

Wait for return. Confirm the file exists + is non-trivial (> 30
lines) before Stage 2.

## Stage 2 — Team interview (AskUserQuestion, 3 rounds)

See `references/interview-questions.md` for the full bank. Each round
≤ 4 questions per `AskUserQuestion` invocation.

**Round 1 — System soul** (always run):
- What does this system DO? (1 sentence)
- Who consumes it?
- What's uniquely fragile / hard to change?
- Where's the design source-of-truth? (ADR folder / Confluence URL / Notion / `none yet`)

**Round 2 — Conventions** (always run):
- Branch naming convention
- Commit message convention
- Test policy (TDD strict / test-after / case-by-case)
- Deploy workflow (CI provider + flow)
- **Exemplary files** — point at 1-2 files that best represent "how we
  write code here" (a model handler, a model component/test). Stage 3-D
  samples these first when seeding `code-style.md`.

**Round 3 — First-sprint state** (always run):
- Currently in a sprint? (yes/no + sprint name)
- Top 3 known carry-overs / tech debt items
- One small task you'd like to pilot the workflow with

Stage answers as a single markdown file at
`docs/setup/_onboard-staging/interview-answers.md` for the drafting
agent to read.

## Stage 3 — Pattern mining (4 parallel Explore agents)

Dispatch all FOUR in a single message:

**Agent A — Bug postmortem miner:**
```bash
.claude/skills/onboard/scripts/mine-git-history.sh "$PROJECT_DIR" --months 6
```
Output JSONL → `_onboard-staging/git-signals.jsonl`. Agent
summarizes the top recurring fix patterns + proposes 3-7 A-rule
candidate names (NOT bodies; bodies come in Stage 4).

**Agent B — Convention sniffer:**
```bash
.claude/skills/onboard/scripts/extract-pr-comments.sh "$PROJECT_DIR" --limit 30
```
Output JSONL → `_onboard-staging/pr-comments.jsonl`. Agent finds
repeated review comments (≥ 3 occurrences of the same phrase /
pattern) → unwritten conventions. Output → `_onboard-staging/conventions-raw.md`.

**Agent C — Architectural drift detector:**
Free-form Explore. Walks the import graph (if present), looks for
boundary violations (handlers calling DB directly, infrastructure
leaking into domain, layer crossings). Output →
`_onboard-staging/drift-findings.md`.

**Agent D — Code-style sampler (the key input for the engineers):**
Read-only Explore. Using `languages` + `frameworks` from Stage 0, samples
**2-4 representative files per area+language** — a handler/entrypoint, a
core-logic file, a test, and (frontend) a component. Extracts the project's
**actual** conventions: file layout, naming, error handling, test structure,
state/styling/i18n idioms (frontend), and which libraries are idiomatic.
Output → `_onboard-staging/code-style-signals.md`. This is what makes
`backend-engineer` / `frontend-engineer` write code that looks like the repo.

See `references/pattern-mining-prompts.md` for the full prompts.

## Stage 4 — Draft documentation (onboarding-engineer agent)

Dispatch the `onboarding-engineer` agent with:

```
Inputs staged:
  docs/setup/codebase-orientation.md         (Stage 1)
  docs/setup/_onboard-staging/interview-answers.md  (Stage 2)
  docs/setup/_onboard-staging/git-signals.jsonl     (Stage 3-A)
  docs/setup/_onboard-staging/pr-comments.jsonl     (Stage 3-B)
  docs/setup/_onboard-staging/conventions-raw.md    (Stage 3-B)
  docs/setup/_onboard-staging/drift-findings.md     (Stage 3-C)
  docs/setup/_onboard-staging/code-style-signals.md (Stage 3-D)

Produce:
  CLAUDE.md (root) — filled from interview + scan
  <area>/CLAUDE.md per area — filled from scan
  docs/setup/codebase-orientation.md — polished
  docs/setup/team-conventions.md — from conventions-raw + drift
  .claude/rules/code-style.md — fill the stub from code-style-signals.md
       (per area → per aspect: layout, naming, error handling, tests,
        framework idioms). This is the style contract the engineers read.
  docs/setup/_onboard-staging/a-rule-candidates.md — 10 ranked drafts

Do NOT write A-rules into brain-hot.md directly. Ratification is the
operator's job at Stage 5. (code-style.md is descriptive, not a hard rule —
write it directly, then have the operator skim it in Stage 5.)
```

Wait for return. Confirm output files exist before Stage 5.

## Stage 5 — A-rule ratification (AskUserQuestion, multi-select)

Read `_onboard-staging/a-rule-candidates.md` (with `limit: 200`).
For each draft, present a multi-select `AskUserQuestion`:

- **Keep** — land verbatim in `brain-hot.md` `## Project-specific rules`
- **Keep with edits** — operator types the revised wording
- **Drop** — not relevant to this team

Append the kept rules to `.claude/rules/brain-hot.md` under the
`## Project-specific rules` section, starting at A011 (or the next
free A-number if the operator had pre-existing project rules).

**Never auto-apply.** If the operator selects nothing, that's a
valid outcome — note in the Stage 5 summary that no A-rules were
ratified yet and `/onboard rules` can re-run mining later.

## Stage 6 — State capture (AskUserQuestion + paste prompts)

Walk the operator through filling three files:

1. **`docs/project/STATUS.md`** — `AskUserQuestion`:
   - Currently active sprint? (default: "S00 — Onboarding")
   - In-flight task? (default: none)
   - Branch convention from Stage 2 Round 2 — pre-fill
2. **`docs/project/backlog.md`** — paste prompt:
   "Paste any current backlog rows (export from Jira/Linear/Issues).
   I'll reformat to the `BACKLOG_ENTRY_TEMPLATE.md` shape.
   Or skip — we can seed it during the first sprint."
3. **`docs/project/FOLLOWUPS.md`** — `AskUserQuestion` from Round 3
   answers — list the top 3 known carry-overs as F-rows.

## Stage 7 — First-feature shakedown handoff

Final interactive moment:

```
== Onboarding complete ==
Files written:
  CLAUDE.md (root)
  <N> per-area CLAUDE.md
  .claude/rules/brain-hot.md (A011 ... A0<NN>)
  docs/setup/codebase-orientation.md
  docs/setup/team-conventions.md
  docs/project/STATUS.md / backlog.md / FOLLOWUPS.md

Next step: pilot the workflow on a small task from Stage 2 Round 3.
Run /next-task to dispatch, or /discover <idea> if you want to
capture more discovery items first.

Stage 8 (onboarding retro) runs after that first sprint closes —
invoke `/onboard retro` then.
```

Return control. Wizard done.

## Stage 8 — Onboarding retro (deferred, `/onboard retro`)

Runs only after the operator's first sprint closes (i.e. they've run
`/retro` at least once). Captures lessons about the wizard itself:

- Which stages took longer than expected?
- Which interview questions felt wrong / missing?
- Which A-rule drafts were dropped + why?
- Which gates were misfit (over-applied / under-applied) for this
  team's reality?

Writes `docs/project/retros/onboarding.md`. Surfaces candidates for
refining the control plane (`brain-hot.md` adjustments, new B-rules,
phase-matrix tweaks).

## Multi-repo coordination

If Stage 0 detected `sibling_installs`, Stage 4 dispatch includes an
extra prompt: *"Inherit project-local A-rules from sibling `<path>`?
This copies the ratified A011+ rules from the sibling's brain-hot.md
into this project's drafts."*

If yes:
1. Read sibling's `.claude/rules/brain-hot.md`, extract its
   `## Project-specific rules` section
2. Merge into THIS project's Stage 4 candidates (de-dup by rule
   name)
3. Document the inheritance link in
   `docs/setup/sibling-repos.md` (template lands in target)

See `references/multi-repo-coordination.md` for the full protocol.

## Failure / fallback

- **Stage 1 Explore returns thin output** (< 30 lines) → stop, ask
  operator to confirm the project actually has code in it; suggest
  rerunning after the initial commits.
- **Stage 3 mining returns 0 signals** → skip Stage 5 A-rule
  ratification; note "greenfield project, no historical signal".
- **Stage 4 agent returns with `_TODO operator_` markers** → surface
  them at Stage 5 alongside A-rule ratification; ask the operator to
  fill the gaps before moving to Stage 6.
- **Operator aborts mid-wizard** → `_onboard-staging/` is left in
  place; re-running `/onboard` resumes from the last completed
  stage (detect via file presence).

## See also

- `.claude/agents/onboarding-engineer.md` — the drafting agent
  dispatched at Stage 4
- `references/repo-topology-detection.md` — how topology classification
  drives downstream stages
- `references/interview-questions.md` — full Stage 2 question bank
- `references/pattern-mining-prompts.md` — Stage 3 agent prompts
- `references/draft-templates.md` — recipes the engineer agent uses
- `references/multi-repo-coordination.md` — sibling-install + org-fork patterns
- `docs/setup/onboarding-guide.md` — human-readable companion
- `docs/setup/multi-team-deployment.md` — the org-fork pattern for shared rules
