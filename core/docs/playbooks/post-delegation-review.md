# Playbook — 6-Gate Post-Delegation Review

> Operator playbook. This is the deep-dive that [`CLAUDE.md`](../../CLAUDE.md) §N4 and [`.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §4 point to. Execute it after **every** coding subagent returns, before any merge or submodule-pointer bump.
>
> **Core principle**: a subagent's "done" / "tests passing" summary is an input, not evidence. You re-derive correctness from the diff and from re-run commands. Never skip a gate. On failure: fix → re-run **that** gate → continue.

## Why this exists

Subagents don't inherit the main session's SessionStart hooks (brain-hot, MEMORY.md). They produce plausible summaries that omit the failure modes that actually bite this repo: broken per-service container builds, missing transitive dependency declarations, hand-copied enums that drift from the canonical contract. The 6 gates are a mechanical net that catches these classes of failure.

## When to run

| Trigger | Run the gates? |
|---|---|
| A coding subagent returned | YES — all 6 |
| A read-only `Explore` / research subagent returned | No (no code changed) |
| You hand-wrote a fix inline in the main session | YES — gates 1, 2, 3, 5 minimum (you ARE the subagent here) |
| A doc-only subagent (retro, design doc, playbook) returned | Gate 1 (inspect diff) only; skip build/test/boundary |

## The gates at a glance

| # | Gate | Primary command(s) | Backstop |
|---|---|---|---|
| 1 | **Inspect** | `git diff --stat` + `git diff <files>` | your own read |
| 2 | **Build + Test** | the project's build + test command (per touched module) | container build |
| 3 | **Boundary** | **preset-specific** — see Gate 3 below | grep gates / lint |
| 4 | **Quality (parallel)** | `pr-review-toolkit:{code-reviewer, silent-failure-hunter, type-design-analyzer}` | `+pr-test-analyzer` / `+comment-analyzer` |
| 5 | **Wiring** | composition-root grep + migrations + observability + topic + contracts | codegen parity |
| 6 | **Integration smoke** | the project's local-stack-up + smoke commands | browser e2e |

> All commands cited below should map to real targets in your meta-repo `Makefile` (or equivalent task runner). Verify the targets exist when you adopt this playbook.

---

## Gate 1 — Inspect

**What it checks**: that the diff matches the task's declared touched-files matrix, contains no stray files (`.env`, credentials, large binaries), and that you have actually read the changed lines — not the subagent's prose about them.

**Commands** (run from the touched module's own checkout, or with `-C`):

```bash
git -C <module> status -s
git -C <module> diff --stat
git -C <module> diff                       # read it; do not skim
# For an already-pushed branch, scope to the branch diff vs main:
git -C <module> diff main...HEAD --stat
```

**What failure looks like**:
- Files touched outside the declared matrix (subagent strayed).
- A secret / `.env` / vendored binary staged.
- The diff does something different from what the summary claimed.

**On failure**: revert the stray hunks (`git -C <m> restore <file>` for unstaged, `git -C <m> restore --staged <file>` to unstage), or send the subagent a `SendMessage` to correct course, then re-run Gate 1. Do **not** proceed to Gate 2 with an un-inspected diff.

---

## Gate 2 — Build + Test

**What it checks**: every touched module compiles and its tests pass — including the **container** build path, which is stricter than the workspace build.

**Commands**:

```bash
# Whole project (loops every module):
make build && make test

# Or scope to the touched module for a faster loop:
make -C <module> build && make -C <module> test

# Container build path (CRITICAL — see bug catch below):
make -C <module> docker-build
```

**Why both build paths**: a workspace / monorepo build is **lenient** — it resolves sibling modules from the workspace. The per-service container build is **strict** — only the service's build context is visible. A change can be green under workspace build and red in the container.

**What failure looks like**: compile error, test failure, or a container build that can't find a module the workspace silently provided.

**On failure**: fix the root cause, re-run `make build && make test` (and `docker-build` if the failure was container-side). Never merge on red.

### Common bug catches

- **Workspace vs container divergence**: workspace build is green, but per-service container build fails — the build context lacked sibling modules the service depends on. Fix: in-container dependency replace (e.g. `go mod edit -replace`) or vendor the dep so the standalone build resolves it.
- **Missing transitive dependencies**: container non-workspace builds are strict about indirect deps; workspace builds are lenient and hide them. Fix: re-run the dependency-management command (e.g. `go mod tidy`, `pnpm install --frozen-lockfile=false` then re-lock) to restore the indirect declarations.

---

## Gate 3 — Boundary (preset-specific)

**What it checks**: the architectural boundary chosen by the project. This is **preset-specific**:

- If you installed the **`go-hex`** preset → dispatch the `hexagonal-reviewer` agent + run a forbidden-import grep gate against the Go hex direction (`cmd → adapters → usecase → ports → domain`).
- If you installed the **`nextjs-fsd`** preset → run the FSD lint (`eslint-plugin-boundaries`) enforcing `app → widgets → features → entities → shared`.
- If you installed the **`vue-pinia`** preset → run the project's component / store boundary lint (e.g. forbid component → store cycle; forbid feature → other-feature import).
- If you installed the **`k8s-helm`** preset → run `helm lint` + a kustomize-overlay drift check.
- If your project has its own architecture → define your own Gate 3 as an A011+ rule in `.claude/rules/brain-hot.md` (or a `<slug>-local.md` rules file) and reference here.

Full rule for the active boundary: your project's N1 rule in `.claude/rules/brain-hot.md` + the preset's `BOUNDARY.md` (if shipped by the preset).

**Generic dispatch shape** (replace `<reviewer>` with the preset-provided reviewer name):

```text
Agent(
  description: "Boundary review for {{TASK_ID_PREFIX}}-S0X.YY",
  subagent_type: "<reviewer>",
  prompt: "Review the diff in <module> (branch feat/...). Enforce the project boundary
           per the N1 rule in .claude/rules/brain-hot.md. Report any forbidden import with file:line."
)
```

**What failure looks like**: the agent reports a forbidden import, or any grep / lint reports a violation.

**On failure**: move the offending dependency to the correct layer (or promote a shared primitive to the appropriate shared module). Re-run the agent + greps / lint. This gate is non-negotiable — a "temporary" boundary break is never acceptable.

---

## Gate 4 — Quality (parallel reviewers)

**What it checks**: project-convention adherence, silent failures / inadequate error handling, and type-design quality. These run in **parallel** (dispatch all in a single message — multiple `Agent` calls in one block).

**Dispatch** (single message, parallel):

```text
Agent(subagent_type: "pr-review-toolkit:code-reviewer",         prompt: "<diff + A-rules context>")
Agent(subagent_type: "pr-review-toolkit:silent-failure-hunter", prompt: "<diff>")
Agent(subagent_type: "pr-review-toolkit:type-design-analyzer",  prompt: "<diff>")
```

Add conditionally:
- `pr-review-toolkit:pr-test-analyzer` — **if tests were added/changed**.
- `pr-review-toolkit:comment-analyzer` — **if comments were touched**.

**What failure looks like**: a reviewer returns a high-confidence finding (silent error swallow, weak type that admits invalid states, a convention break).

**On failure**: triage findings by confidence. Fix high-confidence issues; for the rest, either fix or record an explicit deferral in the task's design doc / STATUS row. Re-run the specific reviewer that flagged it. A subagent's self-review does NOT substitute for this gate.

---

## Gate 5 — Wiring

**What it checks**: that the new code is actually wired in — not just authored. The classic failure is a perfectly good use-case / adapter that nothing constructs. Check each that applies:

| Wiring point | How to verify | Applies when |
|---|---|---|
| Composition root | grep `cmd/<service>/main.{ext}` for the new constructor / route registration | any new use-case, adapter, or route |
| Migrations applied | service bootstrap calls `migrations.ApplyAll(ctx)` (or equivalent) before serving; migration file is idempotent (A004) | schema / index / topic change |
| Observability emits | new request path has a span; new worker emits a heartbeat metric (A008) | any new code path / worker |
| Message topic exists | the topic the producer/consumer uses is created (compose / bootstrap) and the contract is committed | producer/consumer change |
| Contracts updated | a matching `contracts/events/*.json` (or `contracts/openapi/*.yaml`) change exists, committed FIRST (A003) | external-surface change |

**Commands**:

```bash
# Composition-root wiring — the new symbol must appear in main:
grep -rn "NewXxxUseCase\|RegisterXxxRoutes" <service>/cmd/

# Migration idempotency (A004) — every migration must be IF NOT EXISTS / ADD COLUMN IF NOT EXISTS:
grep -rn "IF NOT EXISTS\|createIndex" <service>/migrations/

# Observability heartbeat / span presence on new worker:
grep -rn "_alive\|StartSpan\|tracer" <service>/internal/

# Contract present for an external-surface change (A003):
ls contracts/events/                      # canonical event schemas live here
git -C . log --oneline -- contracts/      # confirm the contract commit landed first

# If the contract changed, regenerate + confirm cross-language types stay in sync:
make codegen
```

**What failure looks like**: new code exists but the composition root never references it; a migration is non-idempotent; a message topic isn't created; an external-surface change shipped without a contract commit.

**On failure**: wire it (composition root), make the migration idempotent, create the topic, or land the contract commit first (Gate ordering: contract commit precedes code — see [`contract-first.md`](contract-first.md)). Re-run the relevant grep / codegen.

---

## Gate 6 — Integration smoke

**What it checks**: the full stack comes up and every HTTP service answers `/healthz=200`; golden-path E2E works.

**Commands**:

```bash
make docker-up        # local stack — every service + its dependencies
make smoke            # discovers each service's published host port, curls /healthz, fails on first non-200
# Frontend touched? add:
make fe-e2e           # browser e2e (auto-starts the app)
# Tear down when done:
make docker-down
```

**What `make smoke` should do**: for each service in the project's smoke list, ask the module for its container port, discover the published host port, curl `/healthz`, fail on the first non-200. Use explicit `if/then/else` (not `&&`/`||`) so a mid-loop failure can't be masked by a later pass.

**What failure looks like**: `make smoke` prints `FAIL` for a service (exit 1), or the browser e2e fails.

**On failure**: inspect that service's logs (`docker compose logs <svc>`), fix, `make docker-down && make docker-up && make smoke`. A service that won't come up is a hard block on merge.

---

## Copy-paste checklist

```text
Post-delegation review — {{TASK_ID_PREFIX}}-S__.__  (module: __________  branch: __________)

[ ] Gate 1  Inspect    git -C <m> diff --stat && git -C <m> diff   (read every line; no stray files / secrets)
[ ] Gate 2  Build+Test make build && make test   AND   make -C <m> docker-build   (container path is strict)
[ ] Gate 3  Boundary   preset-specific reviewer agent + forbidden-import grep / lint clean
[ ] Gate 4  Quality    code-reviewer + silent-failure-hunter + type-design-analyzer  (+pr-test-analyzer / +comment-analyzer)
[ ] Gate 5  Wiring     composition-root grep · migrations idempotent (A004) · observability (A008) · topic created · contract committed first (A003) · codegen in sync
[ ] Gate 6  Smoke      make docker-up && make smoke   (+ make fe-e2e if frontend)   → make docker-down

Any RED → fix → re-run THAT gate → continue. Never skip. Never merge on red.
```

## What to NEVER do

- Trust the subagent's "tests passing" summary without re-running `make build && make test` yourself.
- Let the subagent's self-review stand in for Gate 4.
- Skip the container build (`docker-build`) — the workspace build hides the bugs Gate 2 exists to catch.
- Skip Gate 3 because "the change looks small" — a one-line import is exactly how architecture erodes.
- Merge before the contract commit lands when an external surface changed (A003 / Gate 5).

## Related

- [`../../CLAUDE.md`](../../CLAUDE.md) §N3 — the 6-gate skeleton this expands.
- [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §4 (gates), §5 (never-do).
- [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) — A002 (zero-bug), A003 (verify), A004 (6-gate), N1 (boundary), L116 (wiring) referenced by the gates.
- [`parallel-conflict-prevention.md`](parallel-conflict-prevention.md) — when the work was dispatched as parallel subagents.
- [`contract-first.md`](contract-first.md) — the N2 contract-first detail Gate 5 checks.
