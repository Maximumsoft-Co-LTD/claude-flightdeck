# Draft Templates — recipes for the `onboarding-engineer` agent

> The `onboarding-engineer` agent applies these recipes in Stage 4 of
> `/onboard`. Each section is a mapping from inputs (interview answers,
> Stage 1 scan, Stage 3 mining output) → drafted output. The agent is
> a doc-drafting specialist; nothing in this file authorizes it to
> auto-apply, run code, or commit. Drafts only.

## A. Drafting root `CLAUDE.md`

Start from `core/CLAUDE.md.tmpl` (already rendered by `install.sh`,
so placeholders like `{{PROJECT_NAME}}` are filled in). What you fill
in is the **prose paragraph** in "What this repo is" + the bodies of
N1-N6.

### A.1 The "What this repo is" paragraph

Map Round 1 answers:

| Source | Lands in |
|---|---|
| Q1 (1-sentence purpose) | First sentence of the paragraph |
| Q2 (consumers) | Second sentence — "Consumed by …" |
| Q4 (design SoT) | Closing pointer — "Design source-of-truth: `<path>` — read before touching architecture." |

Example output (for the fictional *_example_* "URL Shortener" Go
service):

> _example_: URL Shortener service — converts long URLs into 6-char
> codes and resolves them to redirects. Consumed by 3 internal teams
> (Marketing, Sales, Support) + 1 external partner SDK. Design
> source-of-truth: `docs/adr/` — read before touching the routing or
> persistence layer.

If Q1 is `_TODO operator_`, leave the placeholder line + flag in your
output summary. Do NOT fabricate purpose from a directory walk.

### A.2 N1-N6 non-negotiables

The template ships 6 default N-rules. Augment per project signals:

| N | Default | Augment when |
|---|---|---|
| N1 Architecture boundary | preset rule file | Stage 3 Agent C flagged frequent boundary violations — strengthen with a citation to `drift-findings.md` |
| N2 Contract-first | always | If multi-service detected, add example of the project's contract dir (e.g. `contracts/openapi/`) |
| N3 6-gate review | always | If Round 2 Q7 = TDD-strict, no augmentation. If test-after, weaken gate 4 to "test-after acceptable for adapters." |
| N4 Parallel conflict prevention | always | If Stage 0 detected monorepo, add the per-area touched-files matrix shape |
| N5 Test-first | depends on Q7 | TDD-strict → full body; test-after → soft body; case-by-case → leave default + note |
| N6 Separation of Duties | regulated industries | Fire only if Optional Round 4 was answered |

Add N7+ only if the operator's answers force it (e.g. Q3 names a
fragile area and proposes the project-local rule "Always run the
`<area>`-regression suite when touching `<area>/`").

### A.3 The `## Quick start` block

Map Round 2 Q8 (deploy workflow) + Stage 1 scan's discovered commands:

```bash
# _example_ (URL Shortener):
make bootstrap        # init submodules, install deps, copy .env
make build            # build everything
make test             # run tests
make docker-up        # local stack on :8080
make smoke            # /healthz + create-shorten-resolve round-trip
```

Pull the actual command names from `Makefile` / `package.json` /
`pyproject.toml` discovered in Stage 1. Don't invent commands. If the
project lacks a Makefile, leave the block as a TODO with the
operator's deploy-workflow paragraph quoted underneath.

### A.4 The dispatch-routing table

Preserve the template's table verbatim. Add rows ONLY when the
project has a custom agent that the template doesn't ship. Example
custom row:

| If the task is… | Use `subagent_type` | Reads first |
| _example_: Lambda function authoring | `lambda-engineer` | Lambda area's CLAUDE.md + AWS SAM template |

## B. Drafting per-area `CLAUDE.md`

Fires when Stage 0 returned `type: monorepo` or `meta-repo`. One file
per declared area (`backend/CLAUDE.md`, `frontend/CLAUDE.md`, …). Each
file ~60-100 lines.

### B.1 Detect what the area IS

Read the area's manifest + a depth-2 file list to classify:

| Signals | Area is |
|---|---|
| `go.mod` + `cmd/` + `internal/` | Go service |
| `package.json` + `app/` + `next.config.*` | Next.js frontend |
| `package.json` + `src/` + `vue.config.*` | Vue frontend |
| `pyproject.toml` + tests/ | Python lib or service |
| `Chart.yaml` + `templates/` | Helm chart |
| `Dockerfile` only, no language manifest | Container build context only — note in CLAUDE.md but don't draft full rules |

### B.2 The 5-section per-area shape

Each per-area `CLAUDE.md` follows:

```markdown
# CLAUDE.md — <area name>

## What this area is
<1-paragraph purpose — from the area's README if present, else inferred
from manifest + Stage 1 scan>

## Tech stack
<bulleted: language, framework, key libs from the manifest>

## Project structure
<directory tree, depth 2, with one-line role descriptions per dir>

## Common commands
<the area's actual commands — pulled from area's Makefile / package.json scripts>

## Local rules
<area-specific rules derived from the area's actual code + the
code-style sampler. Reference `.claude/rules/code-style.md` for the
project's conventions; add a custom-preset rule file only if one is installed.>
```

### B.3 Worked example — `backend/CLAUDE.md` (Go monorepo area)

_example_:

