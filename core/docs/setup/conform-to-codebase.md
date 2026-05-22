# Conform to the Codebase — detect conventions before imposing them

> **The rule:** a preset's architecture (hexagonal, Feature-Sliced Design,
> Pinia stores, Helm layout, …) is a **default assumption, not a mandate.**
> Before writing code, detect how *this* project actually organizes itself
> and conform to that. The codebase's reality wins over the preset's ideal.
> When they conflict and you'd have to *introduce* the preset's architecture
> into a project that doesn't use it — **STOP and ask.**

## Why this exists

Presets are installed on a **language signal** (a `go.mod` → `go-hex`, a
`"next"` dependency → `nextjs-fsd`). That signal does **not** prove the
project follows the preset's architecture. A Go service can be a flat
`main.go` + `handlers/` + `db/`; a Next app can be plain `app/` +
`components/` with no Feature-Sliced layers. If the engineer agent blindly
applies the preset's strict layout, it produces code in a shape the project
never used — technically "correct" per the preset, wrong for the repo.

This is the structural cousin of `programming-fundamentals.md` rule 7
("read the existing code first") — applied to **architecture**, not just to
finding a helper.

## The detect → conform → ask procedure

Run this BEFORE writing any code (it's part of every coding agent's
pre-task ritual):

### 1. Detect the project's actual conventions

- **Glob the area you're about to touch** and **Read 2-3 representative
  existing files** (a handler, a model, a test). How does *this* project
  name things, layer things, wire things?
- **Read the area's `CLAUDE.md`** (if present) — the documented conventions
  win over both the preset and your inference.
- **Check whether the preset's enforcement tooling is actually wired**:
  - go-hex → is there a `make verify-isolation` target / an
    `internal/{domain,ports,usecase,adapters}` tree?
  - nextjs-fsd → is `eslint-plugin-boundaries` in the eslint config / a
    `src/{features,entities,shared}` tree?
  - vue-pinia → is `pinia` a dependency / a `stores/` directory?
  - If the tooling/dirs are absent, the project almost certainly does **not**
    follow that architecture.

### 2. Decide

| Observation | Action |
|---|---|
| Project already follows the preset's architecture | Proceed with the strict preset pattern. Enforce its boundary tooling as normal. |
| Project follows a **different but consistent** pattern | **Conform to the project's pattern.** Match its layout, naming, and wiring. Note the deviation from the preset in your report. Do NOT introduce the preset's layout alongside it. |
| Ambiguous, OR the task would force you to **introduce** the preset's architecture into a project that doesn't use it | **STOP. Report `NEEDS_CONTEXT`** (see below). Do not impose. |

### 3. Ask (on conflict / ambiguity)

Report `NEEDS_CONTEXT` with:

- **What you observed** — the actual layout (paste the directory tree / a
  representative file path), and the absence of the preset's signature
  dirs/tooling.
- **The conflict** — e.g. "this preset assumes hexagonal `internal/ports`,
  but the service is a flat `handlers/` + `store/` layout with no ports."
- **The options** — "(a) follow the existing flat layout for this task, or
  (b) introduce the hexagonal layout for this module (larger change, should
  be its own design-doc decision)."

Then wait for the operator's choice. Introducing an architecture a project
doesn't use is an architectural decision (A005) — it belongs in a design
doc and a human call, not an unasked-for side effect of a feature task.

## What this does NOT mean

- It does **not** mean "abandon the preset." If the project *does* follow
  the architecture, enforce it strictly — that's the preset's whole value.
- It does **not** mean "match every local quirk forever." Genuinely bad
  local patterns can be improved — but that's a design-doc decision, raised
  explicitly, not imposed mid-task.
- It does **not** loosen TDD, the gates, or the other A-rules. Those are
  universal; only the *architectural shape* yields to the codebase.

## If the preset is simply wrong for the project

If detection shows the installed preset doesn't fit at all (e.g. `go-hex`
on a non-hex service), flag it: the operator can re-run `/onboard` or
re-install without that preset. The onboarding wizard runs an
**architecture-fit** probe at setup time to catch this before dispatch —
see [`onboarding-guide.md`](onboarding-guide.md).

## See also

- [`../../.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md) — the detect-and-conform step
- [`../../.claude/rules/programming-fundamentals.md`](../../.claude/rules/programming-fundamentals.md) — "read the existing code first"
- [`discipline-red-flags.md`](discipline-red-flags.md) — A005 (design-first): introducing an architecture is a design decision
