# Onboarding Guide — operator companion to `/onboard`

> The `/onboard` skill is the wizard Claude Code runs. **This guide is
> for you, the operator.** Read it at your own pace before / during /
> after the wizard. The skill drives mechanics; this doc explains
> intent, edge cases, and how to push back when the wizard's wrong.
>
> Sister doc: `docs/getting-started-tour.md` — covers what to
> read first across the whole template. Read it before this if you
> haven't.

## 1. What `/onboard` is for

`/onboard` runs once, right after `install.sh` puts the template into
your project. Its job: take Claude Code from "template installed,
empty defaults" to "fully understands THIS project — its purpose, its
conventions, its fragile spots, its first sprint." It writes:

- Root `CLAUDE.md` filled with your project's purpose + N-rules
- Per-area `CLAUDE.md` if you have a monorepo
- `brain-hot.md` candidates for A011+ project-local rules
- `docs/setup/codebase-orientation.md` — the first-day-reader map
- `docs/setup/team-conventions.md` — softer conventions tier
- Initial `docs/project/sprints/S<N>/tasks.md` (the active sprint board) / `backlog.md` (with `## Follow-ups`)

Runtime: **minutes** on a medium project — the default path is automated
(scan → mine → draft), producing the architecture map + conventions reference +
CLAUDE.md routing with little human input. The deep interview (`/onboard
interview`) and A-rule ratification (`/onboard rules`) are **opt-in** enrichment
you can run later — they are no longer part of the required path.

**When NOT to run it:** if your project is greenfield with < 5
commits, the mining stages won't find signal. Onboard anyway — just
expect fewer A-rule candidates and plan to re-run `/onboard rules`
after the first sprint closes.

## 2. Before you start

### Prereqs

- **`jq`** installed (`brew install jq` / `apt install jq`). Used by
  every Stage 3 script. Without `jq`, Stage 3 silently returns zero
  signals.
- **`gh` CLI** authenticated (optional but recommended). Without it,
  Stage 3 Agent B (convention sniffer) returns zero PR comments —
  you lose half of the unwritten-convention signal.
- **Project has committed code.** The wizard runs without commits but
  the mining stages return nothing useful. Aim for ≥ 30 commits before
  running for the first time.
- **Presets are optional.** No backend/frontend preset is needed — the
  core `backend-engineer` / `frontend-engineer` read your codebase and
  conform. The only shipped preset is `k8s-helm` (infra); install it if
  you deploy via Helm. Stage 3 derives your code conventions into
  `.claude/rules/code-style.md` regardless. (Want an opinionated
  architecture enforced? Author a custom preset — `docs/adding-new-preset.md`.)

### Time budget

| Stage | Wizard work | Your work |
|---|---|---|
| 0 — Pre-flight | < 1 min | Confirm proceed |
| 1 — Codebase scan | 5-10 min (Explore agent) | Skim the output |
| 2 — Interview | 1 min | 30 min answering 11 questions |
| 3 — Mining | 10-20 min (3 parallel agents) | Wait |
| 4 — Drafting | 15-30 min (engineer agent) | Wait |
| 5 — Ratification | 1 min | 20 min reviewing 10 drafts |
| 6 — State capture | 5 min | 10 min pasting backlog rows |
| 7 — Handoff | < 1 min | Read the summary |

Total: ~1 hour of your active time + 1-2 hours of wizard work you can
do something else during.

## 3. The 8 stages — what to expect

### Stage 0 — Pre-flight

Runs `detect-topology.sh`, prints a summary, asks you to confirm.
**Watch for:** "missing preset" warning. If your stack needs a preset
that isn't installed, the wizard suggests aborting + re-running
`install.sh`. Take the suggestion — running without the right preset
means your N1 (architecture boundary) rule lands as a placeholder.

### Stage 1 — Codebase scan

ONE Explore agent walks the codebase, writes
`docs/setup/codebase-orientation.md`. You wait. If the output is
< 30 lines, the wizard stops + asks "does your project actually have
code?" — if you just initialized the repo, this is the wizard
telling you to come back after committing real work.

### Stage 2 — Team interview

11 questions across 3 rounds (+ optional Round 4 for compliance).
Each round is one `AskUserQuestion` call — multiple selects in the
harness UI. Full bank: `core/.claude/skills/onboard/references/interview-questions.md`.

**Push back when:** the wizard pre-fills a default you disagree with.
Pre-fills are template defaults (TDD-strict, Conventional Commits,
`<type>/<task-id>-<slug>` branches) — they exist because the absence
of a convention is itself a problem. If your team actually does
something different, type it; the wizard adapts the drafts.

### Stage 3 — Pattern mining (parallel)

Three Explore agents run in parallel:

