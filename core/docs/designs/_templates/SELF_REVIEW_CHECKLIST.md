# Design-Doc Self-Review Checklist

Run this **before** marking the design doc `Status: draft` and handing
it to the gate. Catches the failure modes that otherwise surface at
review time and burn a cycle.

A design doc that passes self-review is not "perfect" — it's
"internally consistent and free of the known antipatterns." Real
surprises will still surface during implementation; this checklist
filters out the ones already known how to spot.

## The five scans

Walk in order. Each takes ~30 seconds for an XS/S doc, ~2 minutes
for L.

### Scan 1 — Anti-placeholder (maps to DESIGN_TEMPLATE §2 + §7 — Steps + File Structure)

Search the entire doc for these strings. Every hit is a fix-before-
draft:

| Pattern | Why it's bad |
|---------|--------------|
| `TBD`, `TODO`, `???` | A placeholder is a hole. Either fill it or move to `Out of scope` / `Open questions`. |
| `appropriate error handling`, `proper validation`, `as needed`, `where appropriate` | Vague — no implementer can ship "appropriate". State the actual behaviour. |
| `see spec`, `as discussed`, `per the design` | Forces the reader to dereference. The doc should be self-contained for the slice it owns. |
| `etc.`, `and so on`, `among others` | Hides scope. List it or scope it out. |
| `path/to/file`, `foo/bar`, `<file>` | Template residue. Replace with a real `path:line` or delete the bullet. |
| `e.g.`, `for example` *in Steps* | Steps are imperative actions, not illustrations. Move examples to `Approach`. |
| `should`, `would`, `might` *in Steps* | Steps are commitments, not hedges. "Add `getUserById` at `src/users.ts:42`", not "should probably add a lookup". |
| `consider X`, `think about Y` *in Steps* | Steps are decisions already made. If it still needs deciding, move to `Open questions`. |

If a pattern appears in `Approach`, that's usually OK — `Approach`
carries the *why* and may use hedging. The hard rule: **`Steps` and
`Files touched` must be placeholder-free.**

### Scan 2 — Acceptance-criteria coverage (maps to DESIGN_TEMPLATE §7 Implementation Tasks ↔ §9 Acceptance Criteria)

Open the spec's `Acceptance criteria` block. For each `[ACn]`:

1. Search the doc for the AC's number (`[AC1]`, `[AC2]`, …).
2. Confirm at least one `Step` carries that tag.
3. Read that Step. Does executing it actually deliver the AC? If the
   connection is hand-wavy, the Step is too abstract — split it.

If an AC has no step:

- The doc is incomplete → add the steps.
- OR the AC is out of scope for this run → state it in `Out of
  scope` and confirm with the user.

If a Step has no AC tag:

- The step doesn't earn its place → delete it, OR it's scope-creep
  → move to the backlog's Follow-ups section (`docs/project/backlog.md` `## Follow-ups`).
- OR the spec is missing an AC the work actually delivers → go back
  and add the AC to the spec first, then re-tag.
- OR the step is **infrastructure** (a `[infra]`-tagged step that
  wires migrations, config, observability hooks, route registration,
  composition-root assembly) — these are exempt from AC bijection,
  but must live in a clearly labelled `Setup steps` subsection of
  §7 with a `verify:` clause each. Implementation steps below them
  still need AC tags.

There is no fourth option. Every implementation step ↔ at least one
AC; every AC ↔ at least one implementation step; every infra step
↔ a verify clause.

### Scan 3 — Diagram ↔ Files alignment (maps to DESIGN_TEMPLATE §2 High-Level Flow ↔ §2 File Structure)

Walk the `Architecture diagram`:

- Every node marked `★` (new piece) → must appear in `Files touched`
  as a `new` row.
- Every node marked `~~strikethrough~~` (removal) → must appear in
  `Files touched` as a `delete` row.
- Every `new` row in `Files touched` → must appear as a `★` node in
  the diagram.
- Every `delete` row → must appear with strikethrough.

`edit` rows (existing files modified) don't have to be in the
diagram unless the edit is a structural change — but if a file is
edited in a way the diagram should show (new exported function, new
dependency arrow), surface it with a labeled edge or annotation.

XS docs where Diagram = `Impact: N/A` skip this scan.

**S-tier diagrams**: Scan 3 fires only when the diagram contains `★`
(new) or `~~strikethrough~~` (removal) markers. A flow-only mini-mermaid
(no ★/strikethrough) is exempt — verify edges are correct but don't
enforce bijection.

### Scan 4 — Current-state coverage (maps to DESIGN_TEMPLATE §2 Data Flow & Side-Effects + §2 File Structure)

Skip on XS/S `feat` in isolated new files, on `chore`/`docs` not
touching live code, and on `spike`. Otherwise walk it.

**Step 0 — LSP evidence check.** Confirm the design doc cites at least
one LSP-derived fact (`hover`, `documentSymbol`, or `findReferences`
output) per edited file. If none → re-walk with LSP before continuing
this scan. Walk-by-text is the failure mode this scan exists to catch.

Open `Current state` and `Files touched` side by side. For each row:

- **`new`** — no current-state coverage required (the file doesn't
  exist yet).
- **`edit`** — the file must appear in either:
  - the `Data / control flow` bullets (i.e. this file is in the
    flow we walked), OR
  - the `Invariants` list (i.e. the edit preserves or breaks a
    named invariant on this file).

  If the edit isn't in either, ask: do we actually understand what
  the current file does at the line we're editing? If yes, add the
  bullet / invariant. If no, walk it with LSP now — that's the gap
  this scan exists to catch.
