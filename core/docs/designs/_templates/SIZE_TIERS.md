# Size Tiers — picking the right depth for a design doc

Size determines which sections of `DESIGN_TEMPLATE.md` are required,
which are optional, and which should be deleted. Wrong size = either
bloat (XS work dragged through M template) or under-coverage (M work
treated as S). When borderline, **prefer the larger tier.**

## Section mapping (this file ↔ DESIGN_TEMPLATE.md)

The generic section names used throughout this file (`Approach`,
`Steps`, `Files touched`, `Architecture diagram`, …) map to the
numbered sections in `DESIGN_TEMPLATE.md` as follows. When a row says
"required" or "skip", apply that to the corresponding template section.

| Generic name (this file) | DESIGN_TEMPLATE section |
|--------------------------|---------------------------|
| Approach | §2 Architecture & Approach (intro paragraph + Key Decisions) |
| Step order / Steps | §2 Data Flow & Side-Effects + §7 Implementation Tasks |
| Architecture diagram | §2 High-Level Flow (mermaid) |
| Files touched | §2 File Structure |
| Alternatives considered | §2 Key Decisions (Alternatives column) |
| Risks | §10 Open Questions / Risks |
| Observability | §2.7 Interactive Behavior Map (UI) + AC verify clauses |
| Dependencies | §1 Dependencies |
| Rollback | §10 Open Questions / Risks (rollback row) or new §Rollback subsection |
| Out of scope | §1 Scope (Out of scope bullets) |
| Acceptance Criteria | §9 Acceptance Criteria |
| Test plan | §6 Test Plan |
| API / contract | §3 API Contract |
| Data model | §4 Data Model |
| RBAC | §8 RBAC & Security |

XS work that uses [`DESIGN_LIGHT_TEMPLATE.md`](./DESIGN_LIGHT_TEMPLATE.md)
exposes the lightweight equivalents under different names; the mapping
above is for the full template.

The `design-doc-writer` agent sets `Size:` in the design-doc
frontmatter before drafting the rest. The picker below is also the
implicit answer to *"is this even worth a design doc?"* — see
[A005 in `brain-hot.md`](../../../.claude/rules/brain-hot.md):
"if you could describe the diff in one sentence, skip the design
doc." That sentence-test is the XS floor.

## The tiers at a glance

| Size | Files | Logic | Contract / schema | Subsystem reach | Typical Types |
|------|-------|-------|-------------------|-----------------|---------------|
| **XS** | 1 | none | no | none | chore, docs |
| **S**  | ≤ 2 | simple | no | 1 | fix, small feat, small refactor |
| **M**  | 3–10 | real | additive only | 1 | feat, refactor |
| **L**  | 4–14 | real | **breaking** OR multi-subsystem | ≥ 2 | feat, refactor, fix at a seam |
| **XL** | ≥ 15 OR phased | real | breaking + cross-cutting | ≥ 2 (with phasing) | epic-class feat / multi-sprint refactor |

**XL is a backlog-level marker, not a design-doc size.** L is the cap
for a single design doc; XL backlog items split into multiple L docs
(one per coherent slice) so each can pass the gate independently. See
[`../../setup/zero-fix-task-template.md`](../../setup/zero-fix-task-template.md)
for the ≥500-line zero-fix discipline an XL slice still needs per L
doc.

"Real logic" = branching, state, side effects to design. "Simple
logic" = one branch, no state. "Contract / schema" = public
REST/gRPC/event API, DB schema, queue message shape, IPC, anything
external systems depend on.

## Picker — answer in order

1. **Does the change touch a public contract or schema?**
   (REST/gRPC API, DB schema migration, queue message format, public
   library signature)
   - **Breaking** change (rename / remove a field, change a type,
     change semantics) → **L**. Stop.
   - **Additive** change (new optional field, new endpoint, new
     event variant with old still supported) → **M** unless it
     crosses subsystems (which step 2 catches).
   - A migration that runs DDL on a populated table → **L** even if
     "just adding a column" — the rollout / index-build / dual-read
     plan is design work.
2. **Does the change cross more than one subsystem?**
   (e.g. touches both the API layer and the worker layer; or two
   bounded contexts; or a service plus its sibling)
   → **L**. Stop.
3. **Is there real logic to design?**
   (branching, state machine, retry policy, ordering decision,
   concurrency)
   → **M** if single-subsystem (multi-subsystem already caught in 2).
4. **Is it more than 2 files, OR does it have any logic at all?**
   → **S**.
5. **Single file, no logic, no behaviour change visible to users or
   callers?** (typo, dep bump, doc edit, formatter run, comment
   cleanup)
   → **XS**.

