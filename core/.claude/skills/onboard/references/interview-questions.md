# Interview Questions — Stage 2 question bank

> The full bank for `/onboard` Stage 2. The skill SKILL.md lists the
> questions in brief; this file adds the rationale, the "good vs
> vague" answer shape, and how each answer flows downstream.
>
> Each round is a single `AskUserQuestion` invocation (≤ 4 questions
> per call — harness constraint). Never use free-form prose questions
> here; the structured form is what makes downstream parsing reliable.

## Format guide

For every question:

- **Question** — the exact text the wizard surfaces.
- **Good answer** — 1-line example of a useful response.
- **Vague answer** — 1-line example that needs a follow-up.
- **Downstream use** — which stage consumes the answer, how.
- **Default if skipped** — what the wizard fills in if the operator
  hits enter without typing.

## Round 1 — System soul (always run)

The first round establishes what the project IS so every later draft
has a shared frame.

### Q1. What does this system DO? (1 sentence)

- **Good:** *"Inventory-sync service that consumes warehouse webhooks
  and reconciles them into our PG canonical store."*
- **Vague:** *"It's the inventory thing."* → follow up: who calls it,
  who reads its output.
- **Downstream:** Stage 4 — fills the "What this repo is" paragraph of
  root `CLAUDE.md`. Stage 7 — quoted in the handoff summary.
- **Default if skipped:** `_TODO operator: 1-sentence purpose_` left in
  the draft as a flagged gap.

### Q2. Who consumes it?

- **Good:** *"Two internal teams (Operations, Finance), plus one
  external partner SDK."*
- **Vague:** *"Everyone."* → follow up: distinguish first-party vs
  third-party consumers.
- **Downstream:** Stage 4 — informs the "Consumers" line in
  `codebase-orientation.md`. Stage 6 — hints at backlog priority
  (external-facing changes typically need a wider review surface).
- **Default if skipped:** `_TODO operator: list consumers_`.

### Q3. What's uniquely fragile / hard to change?

- **Good:** *"The legacy pricing module — undocumented invariants, no
  test coverage, one engineer left who knows it."*
- **Vague:** *"The whole thing is brittle."* → follow up: name ONE
  area, ONE reason.
