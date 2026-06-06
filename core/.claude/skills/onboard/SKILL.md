---
name: onboard
description: "Use right after install.sh — '/onboard', 'how do I get started', 'set up the workflow', 'onboard the project'. Auto-generates the project-understanding docs the orchestrator + every dispatched agent read: the ARCHITECTURE map (docs/setup/codebase-orientation.md), the CONVENTIONS reference (.claude/rules/code-style.md), and the CLAUDE.md routing — by scanning + mining the codebase. Minutes, mostly automated. Subcommands: /onboard refresh (re-generate after the code changed), /onboard interview (OPTIONAL deep human enrichment), /onboard rules (re-mine + ratify A-rules), /onboard retro (post-first-sprint reflection)."
user_invocable: true
---

# /onboard — Generate the project-understanding docs

**Announce:** Using /onboard to generate the architecture + conventions docs.

**Purpose.** Bring the orchestrator and every dispatched agent from "template
installed" to "understands THIS project" — by **auto-generating, from the
codebase**, the three things the agents actually read:

| Output | What it is | Who reads it |
|---|---|---|
| `docs/setup/codebase-orientation.md` | the **architecture map** (structure, areas, stack, integrations, build/test) | orchestrator + agents (pre-task ritual) |
| `.claude/rules/code-style.md` | the **conventions reference** (layout, naming, error handling, test + framework idioms) | `backend-engineer` / `frontend-engineer` |
| `CLAUDE.md` (root) + area `CLAUDE.md` | routing + non-negotiables, drafted from the two above | orchestrator + agents |

Mostly automated (read-only Explore agents + one drafting agent) — **minutes, not
hours**. The deep human interview is **opt-in** (`/onboard interview`), not required.

## Token budget

- Stages 0-2 are Bash (topology) + read-only Explore dispatches — no full file
  Reads in the main session; miners stage their output to `_onboard-staging/`.
- Stage 3 drafting is delegated to `onboarding-engineer` — trust its summary,
  don't re-Read the drafts. **Hard cap: ~30k** main-session tokens for the
  automated path (the old interview path cost far more).

## Modes

- **`/onboard`** — auto-generate the understanding docs (Stage 0→3 below). Default.
- **`/onboard refresh`** — re-run the generation; present DELTA only (skip stages
  whose inputs are unchanged).