When two answers feel equally true (e.g. "2 files but they're
trivial" vs "1 file but the logic is hairy"), pick **the larger
size**. The cost of an over-sized design doc on small work is a few
extra optional sections you skip; the cost of an under-sized doc on
real work is missed scope caught at the gate (cycle burn).

## Signals that override file count

File count is a *proxy*, not a rule. These signals push size up
regardless:

- **One-file change that adds branching, state, or retry policy** →
  at least S, often M. Complexity lives in the logic, not the file
  spread.
- **One-file change to a public API signature or DB migration** → L.
  Contract changes are always L.
- **Many-file change that's pure rename / formatter / mechanical
  sweep** → still XS or S. Mechanical changes don't carry design
  risk.
- **Touches a security-sensitive path** (auth, crypto, exec,
  deserialise, raw SQL, file/path handling) → bump up one tier. The
  security review (Phase 7 trigger in the [phase matrix](../../../.claude/rules/phase-matrix.md))
  will fire anyway and the doc benefits from more documentation.
- **Introduces a queue, broker, async worker, or pub/sub topic** →
  at least M, often L. The contract you're committing to (delivery
  semantics, idempotency, retry/DLQ, ordering) needs documentation
  even if the code is one consumer file.
- **Removes / decommissions a queue, broker, async worker, or
  pub/sub topic** → at least M, often L. Consumer cutover plan, dual-
  run window, and back-out path are design work; silently dropping a
  topic with live consumers is a high-class outage.

## Edge cases

### "It looks like a chore but it's actually a feature"

Example: "bump library X" sounds XS, but the new version changes the
default error handling, so call sites now behave differently. That's
a **feat** with **S or M** size — the behaviour change is the feature.

Rule: if user-visible behaviour changes, it's not a chore. Re-pick
`Type` first, then `Size`.

### "It's one file but it's a 200-line state machine"

Logic density wins over file count. **M.** A state machine deserves
a diagram, AC tags per transition, and observability around state
changes — all M-tier sections.

### "It's a fix but the fix is one line"

Still run through the picker. A one-line fix to a public API is L. A
one-line guard inside a function is S (with the regression test as
step 1, per the `fix` row of the phase matrix). The fix line count
doesn't determine size — the *blast radius* does.

### "It's a docs-only change but it touches 30 files"

Mechanical docs change (e.g. updating an old name across all guides)
→ **XS**. The plan can list "find/replace + spot-check" as the
entire procedure. Don't drag docs work through M ceremony.

### "It crosses backend + frontend + infra" (full-stack feature)

Default = single L design doc, single dispatch. Crossing three
layers is normal full-stack work, NOT a reason to split into
multiple docs. Only split when both are true: `Ship as: staged` in
the spec frontmatter AND the spec lists ≥ 2 capabilities that can
ship independently.

## What each size requires (cross-link to DESIGN_TEMPLATE.md)

| Section | XS | S | M | L |
|---------|----|----|----|----|
| `Approach` (2–3 sentences) | ✓ | ✓ | ✓ | ✓ |
| `Step order` line | skip | optional | ✓ | ✓ |
| `Architecture diagram` | one-line / N/A | mini mermaid (3–5 nodes) | full mermaid by Type | full + before/after |
| `Steps` (action — path:line — verify — [AC#]) | verify optional | ✓ | ✓ | ✓ |
| (Optional) Phases above Steps | skip | skip | skip | ✓ if >12 steps |
| `Files touched` table | ✓ | ✓ | ✓ | ✓ |
| `Alternatives considered` | skip | skip | when non-obvious | ✓ |
| `Risks` table | skip | optional | ✓ | ✓ |
| `Observability` | N/A | required if feat/fix | required if feat/fix | ✓ |
| `Dependencies` | skip unless present | skip unless present | skip unless present | ✓ |
| `Rollback` | "revert commit" line | "revert commit" or specific | ✓ if destructive | ✓ runbook |
| `Out of scope` | ✓ | ✓ | ✓ | ✓ |

`skip` means *delete the section*, not leave it empty with
placeholder text. Empty sections erode the gating discipline.

## How long should a design doc take to write?

Rough budget (for `design-doc-writer` with brain-hot already loaded):

| Size | Doc-write time | Notes |
|------|----------------|-------|
| XS | 2–5 min | Almost entirely template fill-in |
| S | 5–15 min | Real thinking about Steps + Diagram |
| M | 20–45 min | Alternatives + Diagram + Risks need real thought |
| L | 1.5–4 hr | Two diagrams + Dependencies + L-grade Rollback runbook. If hitting 4 hr, the task is likely XL — re-pick Size. Splitting an L into two M's is faster than dragging a 5-hr L over the line. |

If you're spending 2× the budget at any tier, something's wrong:
scope grew without a Size bump, or the spec is too vague to design
against. In the latter case, go back to discovery — don't paper over
with a longer doc.

## See also

- [`DESIGN_TEMPLATE.md`](./DESIGN_TEMPLATE.md) — the full template
  these tiers specialize
- [`SELF_REVIEW_CHECKLIST.md`](./SELF_REVIEW_CHECKLIST.md) — pre-gate
  scan run against the drafted doc
- [`../../setup/zero-fix-task-template.md`](../../setup/zero-fix-task-template.md) —
  the ≥500-line zero-fix discipline (mostly applies to L)
- [`../../../.claude/rules/phase-matrix.md`](../../../.claude/rules/phase-matrix.md) —
  type × phase decision table that tells you whether to write a doc
  at all
