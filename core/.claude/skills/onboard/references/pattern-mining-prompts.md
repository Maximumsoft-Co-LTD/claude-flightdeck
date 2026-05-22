# Pattern Mining Prompts — Stage 3 agent dispatch templates

> Three parallel Explore agents run in Stage 3 of `/onboard`. Each
> agent consumes one staged artifact (or none, for Agent C), produces
> one output file under `docs/setup/_onboard-staging/`, and never
> reads back into the main session. The drafting agent
> (`onboarding-engineer`) reads the three outputs in Stage 4.
>
> Paste each block verbatim into the corresponding `Agent()` call.
> All three dispatch in a SINGLE message — see
> `dispatch-parallel` for the parallel-dispatch mechanic.

## Agent A — Bug postmortem miner

**Input:** `docs/setup/_onboard-staging/git-signals.jsonl` (output of
`mine-git-history.sh`). Three signal types: `hotspot`, `keyword`,
`reverter`.

**Output:** `docs/setup/_onboard-staging/bug-clusters.md` — ranked list
of 5-10 A-rule **candidate names** (not bodies; the bodies are
authored by `onboarding-engineer` in Stage 4 with citations).

### Prompt

```
You are Stage 3 Agent A of the /onboard wizard — bug postmortem miner.
Read-only. Output one markdown file. Do NOT write A-rules into
brain-hot.md — your job is to propose candidate names + cluster
evidence.

Inputs:
  docs/setup/_onboard-staging/git-signals.jsonl
  (One JSON record per line — schema: see
   core/.claude/skills/onboard/scripts/mine-git-history.sh header.)

Method:
1. Read the JSONL with jq. Group by `type`:
   - hotspot: file paths with ≥ 3 fix-class commits
   - keyword: words appearing ≥ 3 times in fix subjects
   - reverter: paths whose changes were reverted ≥ 2 times
2. For each cluster (max 10 across all 3 types), propose:
   - **Candidate A-rule name** — short, imperative ("Lock the cache
     before reading from `cache/store.go`")
   - **Evidence** — paste the JSON records that motivated the rule
     (cite SHA / path / count)
   - **Confidence** — high (≥ 5 signals) / medium (3-4) / low (< 3)
3. Rank by signal count × recurrence-recency-weight (recent + recurring
   = highest). Take the top 10.

Output:
  docs/setup/_onboard-staging/bug-clusters.md
  ~150-300 lines. Each candidate as an H3 section:

  ### Candidate: <imperative rule name>
  - **Type:** hotspot | keyword | reverter
  - **Confidence:** high | medium | low
  - **Evidence (JSON records):**
    ```jsonl
    {"type":"hotspot","path":"src/cache.go","fix_count":7, ...}
    ```
  - **Suggested A-rule body shape** (one sentence, NOT final):
    > Always do X before Y when touching `<path>`. Why: <reason from
    > fix subjects>.

If the input file is empty or absent → write a one-line stub:
  "No git signals — greenfield project. Skip Stage 5 A-rule
   ratification."
and exit successfully.

Token budget: ≤ 15k tokens. Do NOT Read source files referenced in
the signals — names + counts are sufficient at this stage.
```

### Empty-input fallback

If `git-signals.jsonl` is absent or empty (greenfield or pre-commit
project), Agent A writes a stub line + exits. The wizard surfaces
"Stage 3 Agent A: greenfield, skipped" in the Stage 4 dispatch
summary, and Stage 5 A-rule ratification becomes a no-op.

## Agent B — Convention sniffer

**Input:** `docs/setup/_onboard-staging/pr-comments.jsonl` (output of
`extract-pr-comments.sh`). One record per PR review comment.

**Output:** `docs/setup/_onboard-staging/conventions-raw.md` — themed
sections, each grouping repeated phrases with citations.

### Prompt