- **Downstream:** Stage 4 — seeds one or more A-rule candidates around
  the fragile area ("Always run the pricing-regression suite when
  touching `pricing/`"). Stage 7 — surfaces in handoff as "areas to
  approach cautiously".
- **Default if skipped:** no auto-rule; Stage 3 mining still proposes
  hotspot candidates, but they won't be flagged "fragile by operator
  consensus".

### Q4. Where's the design source-of-truth?

- **Good:** *"`docs/adr/` for architecture decisions, Confluence
  https://… for product specs, GitHub Issues for tasks."*
- **Vague:** *"In our heads."* → that IS a valid answer — fill in
  `none yet` and flag for the first sprint to fix.
- **Downstream:** Stage 4 — drops a pointer in root `CLAUDE.md`'s
  "What this repo is" paragraph. Stage 6 — informs the design-doc
  location convention for `docs/designs/`.
- **Default if skipped:** `docs/designs/` (the template's own
  convention).

## Round 2 — Conventions (always run)

Round 2 captures conventions that map directly to N-rules in root
`CLAUDE.md` + the team-conventions doc.

### Q5. Branch naming convention?

- **Good:** *"`<type>/<ticket-id>-<slug>`, e.g.
  `feat/INV-432-warehouse-webhook`. `<type>` ∈ feat/fix/refactor/chore."*
- **Vague:** *"We use feature branches."* → follow up: example, please.
- **Downstream:** Stage 4 — fills the `<type>/<task-id>-<slug>` slot in
  the dispatch-routing notes + the `Type:` row of the phase matrix.
  Stage 6 — pre-fills `STATUS.md`'s "Branch convention" field.
- **Default if skipped:** `<type>/<task-id>-<slug>` (the template's
  default from `git-workflow.md`).

### Q6. Commit message convention?

- **Good:** *"Conventional Commits — `<type>(<scope>): <subject>`, ≤ 72
  chars, body in imperative."*
- **Vague:** *"Whatever Git wants."* → still a valid answer; flag for
  `git-workflow.md` rules to apply unchanged.
- **Downstream:** Stage 4 — fills the commit-message section of root
  `CLAUDE.md` and any per-area `CLAUDE.md`. Stage 3 mining tolerates
  any style but performs best when convention is consistent.
- **Default if skipped:** Conventional Commits (the template's
  default per `git-workflow.md` Rule 4).

### Q7. Test policy (TDD-strict / test-after / case-by-case)?

- **Good:** *"TDD-strict for `usecase/` + `domain/`; test-after
  acceptable for adapters."*
- **Vague:** *"We test."* → follow up: write-first or write-after for
  the primary code?
- **Downstream:** Stage 4 — sets N5 ("Test-first discipline") to
  full / soft / project-default. Stage 5 — influences whether the
  A001 reinforcement A-rule lands. Phase matrix loaded by every
  engineer subagent.
- **Default if skipped:** TDD-strict (A001 default).

### Q8. Deploy workflow (CI provider + flow)?

- **Good:** *"GitHub Actions; main → ECR push + Argo CD sync;
  `release` tag triggers a separate prod deploy."*
- **Vague:** *"CI/CD."* → follow up: provider + trigger + target.
- **Downstream:** Stage 4 — fills the `Quick start` block of root
  `CLAUDE.md` with the actual commands. Stage 6 — informs the
  deployment-workflow doc references. If CI provider is non-standard,
  flagged for the operator to add a per-area `CLAUDE.md` note.
- **Default if skipped:** `_TODO operator: describe your deployment
  workflow here_`.

## Round 3 — First-sprint state (always run, only 3 questions)

Three questions, not four — Round 3 is intentionally shorter to keep
the wizard moving. Sprint mechanics are answered, not researched.

### Q9. Currently in a sprint? (yes/no + sprint name)

- **Good:** *"Yes — S07, started Monday."*
- **Vague:** *"Kind of."* → follow up: is there a sprint file
  somewhere or not?
- **Downstream:** Stage 6 — pre-fills `STATUS.md`'s active-sprint
  field. If "no", the wizard seeds `S00 — Onboarding` as a starter
  sprint so the first task can run.
- **Default if skipped:** `S00 — Onboarding`.

### Q10. Top 3 known carry-overs / tech debt?

- **Good:** *"(1) Pricing module test coverage. (2) Replace homemade
  retry lib with stdlib. (3) Migrate logging from log/slog to OTEL."*
- **Vague:** *"Lots of debt."* → follow up: name 3 specific items.
- **Downstream:** Stage 6 — seeds `FOLLOWUPS.md` with three F-rows.
  Stage 7 — handoff suggests starting with one of these in the first
  sprint.
- **Default if skipped:** `FOLLOWUPS.md` created empty; operator can
  fill in over the first sprint.

### Q11. One small task to pilot the workflow with?

- **Good:** *"Add a `/healthz` endpoint to the API gateway — small,
  visible, no domain risk."*
- **Vague:** *"Anything."* → follow up: surface ONE — small + visible
  + low-risk.
- **Downstream:** Stage 7 — quoted in the handoff as the recommended
  first `/work`. Stage 8 (retro) — anchors the retrospective in
  a concrete first-sprint experience.
- **Default if skipped:** wizard suggests "Add a small healthcheck or
  doc edit to validate the workflow round-trip" as a generic pilot.

## Optional Round 4 — Compliance / governance

Fires ONLY if the operator opts in at the Round 3 close-out
("Anything else to capture? (compliance / governance / regulated
industry)"). Skip otherwise — most projects don't need it.

### Q12. Auth / RBAC strictness?

- **Good:** *"OIDC via Keycloak; RBAC enforced in every handler; PR
  must include a CODEOWNERS reviewer if `auth/` is touched."*
- **Downstream:** Stage 4 — adds N6 ("Separation of Duties") content
  + cites `docs/setup/separation-of-duties.md`.

### Q13. Regulated industry flags?

- **Good:** *"SOC2 Type 2 + HIPAA. Audit retention 36 months. PHI
  fields tagged in schema."*
- **Downstream:** Stage 4 — adjusts `audit-trail.md` retention recs +
  `compliance-mapping.md` references. Stage 6 — pre-fills retention
  field in `STATUS.md` if present.

### Q14. Secrets / KMS provider?

- **Good:** *"AWS Secrets Manager; rotation 90d; no secrets in
  `.env`."*
- **Downstream:** Stage 4 — adds a project-specific secret-handling
  note pointing at `docs/setup/secret-handling.md`.

## Failure modes

- **Operator types essays for every question.** Stage 4 truncates each
  field to ~3 sentences; the rest goes into a `interview-notes.md`
  sidecar the operator can mine later.
- **Operator skips everything.** Wizard proceeds with all defaults +
  flags every default as `_TODO operator_` in the drafts. Stage 5
  ratification surfaces the TODO list alongside A-rule candidates.
- **Operator contradicts themselves across rounds** (e.g. Q7 says
  TDD-strict but Q11 names a typo-fix as the pilot). Stage 4 surfaces
  the tension in its confidence-notes section so the operator
  resolves at Stage 5.

## See also

- `core/.claude/skills/onboard/SKILL.md` — Stage 2 invocation
- `references/draft-templates.md` — how Stage 4 maps these answers
  into prose
- `core/CLAUDE.md.tmpl` — the destination template these answers fill
- `core/.claude/rules/phase-matrix.md` — Q7's downstream