```markdown
# CLAUDE.md — backend

## What this area is
The URL Shortener API. HTTP REST handlers + PG persistence + Redis
cache for hot-path lookups.

## Tech stack
- Go 1.22
- chi router
- pgx (Postgres driver)
- go-redis
- testify + dockertest for integration

## Project structure
- `cmd/api/` — HTTP server entrypoint
- `internal/usecase/` — pure business logic (no I/O)
- `internal/adapter/http/` — HTTP handlers
- `internal/adapter/store/` — PG + Redis adapters
- `internal/domain/` — entities + value objects
- `migrations/` — golang-migrate SQL files

## Common commands
- `make build` — compile to `bin/api`
- `make test` — unit + integration (requires Docker)
- `make migrate-up` — apply pending migrations to local PG
- `make smoke` — /healthz + shortener round-trip

## Local rules
- B1 (conventions): follow `.claude/rules/code-style.md` for this area's layout, naming, error handling, test style
- B2 (migrations): every schema change ships with an `up.sql` AND `down.sql`
- F1 (Redis fallback): handler MUST degrade to PG if Redis is unavailable
```

## C. Drafting A011+ rule candidates

Each A-rule candidate in `_onboard-staging/a-rule-candidates.md` is
ONE markdown bullet with three sub-bullets:

```markdown
- **<rule name in imperative>** — <one-sentence rule>
  - *Why:* <one-sentence evidence>
  - *How to apply:* <one sentence on when this fires>
```

### C.1 Evidence cite formats

Every candidate MUST cite at least one evidence source. Format:

| Source | Cite shape |
|---|---|
| Git commit | `(SHA abc1234: "fix subject")` |
| PR review comment | `(PR #142 review: "<quoted phrase>")` |
| Hotspot file | `(hotspot src/foo.go: 12 fixes since 2025-08)` |
| Reverter | `(reverter src/cache.go: 3 reverts since 2026-02)` |
| Interview answer | `(operator Q3: "<quoted phrase>")` |
| Drift finding | `(drift src/handler.go:42 — handler→DB direct)` |

If a candidate has multiple sources, list them all — confidence is
proportional to source count.

### C.2 Ranking

Rank by `recurrence_count × recency_weight × blast_radius`:

- **recurrence_count** — number of cited evidence records
- **recency_weight** — 1.0 for last 30 days, 0.7 for 30-90 days, 0.4
  for 90-180 days
- **blast_radius** — 3 for production code touched by ≥ 3 teams, 2
  for production touched by ≤ 2 teams, 1 for scripts / tools / tests

Top 10 candidates ship; surface the next 5 in an "Also considered"
section in case the operator wants to elevate them at Stage 5.

### C.3 Worked example (drafted, not yet ratified)

_example_:

```markdown
- **Lock the cache before reading from `cache/store.go`** — Wrap
  `Get` calls inside a `sync.RWMutex.RLock()` guard.
  - *Why:* 7 deadlock fixes in 6 months on this file
    (hotspot cache/store.go: 7 fixes since 2025-11; SHA d23f44a:
    "fix: cache deadlock under concurrent invalidation").
  - *How to apply:* Any new `cache.Store.Get` / `cache.Store.Set`
    call MUST acquire the mutex; reviewer rejects PRs that touch
    `cache/store.go` without seeing the lock.
```

## D. Polishing `codebase-orientation.md`

Stage 1's Explore agent wrote a raw scan. The `onboarding-engineer`
polishes it into a coherent first-time-reader doc. Checklist:

- [ ] H1 = project name + 1-sentence purpose (from Q1)
- [ ] "Architecture / module map" section with a directory tree
      (depth ≤ 3)
- [ ] "Hotspot files" section quoting Stage 3-A's top 5 hotspots with
      "<file>: <fix_count> fix-class commits since <date>"
- [ ] "External integrations" section listing APIs / DBs / queues /
      SDKs discovered in Stage 1
- [ ] "Test + CI conventions" section quoting Round 2 Q7 + Q8
- [ ] "Quirks worth knowing" section quoting Q3 (fragile area) + any
      Stage 3-C clean-area or violation-class notes

Target: 600-800 words. Cut Stage 1's raw walk if it exceeded that —
the polished orientation is "read this on day one to know where
things live", not an exhaustive file catalog.

## E. Writing `team-conventions.md`

Softer than A-rules — the things the team agrees on but that don't
quite rise to "always-apply non-negotiable." Comes from Stage 3
Agent B's `conventions-raw.md`.

### E.1 A-rule vs convention — the distinction

A candidate becomes an **A-rule** if:

- It's cited by ≥ 5 distinct PR comments AND
- A violation is consistently caught at code review AND
- The cost of a violation is high (bugs ship, customers see it)

A candidate becomes a **convention** if:

- It's cited by ≥ 3 PR comments BUT
- Violations are caught inconsistently (some reviewers care, others
  don't) OR
- The cost of a violation is style / readability only

If unsure → convention. Operators can elevate conventions to A-rules
later via `/onboard rules`.

### E.2 Format

Organize by area, then by theme within area. Example:

```markdown
# Team Conventions

> Soft rules — read at onboarding, follow by default. Promote to A-rule
> if violation becomes a recurring incident.

## backend/

### Naming
- Repository methods: singular for `Find` / `Get`, plural for `List`.
- Test files: `<file>_test.go` next to the file under test.

### Error handling
- Wrap errors with `fmt.Errorf("operation: %w", err)`.
- Never use `errors.Is` to match user-input strings; use sentinel
  errors only.

## frontend/

### Component layout
- One component per file. Co-locate `<name>.module.css` + `<name>.test.tsx`.
- ...
```

Target: 150-250 lines for a typical 2-area monorepo.

## See also

- `core/.claude/agents/onboarding-engineer.md` — the agent that
  applies these recipes
- `core/CLAUDE.md.tmpl` — the destination template for §A
- `core/.claude/rules/brain-hot.md` — A001-A010, the format A011+ must
  match
- `core/.claude/rules/phase-matrix.md` — how the Type slot from
  branch convention threads through
- `references/interview-questions.md` — the inputs §A consumes
- `references/pattern-mining-prompts.md` — the inputs §C + §E consume
