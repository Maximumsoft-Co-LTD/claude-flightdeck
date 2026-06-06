# Phase Matrix — type × phase decision table (auto-loaded)

> When `/work` (or any orchestrator) picks up a task, the type of
> work changes which phases run, run lightly, or skip. This file is
> the mechanical lookup. Adapted from battle-tested multi-project
> workflow conventions.
>
> **Read this BEFORE writing a design doc** so you don't drag a typo
> fix through a 500-line zero-fix template, and don't ship a feature
> without the quality gates that apply.

## Phase ↔ Stage mapping

The 12 phases below specialize the 7 stages from
[`docs/setup/workflow-master.md`](../../docs/setup/workflow-master.md).
This table is the cross-reference; phase numbering is the canonical
mechanical lookup, stage names are the human shorthand.

| Phase | Stage (workflow-master) |
|-------|--------------------------|
| 1. Discovery / interview | **S1 Discovery** |
| 2. Design doc | **S3 Design** |
| 3. Gate / approval | **S3 Design** (closeout) → entry to S4 |
| 4. Test first (TDD) | **S4 Implement** |
| 5. Implement | **S4 Implement** |
| 6. Code review | **S5 Review** (gates 1, 3, 4) |
| 7. Security review | **S5 Review** (trigger gate) |
| 8. Integration smoke | **S5 Review** (gate 6) |
| 9. Design-fidelity review | **S5 Review** (UI trigger gate) |
| 10. Docs touch-up | **S5 Review** closeout |
| 11. Ship (commit + PR) | **S5 Review** closeout |
| 12. Live mini-retro | **S6 Per-task retro** |

S2 Sprint planning and S7 Sprint close are sprint-level (not per-task)
and so don't appear in the phase matrix; see workflow-master for those.

## The matrix

Rows are **work types** (declared in the sprint file row + design-doc
frontmatter). Columns are the **phases** that come from the workflow
pipeline (`docs/setup/workflow-master.md`). Cell legend:

- ✓ — runs fully
- ⚠ — runs *light* (thinner pass, e.g. inline checklist instead of full template)
- skip — does not run; the orchestrator records `skipped — type=<x>`
- trig — runs only if a trigger fires (see Triggers section below)

| Phase | feat | fix | refactor | chore | docs | spike | release |
|-------|------|-----|----------|-------|------|-------|---------|
| 1. Discovery / interview | ✓ | ✓ | ✓ | ⚠ | ⚠ | ✓ (timeboxed) | ⚠ |
| 2. Design doc (≥500-line zero-fix) | ✓ | ⚠ (light template) | ⚠ (behavior-equiv note) | skip | skip | ⚠ (exploration plan) | ⚠ (release notes) |
| 3. Gate / approval | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4. Test first (TDD — A001) | ✓ | ✓ (regression FIRST) | ✓ (behavior-equiv check) | skip | skip | skip | skip |
| 5. Implement | ✓ | ✓ | ✓ | ✓ | ✓ (file edits) | ✓ (exploration) | ✓ (version bump) |
| 6. Code review (gates 1, 3, 4 of `/review gates`) | ✓ | ✓ | ✓ | ✓ | ⚠ | ⚠ light | ⚠ |
| 7. Security review | trig | trig | trig | trig | skip | skip | trig |
| 8. Integration smoke | ✓ | ✓ | ✓ | ⚠ | skip | skip | ✓ |
| 9. Design-fidelity review (UI only) | trig | trig | trig | skip | skip | skip | trig |
| 10. Docs touch-up | ✓ | ⚠ | ⚠ | ⚠ | ✓ | skip | ✓ |
| 11. Ship (commit + PR) | ✓ | ✓ | ✓ | ✓ | ✓ | optional | ✓ |
| 12. Live mini-retro (A009 / L036) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**Chore exception:** dep bumps that change defaults / errors /
signatures must re-tag as `feat` or `fix` (per A002 zero-bug).
Genuinely behaviorless chores still pass through Gate 1 Inspect + Gate
4 silent-failure-hunter.

**Optional row.** Projects with continuous deployment from `main` can
omit the `release` type — treat version bumps as `chore`. The row is
shipped for explicit-release projects (versioned libraries, mobile
apps, SDK packages, anything with formal release notes).

## Type definitions

- **feat** — new user-visible behaviour. Adds an endpoint, page,
  message-handler, schema field, or capability. Default zero-fix
  template applies.
- **fix** — restoring intended behaviour. **No fix without root-cause
  first** — invoke `superpowers:systematic-debugging` (reproduce →
  isolate → hypothesis → root cause) BEFORE proposing a change; a
  symptom patch that doesn't name the root cause is a failure. Step 1 of
  implementation MUST be a failing regression test; the test commits
  separately so the gate can verify "fail on pre-fix, pass on fix".
  **3-strikes escalation:** if 3 fix attempts on the same bug fail,
  STOP — do not try fix #4. The pattern signals a structural problem;
  raise it to the user / `senior-tech-lead` and question the
  architecture, not the symptom.
- **refactor** — change shape, keep behaviour. Design doc must
  include a behaviour-equivalence note; the test phase verifies the
  existing suite still passes (no new behavior tests added).
- **chore** — formatter run, dep bump that's confirmed non-behavior-
  changing, lockfile refresh, comment cleanup. If the bump changes
  defaults / errors / signatures, **re-tag as `feat` or `fix`** —
  chore is for genuinely behaviorless work only.
- **docs** — README, comments, design doc edits, runbook updates. No
  code-path changes.
- **spike** — timeboxed exploration. Produces an `exploration plan` in
  step 2 plus a `findings.md`. **No production code lands** unless
  the user explicitly re-promotes the work to a `feat`.