- **Agent A** mines git history for bug-fix hotspots, keywords,
  reverters → `_onboard-staging/bug-clusters.md`
- **Agent B** mines PR review comments for repeated phrases →
  `_onboard-staging/conventions-raw.md`
- **Agent C** walks the import graph for boundary violations →
  `_onboard-staging/drift-findings.md`

If your project has < 30 fix commits, Agent A returns thin output. If
`gh` isn't authed, Agent B returns nothing. Both are OK — Agent C
runs regardless and you can re-run mining later via `/onboard rules`.

### Stage 4 — Draft documentation

The `onboarding-engineer` agent reads Stages 1-3 outputs + the
interview, then drafts every doc. You wait. The agent writes drafts
ONLY to staging or to the final paths — but A-rules go to
`_onboard-staging/a-rule-candidates.md`, NOT to `brain-hot.md`.
Nothing is binding yet.

### Stage 5 — A-rule ratification

The wizard reads the candidates file and presents them one-by-one as
multi-select `AskUserQuestion`: Keep / Keep with edits / Drop. **Read
the evidence on each candidate.** A candidate without strong
evidence (1 SHA, no recurrence) is probably noise — drop it. A
candidate with 5+ SHAs across 3 months is almost certainly real —
keep it.

Edits are encouraged — the wizard's wording is a draft, your rewrite
is the canonical one.

### Stage 6 — State capture

Two files: the active sprint board (`docs/project/sprints/S<N>/tasks.md`) and `backlog.md` (which includes the `## Follow-ups` section). The wizard pre-fills from your interview. The backlog step has a paste prompt — copy 5-10 rows from Jira / Linear / Issues into the textbox; the wizard reformats to the template's `BACKLOG_ENTRY_TEMPLATE.md` shape. Skip if you'd rather seed it during the first sprint.

### Stage 7 — Handoff

Final summary: files written, A-rules ratified, suggested first task
(your Round 3 Q11 answer). Run `/work` to dispatch the first
task, or `/idea <idea>` if you want to capture more ideas first.

### Stage 8 — Onboarding retro (deferred)

Runs only AFTER your first sprint closes (i.e. after you've run
`/retro` at least once). Invoke `/onboard retro` then. The wizard
captures lessons about itself — which questions felt missing, which
A-rule drafts were dropped + why, which gates were over- or
under-applied. Output: `docs/project/retros/onboarding.md`. Use it to
refine your team's control plane.

## 4. Reading the drafts before ratifying

At Stage 5, you'll see ~10 A-rule candidates. For each, look at:

1. **Evidence count.** A candidate cites SHAs / PR comments /
   hotspots / interview answers. More citations = more confidence.
   < 3 citations = probably skip.
2. **Recurrence pattern.** Same file hit 12 times in 6 months =
   strong rule. Same file hit twice in one week (one bad refactor) =
   incident, not rule.
3. **Blast radius.** A rule about a hot adapter that 5 teams import =
   high blast radius, ship it. A rule about a tools script no-one
   touches = low blast radius, drop or downgrade to convention.
4. **Rule body clarity.** The draft rule is one sentence. If you
   can't restate it as an imperative ("Always X before Y") without
   ambiguity, edit before keeping.

**Push back when:** the wizard proposed a rule that sounds good in
the abstract but doesn't match your project's reality. Common case:
"Always use table-driven tests" because PR comments mention them 3
times — but actually your team uses subtests for state-heavy cases.
Edit the rule wording or drop it.

## 5. Multi-repo decision tree

```
How many AI-Workflows installs are in your org?
────────────────────────────────────────────────
1 (this project, no siblings)   →   No sharing needed. Run /onboard normally.
2 siblings                       →   Accept the inheritance offer at Stage 4.
3+ siblings                      →   Adopt the org-fork pattern. See
                                     docs/setup/multi-team-deployment.md.
Meta-repo with submodules        →   Onboard the meta first; per-submodule
                                     onboarding is optional + inherits.
```

Full mechanic: `core/.claude/skills/onboard/references/multi-repo-coordination.md`.

If you're not sure → start with sibling inheritance. Upgrade to
org-fork when copy-paste drift gets painful.

## 6. After the wizard

The wizard finishing isn't the end. Manual tuning over the next 1-2
weeks:

- **First sprint as pilot.** Run the small task from Round 3 Q11.
  Notice where the wizard's drafts didn't match reality. Don't fix
  them mid-sprint — capture in live mini-retros.
- **First retro.** Run `/retro` at sprint close as usual. The retro
  surfaces convention misfits.
