---
name: post-delegation-gate
description: "Run the 6-gate post-delegation review on a coding subagent's output. Use after any agent dispatch that touched code, BEFORE declaring work 'done' or merging. Enforces the non-negotiable review chain: inspect diff → build+test → architectural-boundary check → quality (parallel reviewers) → wiring check → integration smoke. Use when the user says '/post-delegation-gate', 'review the agent's work', 'run the gates'."
user_invocable: true
---

# /post-delegation-gate — 6-Gate Review (Mandatory)

Run after every coding subagent returns. **Skipping a gate is not permitted.** Canonical reference: `docs/playbooks/post-delegation-review.md`.

## Token budget (MANDATORY)

- `git diff --stat` first, then targeted `git diff <files>` — never `git diff` the entire commit.
- Reviewer subagents (Gate 4) get the diff + spec, not the whole repo.
- Smoke test (Gate 6) output is captured verbatim (no summarization), but only the failing tail is re-Read.

## Gate 1 — Inspect (manual)

```bash
git diff --stat HEAD~1..HEAD
git diff HEAD~1..HEAD <changed-files>
```

- Read the actual diff. Do not trust the agent's summary.
- If the diff includes files you did not authorize, **STOP and report.**
- If the diff touches more lines than the task description implied, ask why.

**Pass:** every changed file is justified by the task spec.
**Fail** → fix → re-run Gate 1.

## Gate 2 — Build + Test

In the touched component(s):

```bash
<your build command>     # e.g. make build, npm run build, go build ./...
<your test command>      # e.g. make test, npm test, go test ./... -race -count=1
```

For multi-package repos: run the umbrella target.

**Pass:** both exit 0; tests are deterministic (no flake, no cache hit hiding a failure).
**Fail** → dispatch fix to the original implementer with the failure output → re-run Gate 2.

## Gate 3 — Architectural-boundary check

```
Agent(
  subagent_type: "<your boundary reviewer>",   # e.g. hexagonal-reviewer from the go-hex preset
  prompt: "Review architectural boundary on this diff: <BASE_SHA>..<HEAD_SHA> in <component>. Required reads: .claude/rules/<your-boundary-rule>.md."
)
```

**Pass:** reviewer reports COMPLIANT.
**Fail** → fix loop (back to implementer) → re-run Gate 3.

## Gate 4 — Quality (parallel, single message)

Dispatch in a SINGLE message:

```
Agent(subagent_type: "pr-review-toolkit:code-reviewer", prompt: "...")
Agent(subagent_type: "pr-review-toolkit:silent-failure-hunter", prompt: "...")
Agent(subagent_type: "pr-review-toolkit:type-design-analyzer", prompt: "...")
# If tests touched:
Agent(subagent_type: "pr-review-toolkit:pr-test-analyzer", prompt: "...")
# If comments touched:
Agent(subagent_type: "pr-review-toolkit:comment-analyzer", prompt: "...")
```

**Pass:** every reviewer returns no critical or important issues.
**Fail (any reviewer)** → fix loop → re-run only the reviewer that flagged.

## Gate 5 — Wiring check (composition root + migrations + observability + contracts)

Quick mechanical checks against the diff:

- **Composition root** — `grep` for the new component/use-case/handler being wired into the entry point (`main.go`, `index.ts`, `app.py`, etc.).
- **Migrations applied** — if persistence schema changed: confirm bootstrap runs them (e.g. `docker-compose up` log says migrations applied).
- **Observability emit** — `grep` for the project's tracing / metric APIs in the new code paths.
- **Contracts updated** — if event / API shape touched: `git log -1 contracts/...` shows a prior commit (contract-first discipline).

**Pass:** all applicable checks pass.
**Fail** → fix → re-run Gate 5.

## Gate 6 — Integration smoke

```bash
<your stack-up command>     # e.g. make docker-up
<your smoke command>        # e.g. make smoke
```

If frontend touched:

```bash
cd <frontend-dir>
<your e2e command>          # e.g. npm run test:e2e
```

**Pass:** all health checks green + golden-path E2E passes.
**Fail** → root-cause via `superpowers:systematic-debugging` → fix → re-run Gate 6.

## Final acceptance

```
=== Post-delegation review ===
Task: {{TASK_ID_PREFIX}}-S<N>.<NN> — <slug>
Subagent: <type>
Diff: <files changed count>

Gate 1 — Inspect:                  ✅
Gate 2 — Build + Test:             ✅
Gate 3 — Architectural boundary:   ✅
Gate 4 — Quality:                  ✅ (3-5 reviewers)
Gate 5 — Wiring:                   ✅
Gate 6 — Integration:              ✅

READY TO MERGE.
```

## What to do if you're tempted to skip

The gates exist because past evidence said they had to. Silent failures, boundary violations that break down at sprint 8 close, migration gaps that surface in UAT weeks later — every one of these started with "let's skip the gate just this once."

If a gate is "too slow" — the implementer subagent has too-large scope. Split the task; don't skip the gate.

## Related

- `docs/playbooks/post-delegation-review.md` — the canonical gate definition
- `.claude/rules/<your-boundary-rule>.md` — what Gate 3 checks
- `.claude/rules/<your-project-rules>.md` — what Gate 4 indirectly checks via the reviewers
- `/design-review` — additional gate for FE work (UI fidelity, runs after Gate 6 for frontend sprints)