```
You are Stage 3 Agent B of the /onboard wizard — convention sniffer.
Read-only. Output one markdown file.

Inputs:
  docs/setup/_onboard-staging/pr-comments.jsonl
  (One record per PR review comment — schema: pr, author, body, path,
   line, created.)

Method:
1. Read the JSONL with jq. Lowercase the `body` field; strip
   punctuation; tokenize into 3-5-gram phrases.
2. Group by repeated phrase (≥ 3 occurrences across distinct PRs).
   Discard phrases that appear in only one PR — those are noise.
3. For each recurring phrase, classify by theme:
   - Naming (e.g. "rename this to", "should be plural", "snake_case")
   - Error handling (e.g. "swallowed error", "wrap with context")
   - Testing (e.g. "missing test for", "table-driven", "no integration")
   - Architecture (e.g. "doesn't belong here", "should be in usecase")
   - Style (e.g. "extract method", "magic number")
   - Documentation (e.g. "docstring missing", "outdated comment")
4. For each theme, summarize as a paragraph + cite 2-3 PR numbers as
   evidence.

Output:
  docs/setup/_onboard-staging/conventions-raw.md
  Sections organized by theme. Example:

  ## Naming
  Reviewers repeatedly push back on plural-vs-singular for repository
  method names. 4 occurrences (#142, #178, #203, #221) — convention:
  *use singular for `Find` / `Get`, plural for `List` / `Find...All`.*
  Operator decision: A-rule, soft convention, or skip?

If the input file is empty (no PR access / no merged PRs) → write the
stub "No PR comment signals — skip convention sniffer." and exit.

Token budget: ≤ 12k tokens. Do NOT Read source files referenced in
comments; quote the comment body and the file path only.
```

### Empty-input fallback

`extract-pr-comments.sh` fail-opens silently when `gh` is missing /
not authed / origin isn't GitHub. In all those cases, Agent B writes
the stub line and exits. Stage 4 drafts `team-conventions.md` from
codebase-orientation signals alone (less rich but functional).

## Agent C — Architectural drift detector

**Input:** None directly — Agent C explores the codebase itself, with
the codebase-orientation file as its map.

**Output:** `docs/setup/_onboard-staging/drift-findings.md` —
classified boundary violations with file:line citations.

### Prompt

```
You are Stage 3 Agent C of the /onboard wizard — architectural drift
detector. Read-only. Output one markdown file.

Inputs:
  docs/setup/codebase-orientation.md  (Stage 1 output — the
  structural map. Tells you the areas + their intended boundaries.)

Method:
1. Read codebase-orientation.md. Identify declared boundaries:
   - For Go: domain ← ports ← usecase ← adapters ← cmd (or whatever
     the preset declares)
   - For frontend FSD: shared ← entities ← features ← widgets ← pages
   - For monorepo: <area>/ must not import from <other-area>/
   - For meta-repo: submodule-to-submodule direct imports forbidden
2. Use LSP `findReferences` + `goToImplementation` where possible. If
   LSP returns empty, fall back to Grep on import lines:
   - Go: `grep -rE '^import |^\s*"' --include='*.go'`
   - TypeScript: `grep -rE 'from .[/\\.]' --include='*.ts' --include='*.tsx'`
   - Python: `grep -rE '^from |^import ' --include='*.py'`
3. Classify each finding:
   - **handler→DB direct** — handler calls DB without going through
     usecase / repository
   - **infra→domain** — infrastructure code imports domain types
     directly (should flow the other way)
   - **layer-cross** — same-language layer-skip (e.g. pages → entities
     without going through features)
   - **area-cross** — monorepo area imports another area's internals
     (should go through a published surface)
   - **submodule-cross** — meta-repo submodule depends on another
     submodule directly
4. For each finding, cite `<path>:<line>` + the import line itself.
   Note severity: high (production code) / medium (test code) / low
   (scripts / tools).

Output:
  docs/setup/_onboard-staging/drift-findings.md
  ~80-200 lines. Organized by class:

  ## handler→DB direct (3 findings)
  - `src/api/order_handler.go:42` — `import "pkg/db"` — bypasses
    `usecase/order/`. Severity: high.
  - ...

  ## layer-cross (1 finding)
  - ...

  ## Clean areas
  - <list any area you walked that had zero violations>

If you find zero violations across the whole codebase, write:
  "No drift detected — boundaries are clean as declared."
This is itself a useful signal for Stage 4 (it means current rules
are sufficient; don't propose architectural A-rules).

Token budget: ≤ 18k tokens. Use LSP where possible (cheaper); grep
fallback OK when LSP returns empty.
```