- **`delete`** — must appear in the caller-walk (we know nothing
  else points at it) AND in the as-is flow (we know what it
  currently does at the call site).

Then walk `Current state` itself:

- Every invariant has a `path:line` citation. "The hook fails open"
  is not an invariant; "the hook fails open on missing `jq` at
  `.claude/hooks/lint.sh:19`" is.
- The caller walk gives a concrete number (0 / N / "many — listing
  non-obvious") for every symbol whose contract changes. "Some
  callers" is not a count.
- For `refactor`: the Anti-goals list ties to the Approach's
  behaviour-equivalence statement — both name the same invariants
  from opposite sides.
- For `fix`: the Bug path has a `← BUG` marker on the wrong-data
  step, not on the symptom step.

If any check fails, the section is paraphrase rather than mapping
— re-walk with LSP and cite.

### Scan 5 — Verify-per-step completeness (maps to DESIGN_TEMPLATE §7 Implementation Tasks + §6 Test Plan)

Walk every Step. For each:

- Has a `verify:` clause? (Required for S/M/L; optional for XS.)
- A verify clause must be EITHER:
  - **(a) a runnable command / query / curl** — `npm test
    src/foo.test.ts`, `curl -s :8080/health | jq .status`, `psql -c
    "\d users"`, `grep -n 'NewXxxUseCase' cmd/svc/main.go`. The
    reviewer can paste it into a shell and see the answer.
  - **(b) a state assertion the reviewer can confirm by inspecting a
    specific file / table / log / dashboard named in the clause** —
    `column email_verified exists in users table`, `composition root
    cmd/api/main.go line 142 references NewVerifyUseCase`, `Grafana
    "checkout-latency" dashboard panel "p95" renders`.
- **Pure outcome sentences do NOT count.** `users see X`, `feature
  works end-to-end`, `the page loads correctly`, `behaviour is
  preserved` — these describe what should happen, not how to
  observe it. Reject and rewrite.
- If verify is `manually check`, `visually inspect`, `eyeball the
  output`, `looks correct` → reject.

If a Step doesn't have a clean verify, the step is doing too many
things — split until each piece is verifiable atomically.

> Why this scan is the highest-leverage one: the `verify` clause is
> what the implementer runs after the step, what the reviewer uses
> to confirm the step landed, and what the test phase translates
> into an assertion. A bad verify reaches all three later phases.

## Extra checks for M / L docs

### Alternatives section is honest (M/L feat/refactor)

If you wrote `Alternatives considered`, the rejected options must be
plausible — not strawmen. "Considered X, rejected because it would
be slower" without naming *why* or *by how much* is a strawman.
Either give a real reason (benchmark, complexity argument, ecosystem
maturity) or drop the section.

If there really *was* only one reasonable approach, write a one-line
note in `Approach` saying so (`Approach is the only obvious path
because <constraint>`) and skip the section.

### Rollback is real (L docs)

If `Rollback` says anything beyond "revert the commit", read it as a
runbook:

- Could an on-call engineer at 2am execute it from the text alone?
- Are the steps copy-pasteable, in order, with no implicit context?
- Is `Data loss?` honest? (Almost no rollback is truly "no data
  loss" if the change wrote anything — be precise about *what*
  might be lost.)

### Dependencies are concrete

`External: some library` is not a dependency — `External: pg-listen
>= 1.7.2 (for LISTEN/NOTIFY support added in 1.7)` is. `Internal:
prior PR` is not a dependency — `Internal: must land after PR #482
(schema migration adds users.tenant_id)` is.

### Phases are coherent (L docs with optional Phases)

If you grouped Steps under Phases (>12 steps in L), each phase
should have a clear name (`schema migration`, `write path`, `read
path`, `consumer cutover`) and be roughly independently committable.
A phase named "miscellaneous" is a smell — either it doesn't deserve
its own phase, or the steps in it should be split across the named
phases.

## When to fail self-review and rewrite

Rewrite (don't patch in place) if ANY of:

- Scan 4 (Current-state coverage) fails on ≥1 file
- Scan 2 (AC bijection) breaks for >1 AC
- Scan 5 (Verify-per-step) flags >2 steps with vague verifies
- OR 3+ items total across all scans (the original rule, as a fallback)

A single fundamental gap (current-state) costs more than four cosmetic
ones — fix the structure first. Re-read the spec, re-pick the Size if
needed, and re-draft. Faster than chasing scan hits one by one.

If Scan 4 (Current-state coverage) is the one failing, fix it
*first* before re-running the other scans — most downstream gaps
(vague steps, missing verifies, AC tags that don't quite fit) trace
back to not actually knowing what the existing code does.

## The final question

Before marking `Status: draft`, ask:

> If I handed this doc to an engineer who has never seen the spec,
> could they implement it without asking me anything except about
> ambiguities I've already listed in `Open questions`?

- If **yes** → draft.
- If **no** → which scan caught it? Run that scan again.
- If "I'm not sure" → run all five scans.

The design doc is the *contract* between `design-doc-writer` (the
planner) and whichever preset engineer implements it, and the *spec*
that the gate will review against. Self-review is what makes the
contract stand on its own.

## See also

- [`DESIGN_TEMPLATE.md`](./DESIGN_TEMPLATE.md) — the structure these
  scans audit
- [`SIZE_TIERS.md`](./SIZE_TIERS.md) — pick the right tier first;
  most over-/under-coverage problems start with a wrong-size pick
- [`../../playbooks/post-delegation-review.md`](../../playbooks/post-delegation-review.md) —
  the 6-gate review that runs *after* implementation; this self-
  review catches what gate 1 (Inspect) would otherwise catch