- **`/onboard interview`** — OPTIONAL deep human enrichment for context only humans
  have (system purpose, what's fragile, exemplary files, sprint state). See §Interview.
- **`/onboard rules`** — re-mine git history for A-rule candidates + ratify them
  (operator-gated). See §Ratify.
- **`/onboard retro`** — after the first sprint closes, reflect on the wizard itself.

---

## Stage 0 — Pre-flight (auto)

```bash
.claude/skills/onboard/scripts/detect-topology.sh "$PROJECT_DIR"
```

Confirm the required plugins are installed (`pr-review-toolkit` required,
`superpowers` recommended) — see
[`../../../docs/setup/plugin-dependencies.md`](../../../docs/setup/plugin-dependencies.md)
§Verify. Read the topology JSON and branch:

- `existing_install: true` → switch to `refresh` mode unless a full re-run was asked.
- `git_repo: false` / `git_commits < 10` → warn that convention mining will be thin
  (greenfield); proceed with the scan, skip the git-history miner.
- `sibling_installs: [...]` → offer A-rule inheritance at Stage 3 (see
  [`references/multi-repo-coordination.md`](references/multi-repo-coordination.md)).
- `frameworks: [...]` → tells the code-style sampler which UI files to sample. No
  architecture is imposed — the core engineers conform to whatever the code does.

## Stage 1 — Architecture scan (1 Explore agent)

Dispatch ONE read-only Explore agent to produce the **architecture map**. Brief it
to cover: top-level architecture (directory roles, languages, frameworks); module
/ area boundaries; the 10 most-edited files (6-month `git log` churn); external
integrations (APIs, DBs, queues, SDKs); test patterns + how coverage runs; the
build / CI commands that ACTUALLY run; and any unwritten convention it spots.
Write `docs/setup/codebase-orientation.md` (~600-800 words). Confirm it exists and
is non-trivial (>30 lines) before Stage 2.

## Stage 2 — Conventions mining (parallel Explore agents)

Dispatch the miners in a SINGLE message; each stages output to
`docs/setup/_onboard-staging/`. Full prompts:
[`references/pattern-mining-prompts.md`](references/pattern-mining-prompts.md).

- **Code-style sampler** (the key input) — samples 2-4 representative files per
  area+language (handler, core-logic, test, component) and extracts the project's
  ACTUAL conventions → `code-style-signals.md`. This is what makes the engineers
  write code that looks like the repo.
- **Git-history miner** — `scripts/mine-git-history.sh "$PROJECT_DIR" --months 6`
  → recurring fix patterns + 3-7 A-rule candidate names (not bodies).
- **Convention sniffer** — `scripts/extract-pr-comments.sh "$PROJECT_DIR" --limit 30`
  → repeated review comments (≥3×) = unwritten conventions → `conventions-raw.md`.
- **Drift detector** (optional) — boundary violations (handler→DB direct, infra
  leaking into domain) → `drift-findings.md`.

> Greenfield (Stage 0 said thin git history) → run only the code-style sampler.

## Stage 3 — Draft the docs (onboarding-engineer agent)

Dispatch `onboarding-engineer` with the staged inputs. It produces:
`CLAUDE.md` (root routing + non-negotiables), per-area `CLAUDE.md`, the polished
`docs/setup/codebase-orientation.md`, `docs/setup/team-conventions.md`, and fills
`.claude/rules/code-style.md` from `code-style-signals.md` (per area → per aspect).
It also writes `_onboard-staging/a-rule-candidates.md` (ranked drafts). Recipes:
[`references/draft-templates.md`](references/draft-templates.md).

> **A-rules are NOT landed automatically.** `code-style.md` is descriptive (written
> directly); A-rules are operator-gated — candidates wait for `/onboard rules`.

## Stage 4 — Summary + handoff

Print what was written (the 3 docs above + area CLAUDE.md + the A-rule candidate
count), then hand off:

```
== Onboarding docs generated ==
  docs/setup/codebase-orientation.md   (architecture map)
  .claude/rules/code-style.md          (conventions reference)
  CLAUDE.md + <N> area CLAUDE.md        (routing)
  <K> A-rule candidates (not yet landed)

Next:  /work            — pick or scaffold the first sprint and start
Later: /onboard rules     — ratify the A-rule candidates
       /onboard interview — capture human-only context (optional)
```

The orchestrator + agents now read these via the pre-task ritual. Done.

---

## §Interview — `/onboard interview` (OPTIONAL human enrichment)

For teams that want the human-only context captured. 3 short `AskUserQuestion`
rounds (≤4 questions each) — system soul (what it does, who consumes it, what's
fragile, design source-of-truth); conventions (branch/commit/test/deploy +
exemplary files); first-sprint state. Full bank:
[`references/interview-questions.md`](references/interview-questions.md). Answers
are folded into `CLAUDE.md` + `team-conventions.md` (re-run the Stage 3 drafter
with the interview answers staged). Not required for agents to function.

## §Ratify — `/onboard rules` (operator-gated A-rule landing)

Re-mine if needed, then for each `_onboard-staging/a-rule-candidates.md` draft,
present a multi-select `AskUserQuestion`: **Keep** (land verbatim) / **Keep with
edits** / **Drop**. Append kept rules to `.claude/rules/brain-hot.md`
`## Project-specific rules` (A011+). **Never auto-apply.** Selecting nothing is a
valid outcome. (Same gate as `/retro ratify`.)

## `/onboard retro` — post-first-sprint reflection

Runs after the first `/retro`. Captures lessons about the wizard itself (which
stages misfit, which A-rule drafts were dropped + why, which gates were over/under-
applied) → `docs/project/sprints/S<N>/retro.md` or a dedicated onboarding note.

## Failure / fallback

- Stage 1 returns thin (<30 lines) → confirm the project has code; suggest re-running
  after the first commits.
- Stage 2 mining returns 0 signals → note "greenfield, no historical signal"; the
  code-style sampler still seeds `code-style.md`.
- Stage 3 returns `_TODO operator_` markers → surface them; the operator fills the
  gaps (or runs `/onboard interview`).
- Operator aborts → `_onboard-staging/` is left in place; re-running resumes from
  the last completed stage (detect via file presence).

## See also

- [`../../agents/onboarding-engineer.md`](../../agents/onboarding-engineer.md) — the Stage 3 drafting agent
- [`references/pattern-mining-prompts.md`](references/pattern-mining-prompts.md) · [`references/draft-templates.md`](references/draft-templates.md) · [`references/interview-questions.md`](references/interview-questions.md)
- [`references/repo-topology-detection.md`](references/repo-topology-detection.md) · [`references/multi-repo-coordination.md`](references/multi-repo-coordination.md)
- [`../../../docs/setup/onboarding-guide.md`](../../../docs/setup/onboarding-guide.md) — human-readable companion