> Drift is judged against the project's OWN declared boundaries (from
> `codebase-orientation.md` / `code-style.md`), not a prescribed architecture.
> If the project has no clear boundary, report "no declared boundary to check"
> rather than inventing one.

## Agent D — Code-style sampler

Read-only Explore. Goal: derive how THIS project actually writes code so the
`backend-engineer` / `frontend-engineer` can match it. **Describe what the
code does — never prescribe an architecture.**

### Prompt

```
You are Stage 3 Agent D of the /onboard wizard — code-style sampler.
Read-only. Do NOT propose an architecture or "better" structure — only
document what's actually there.

Using the detected languages + frameworks (from Stage 0 topology), for EACH
area (backend / frontend / etc.):
1. Pick 2-4 representative files: an entrypoint/handler, a core-logic file,
   a test, and (frontend) a component. Prefer any files the operator named
   in the Round-2 interview as "how we write code here".
2. Read them and extract, with a concrete file:path example per point:
   - File layout — where each kind of file lives; one file per X? colocation?
   - Naming — function/type/file naming patterns actually used.
   - Error handling — how errors are created/wrapped/surfaced; any swallowing.
   - Tests — framework, location, assertion style, table-driven? mocks where?
   - Framework idioms — which libs are idiomatic (state, HTTP, i18n, styling);
     how dependencies are wired.
3. Flag any INCONSISTENCY (two patterns for the same thing) so the engineer
   asks rather than guesses.

Output → docs/setup/_onboard-staging/code-style-signals.md, organized per
area → per aspect, observation + example path each. No aspirational rules.

Token budget: ≤ 12k tokens. Sampling only — read a handful of files per
area, don't walk the whole tree.
```

### Empty-input fallback

If `codebase-orientation.md` is missing (Stage 1 failed or returned
thin output), Agent C cannot identify intended boundaries. It writes:

```
Cannot run drift detection — Stage 1 output (codebase-orientation.md)
missing or thin. Re-run /onboard scan first.
```

The wizard surfaces this at Stage 4 and lets the operator either
re-run Stage 1 or skip Agent C's input entirely (Stage 4 falls back
to git-signals + PR comments only).

## Dispatch shape (paste into the main session)

```
[Single message containing 4 Agent tool calls]

Agent(
  description: "Stage 3-A: bug postmortem miner",
  subagent_type: "Explore",
  prompt: "<Agent A prompt block above>"
)
Agent(
  description: "Stage 3-B: convention sniffer",
  subagent_type: "Explore",
  prompt: "<Agent B prompt block above>"
)
Agent(
  description: "Stage 3-C: architectural drift detector",
  subagent_type: "Explore",
  prompt: "<Agent C prompt block above>"
)
Agent(
  description: "Stage 3-D: code-style sampler",
  subagent_type: "Explore",
  prompt: "<Agent D prompt block above>"
)
```

All four are read-only (`Explore`) — no worktree isolation needed.
Wait for all four to return before proceeding to Stage 4.

## Failure handling

| Failure | Action |
|---|---|
| Agent A returns "greenfield" stub | Skip Stage 5 A-rule ratification; note in Stage 4 dispatch prompt |
| Agent B returns "no PR signals" stub | Stage 4 drafts `team-conventions.md` from drift-findings only |
| Agent C returns "boundaries clean" | Stage 4 drops architectural A-rule candidates; this is a healthy signal |
| Two or more agents stub-out | Wizard warns: "Greenfield-like project — Stage 4 will draft mostly from interview answers + Stage 1 scan" |
| Any agent crashes or exits non-zero | Re-dispatch only that agent (the other outputs are intact); if it crashes twice, skip + flag in Stage 4 dispatch |

## See also

- `core/.claude/skills/onboard/SKILL.md` — Stage 3 invocation
- `core/.claude/skills/onboard/scripts/mine-git-history.sh` — input for Agent A
- `core/.claude/skills/onboard/scripts/extract-pr-comments.sh` — input for Agent B
- `references/draft-templates.md` — how Stage 4 maps these outputs into final docs
- `core/.claude/skills/dispatch-parallel/SKILL.md` — parallel dispatch mechanic