- **`/onboard retro`.** Run it AFTER the first `/retro`. It captures
  wizard-specific lessons + suggests follow-up actions (e.g. "Add
  Round 4 question about feature flags — operator mentioned them 3
  times but the wizard didn't have a slot").
- **Iterate `brain-hot.md`.** Add A-rules as new patterns emerge. The
  wizard's initial set is the floor, not the ceiling.

## 7. Common stumbles

### Greenfield project with no git history

**Symptom:** Stage 3 Agent A returns "greenfield, no signals." Stage
5 has 0-2 candidates instead of 10.

**Fix:** ignore the lack of candidates. Run normally; revisit with
`/onboard rules` after the first 30+ commits.

### Conflicting interview answers

**Symptom:** Stage 4 dispatch summary flags "Round 2 Q7 says TDD-strict
but Round 3 Q11 names a typo fix as the pilot."

**Fix:** resolve at Stage 5 ratification. Either tighten Q7 (TDD-strict
for `usecase/` only, not for `chore`-class tasks) or pick a different
pilot task. The wizard surfaces the tension so you decide — it never
silently picks for you.

### Area dirs the script missed

**Symptom:** Stage 0 reports `monorepo` with `areas: [backend,
frontend]` but your project also has `mobile/` (which has no
package.json at root — uses Expo's `app.json`).

**Fix:** at Stage 4 dispatch, the wizard accepts an operator-supplied
area override. Type: "Also draft `mobile/CLAUDE.md` — manifest is
`mobile/app.json`." The drafter adapts.

If you miss the moment, post-wizard: copy any existing per-area
`CLAUDE.md` to `mobile/CLAUDE.md`, edit by hand. Or re-run
`/onboard scan` after adding a `mobile/Makefile` so Stage 0 detects
the area.

### Sibling inheritance picked up rules that don't fit

**Symptom:** Stage 5 surfaces 4 candidates inherited from
`../service-billing` that mention Postgres advisory locks, but your
new project doesn't use Postgres.

**Fix:** drop all 4 candidates. The wizard inherits soft — copies
once, doesn't symlink. Dropping doesn't affect the sibling.

## 8. FAQ

### Can I re-run `/onboard`?

Yes. Use `/onboard refresh` to re-onboard with DELTA-only output (the
wizard skips stages whose inputs haven't changed). Or `/onboard scan`
/ `/onboard rules` for partial re-runs.

### Is `/onboard` idempotent?

Mostly. Re-running with no changes is a no-op for files already
written. The only non-idempotent step is Stage 5 ratification — the
wizard re-surfaces candidates each run; you re-ratify each run.
Already-kept rules stay kept; the wizard just doesn't duplicate them.

### What's `_onboard-staging/`?

`docs/setup/_onboard-staging/` holds intermediate artifacts (Stage 1
raw scan, Stage 3 JSONL signals, Stage 4 candidates). The wizard
reads from it across stages and ignores it after the wizard finishes.
Safe to delete after Stage 7; safe to keep for `/onboard retro` later.
Add it to `.gitignore` if you don't want it tracked.

### How do I roll back?

The wizard writes drafts; nothing is hidden. To roll back:

```bash
git -C <project> diff           # see what changed
git -C <project> checkout .     # discard everything (destructive!)
# Or selectively:
git -C <project> checkout -- CLAUDE.md
```

Stage 5 ratifications land in `.claude/rules/brain-hot.md` only
after you say "Keep" — if you said "Drop" for everything, nothing
got committed to brain-hot.

### What if the wizard crashes mid-flight?

`_onboard-staging/` is left in place. Re-running `/onboard` detects
the staging files and resumes from the last completed stage. You can
also abort fully: `rm -rf docs/setup/_onboard-staging/` + re-run from
Stage 0.

### Does the wizard touch my code?

No. The wizard writes docs only (`.md` files). The drafting agent
(`onboarding-engineer`) is build-only — no code modification, no
commits. You commit when you're ready, after Stage 7.

## See also

- `core/.claude/skills/onboard/SKILL.md` — the wizard mechanics
- `core/.claude/agents/onboarding-engineer.md` — the drafting
  specialist
- `core/.claude/skills/onboard/references/interview-questions.md` —
  full Stage 2 bank with rationale
- `core/.claude/skills/onboard/references/repo-topology-detection.md` —
  Stage 0 deep-dive
- `core/.claude/skills/onboard/references/pattern-mining-prompts.md` —
  Stage 3 prompts
- `core/.claude/skills/onboard/references/draft-templates.md` —
  Stage 4 recipes
- `core/.claude/skills/onboard/references/multi-repo-coordination.md` —
  sibling / org-fork / meta-repo handling
- `core/docs/setup/multi-team-deployment.md` — canonical org-fork
  pattern
- `core/docs/getting-started-tour.md` — what to read first
  across the template (sister doc — read before this one)