- **release** — version bump, changelog, tag, deploy. No new logic.

## Triggers (Phase 7 — Security review)

Phase 7 runs when the diff touches any of:

- auth, session, token, JWT, OAuth, SAML
- password / credential handling
- crypto primitives (encryption, signing, KDF)
- SQL / query building (raw or generated)
- HTML rendering of untrusted input
- file path handling / archive extraction
- shell-command construction or sub-process spawning with
  string-concatenated arguments
- deserialisation of untrusted input (binary object formats, YAML
  with tags, JSON with type metadata)
- secret-bearing files (`.env`, config, sealed-secrets)
- new external network endpoints
- SSRF — server-side fetch where URL / host / port is user-controlled
- XXE / XML external-entity parsing (any XML parser with external
  entity resolution enabled)
- prototype pollution / `Object.assign` / merge from untrusted JSON
- CORS / CSP / cookie attributes (SameSite, Secure, HttpOnly)
- regex compiled from user input (ReDoS — catastrophic backtracking)
- **agent config that is committed + executable** — any diff to
  `.claude/settings*.json`, `.mcp.json`, or `.claude/hooks/*`, or a diff
  introducing `ANTHROPIC_BASE_URL` / any `*_BASE_URL` model-API redirect /
  `enableAllProjectMcpServers`. Committed agent config runs on every
  teammate's machine (CVE-2025-59536 class) — review it like CI config. Full
  trust model + reviewer checklist:
  [`../../docs/setup/agent-config-security.md`](../../docs/setup/agent-config-security.md).
- **a new dependency added to a manifest** (`package.json`, `go.mod`,
  `requirements.txt`, `Cargo.toml`, `pyproject.toml`, `Gemfile`, …) — verify it
  **actually exists** and is the **intended** package, not a hallucinated /
  squatted name (~19.7% of LLM-suggested packages don't exist → slopsquatting is
  install-time RCE). A package you can't confirm exists is a STOP.

**Invoke [`/review security`](../skills/review/SKILL.md)** to run Phase 7
— a diff-aware, semantic pass across the dimensions above with false-positive
filtering so it stays signal not noise (it dispatches
`pr-review-toolkit:silent-failure-hunter` + a security-focused `senior-tech-lead`
for the deep dimensions). The orchestrator decides which triggers fired.

## Triggers (Phase 9 — Design-fidelity review)

Phase 9 runs when the diff touches:

- any UI component / page / layout file (frontend preset paths)
- design tokens / theme files / CSS variables
- i18n message catalogs (visible string changes)
- responsive breakpoints / media queries
- animations / transitions / motion (`@keyframes`, transition props,
  Framer / GSAP, scroll-driven animations)
- focus / hover / active states and accessibility-visible styling
  (focus rings, aria-visible style hooks)

Dispatch `/review design` for the 3-lens visual gate. Skip otherwise.

## How to apply

1. **At task pickup** (`/work` step 2): read the task
   row's `Type:` slot. If missing, ask the user. Default = `feat`.
2. **Pick the matrix row.** That row tells you the phase list for the
   rest of the work.
3. **Quote the row in your task report.** Example:
   > Type=fix → phases 1, 2⚠, 3, 4 (regression first), 5, 6, 7 trig,
   > 8, 9 trig, 10⚠, 11, 12.
4. **Don't skip phases that are ✓** even if "this one's easy." Skipping
   a ✓ phase is the most common cause of slipped quality.
5. **Don't run phases that are skip** — that's bloat (chore /
   refactor / spike commonly get over-templated by accident).
6. **When in doubt, pick the larger type.** A docs change that ALSO
   touches a code path is a `feat` or `fix`, not a `docs`.

## Tie-ins

- **A001 (TDD)** — phase 4 is the test-first phase. Matrix says ✓ on
  feat/fix/refactor; skip on chore/docs/spike/release. **On untested
  legacy code** (`refactor` / `fix` where no tests cover the change site),
  the "test first" phase = a **characterization test** that pins current
  behavior *before* you change it — not a from-scratch new-behavior spec.
  This keeps the discipline legacy-safe (one test around the change site,
  never a blocked commit). Follow the TDD playbook (`docs/playbooks/tdd.md`) (it picks the mode);
  recipe + the test-theater anti-patterns the gate rejects:
  [`../../docs/setup/test-discipline.md`](../../docs/setup/test-discipline.md).
- **A005 (design-doc-first)** — phase 2. Matrix shows feat = ✓
  (full template), fix/refactor/spike = ⚠ (light), chore/docs = skip.
- **A004 (6-gate review)** — phases 6 + 7 trig + 8 + 9 trig + 10 are
  the gates. The matrix is the *which gates fire* lookup; the playbook
  at `docs/playbooks/post-delegation-review.md` is the *how* of each
  gate. For a **large / multi-file diff**, the Gate-4b quality + Phase-7
  security dimensions can be fanned out + adversarially verified via
  `/review ultra` (Workflow-backed) — it *augments, never replaces*, the
  gate (returns findings, not a merge verdict).
- **A009 (live mini-retro)** — phase 12 is universal. Every type runs
  it. No exceptions.

## See also

- `docs/setup/workflow-master.md` — the end-to-end pipeline this
  matrix specializes per-type
- `docs/playbooks/post-delegation-review.md` — the 6-gate playbook
  (gates 1-6 land in phases 6 + 8)
- `core/.claude/skills/work/SKILL.md` — `/work` looks up this matrix in
  Step 2 of task pickup
- `core/.claude/agents/orchestrator.md` — routing table cross-refs
  this matrix
