# Playbook — 6-Gate Post-Delegation Review

> Operator playbook. This is the deep-dive that [`CLAUDE.md`](../../CLAUDE.md) §N3 and [`.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §4 point to. Execute it after **every** coding subagent returns, before any merge or submodule-pointer bump.
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
| 4a | **Spec-compliance** | read code vs the D-doc AC list — every AC built, nothing extra | the verification JSON's `files_will_touch` |
| 4b | **Quality (parallel)** | `pr-review-toolkit:{code-reviewer, silent-failure-hunter, type-design-analyzer}` | `+pr-test-analyzer` / `+comment-analyzer` |
| 5 | **Wiring** | composition-root grep + migrations + observability + topic + contracts | codegen parity |
| 6 | **Integration smoke** | the project's local-stack-up + smoke commands | browser e2e |

> Still "6 gates" — Gate 4 is a two-stage gate (4a spec-compliance THEN
> 4b quality), mirroring the spec-then-quality review order. 4a must pass
> before 4b: there's no point judging *how well* code is built before
> confirming it builds *the right thing*.
>
> All commands cited below should map to real targets in your meta-repo `Makefile` (or equivalent task runner). Verify the targets exist when you adopt this playbook.

## Rationalizations for skipping a gate

The gates feel like overhead under deadline pressure. These are the
excuses — each is the exact moment a class of bug slips through. Full
catalogue of discipline excuses: [`../setup/discipline-red-flags.md`](../setup/discipline-red-flags.md).

| Excuse | Reality |
|---|---|
| "The subagent said tests pass" | Re-run them yourself (Gate 2). A "done" summary is an input, not evidence. |
| "It's a tiny change, skip the gates" | Tiny changes ship the wiring bugs (Gate 5) and silent failures (Gate 4b) most often. |
| "I read the summary, the diff looks fine" | Read the *diff* (Gate 1), not the prose about it. |
| "Spec-compliance and quality are one pass" | They're not: 4a = *did it build the AC, nothing extra*; 4b = *is it well-built*. 4a gates 4b. |
| "Smoke test takes too long" | Gate 6 is where "green tests, broken feature" is caught before prod. |

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

## Gate 3 — Boundary (the project's own)

**What it checks**: that the change respects **the project's own** module
boundaries — the ones captured in `.claude/rules/code-style.md` (generated by
`/onboard`) + the N1 rule in root `CLAUDE.md`, not a prescribed architecture.

- **Default** → dispatch `senior-tech-lead`: it reads `code-style.md` + the
  area `CLAUDE.md` and checks the diff against the documented boundaries
  (e.g. "data access only in `<path>`", "domain imports no framework"). Back
  it with a forbidden-import grep when the boundary is mechanically checkable.
- If you installed the **`k8s-helm`** preset → also run `helm lint` + a
  kustomize-overlay drift check.
- If you authored a **custom preset** with its own boundary rule + reviewer
  → dispatch that reviewer (see `docs/adding-new-preset.md`).

Full rule for the active boundary: `.claude/rules/code-style.md` + the N1 rule
in root `CLAUDE.md` (+ a custom preset's boundary rule if installed).

**Generic dispatch shape** (`<reviewer>` = `senior-tech-lead`, or a custom preset's reviewer):

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

## Gate 4a — Spec-compliance (runs BEFORE 4b)

**What it checks**: that the code implements **every acceptance criterion in the design doc — and nothing more**. This is the spec-then-quality discipline: confirm the *right thing* was built before judging *how well* it was built.

**How to run** (the orchestrator does this directly, or dispatches a `senior-tech-lead` / `general-purpose` reviewer with a `<TASK_ID>-review` brief):

1. Open the task's D-doc; list its AC and its touched-files matrix.
2. **Read the actual code** (not the subagent's summary) and check, AC by AC:
   - **Missing**: is every AC implemented? Anything claimed-but-not-actually-built?
   - **Extra / over-built**: anything implemented that no AC asked for (a "nice to have", an unrequested flag, speculative generality)? YAGNI — flag it.
   - **Misread**: did it solve a slightly different problem than the AC stated?
3. Cross-check the diff's files against the verification JSON's `files_will_touch` (the agent declared these before coding).

**Core principle**: *do not trust the report — verify by reading code.* A subagent that finished suspiciously fast may have an optimistic summary.

**What failure looks like**: an AC with no corresponding code/test; a feature the AC never requested; the right feature built the wrong way.

**On failure**: send the implementer (same subagent, via `SendMessage`) the specific gap — "AC3 not implemented" / "remove the unrequested `--json` flag" — and re-run 4a. Do **not** proceed to 4b with an unmet or over-built spec.

---

## Gate 4b — Quality (parallel reviewers)

**What it checks**: project-convention adherence, silent failures / inadequate error handling, and type-design quality. These run in **parallel** (dispatch all in a single message — multiple `Agent` calls in one block). **Only after Gate 4a passes.**

**Dispatch** (single message, parallel):

```text
Agent(subagent_type: "pr-review-toolkit:code-reviewer",         prompt: "<diff + A-rules context>")
Agent(subagent_type: "pr-review-toolkit:silent-failure-hunter", prompt: "<diff>")
Agent(subagent_type: "pr-review-toolkit:type-design-analyzer",  prompt: "<diff>")
```

Add conditionally:
- `pr-review-toolkit:pr-test-analyzer` — **if tests were added/changed**.
- `pr-review-toolkit:comment-analyzer` — **if comments were touched**.

**Test-theater check (when tests were added/changed).** A passing test
suite is an input, not evidence the tests are real. The reviewer (and your
own read of the test diff) must reject **test theater** — tests that pass
without constraining behavior:

- **Asserting the mock** (`expect(mock).toHaveBeenCalled()` with no real
  outcome checked) — proves nothing about the code.
- **Tautology** — asserting a value the code just returned, or
  `expect(f(x)).toBe(f(x))`.
- **No red phase** — for a `fix`, the regression test MUST fail on the
  pre-fix code (verify: check out pre-fix, run it, see red). For a `feat`,
  the test should have been red before the implementation existed.
- **Behavior-as-intent on legacy** — pinning current (unverified) output as
  if it were a spec. Acceptable ONLY when explicitly labeled a
  **characterization** test (locks behavior as a refactor safety net, not
  correctness — see [`../setup/test-discipline.md`](../setup/test-discipline.md)
  / the TDD playbook (`docs/playbooks/tdd.md`)).
- **Happy-path only** — no error / empty / boundary case for branches the
  code actually has.

**What failure looks like**: a reviewer returns a high-confidence finding (silent error swallow, weak type that admits invalid states, a convention break, a test-theater pattern above).

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
[ ] Gate 4  Quality    code-reviewer + silent-failure-hunter + type-design-analyzer  (+pr-test-analyzer → reject test theater / +comment-analyzer)
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
