# Backlog Entry Template

> Standard format for ALL entries in `docs/project/backlog.md`.

## Table Format (6 columns — used in every section)

```markdown
| ID | Type | Title | Pri | Size | Status |
|----|------|-------|-----|------|--------|
| B### | feat | **Bold Name** — one-line description (~100 chars) | P1 | M | new |
```

### Column Definitions

| Column | Values | Notes |
|--------|--------|-------|
| **ID** | `B###` sequential | Never reuse. Increment `Next ID` counter at top of backlog.md |
| **Type** | `feat` / `bug` / `enh` / `debt` / `audit` | See Type Guide below |
| **Title** | **Bold name** — description | Keep to ~100 chars. Bold the noun phrase, dash, then context |
| **Pri** | `P0` / `P1` / `P2` / `P3` | No suffixes (-CRITICAL, -HIGH, -LOW). Just P0–P3 |
| **Size** | `S` / `M` / `L` / `XL` | S=~1 task group, M=~2-3, L=~4-6, XL=~7+ |
| **Status** | `new` / `scheduled S##` / `done S##` / `deferred` / `wontfix` | Always include sprint number |

### Type Guide

| Type | When to use |
|------|-------------|
| `feat` | New capability that didn't exist before |
| `bug` | Something broken that should work |
| `enh` | Improvement to an existing working feature |
| `debt` | Code cleanup, dead code, test gaps, refactoring |
| `audit` | Investigation task — output is a report, not code |

### Backlog Type → Phase-Matrix Type (mapping)

The backlog uses business-facing vocabulary (`bug`, `enh`, `debt`,
`audit`) because that's what stakeholders read. The
[phase matrix](../../../.claude/rules/phase-matrix.md) and
[git-workflow](../../../.claude/rules/git-workflow.md) use commit-
facing vocabulary (`feat | fix | refactor | chore | docs | spike |
release`). When a backlog row promotes into a sprint task or design
doc, translate via this table:

| Backlog `Type` | Phase-Matrix / Commit `Type` | Notes |
|----------------|------------------------------|-------|
| `feat` | `feat` | Direct match |
| `bug` | `fix` | Failing regression test ships first (A001) |
| `enh` | `feat` *or* `refactor` | New behaviour → `feat`; pure shape change → `refactor` |
| `debt` | `refactor` | Behaviour-equivalence note required |
| `audit` | `spike` | Output is `findings.md`, no production code lands without re-promotion |
| (any backlog row producing only docs) | `docs` | Use sparingly — most "doc" work actually changes behaviour via examples |

If the backlog row's eventual sprint task can't be mapped to one of
the seven phase-matrix types, the row is too vague to schedule —
split it.

## Detail Block (optional — for entries needing context beyond the table row)

Place immediately after the table, using `<details>` for collapsible content:

```markdown
<details>
<summary>B### — Title</summary>

**Source:** D### (`docs/project/ideas/D###-slug.md`) or Sprint ## testing
**Spec Ref:** XX-### (if your project tracks a spec ID)
**Root Cause:** (bugs only) concise description of why it happens
**Dependencies:** B### (blocks), B### (related)

**Key AC:**
- Bullet 1
- Bullet 2
- Bullet 3

**Notes:** extra context if needed

</details>
```

### Detail Block Rules

- **Source** — required for promoted discovery items; optional otherwise
- **Spec Ref** — only include if one exists; don't add placeholders
- **Root Cause** — bugs only; move multi-paragraph analysis here instead of cramming the table row
- **Dependencies** — use `blocks` (hard dependency) or `related` (soft)
- **Key AC** — 3–5 bullets summarizing acceptance criteria
- **Notes** — anything else (screenshots, links, context)

## Section Organization

Backlog file has 4 sections, ordered by lifecycle:

```markdown
## Active
<!-- Unscheduled items, sorted by priority (P0 first) -->

## Scheduled
<!-- Items assigned to a sprint, grouped by sprint number -->

## Deferred
<!-- Explicitly postponed — each MUST have a reason -->

## Archive
<!-- Completed items — collapsed <details> block -->
```

### Rules

1. **New entries** go to Active with status `new`
2. **Sprint planning** moves items to Scheduled, status → `scheduled S##`
3. **Completed items** move to Archive, status → `done S##`
4. **Postponed items** move to Deferred with reason in detail block
5. **Every section** uses the same 6-column table — no exceptions

## File Header

```markdown
# {{PROJECT_NAME}} — Product Backlog

> **Next ID:** B### | **Last reviewed:** YYYY-MM-DD

## Complexity Scale
| Size | Estimate | Example |
|------|----------|---------|
| S | ~1 task group | Seed data, simple config |
| M | ~2-3 task groups | CRUD backend or frontend |
| L | ~4-6 task groups | Full feature (backend + frontend + tests) |
| XL | ~7+ task groups | Complex feature with real-time, CRDT, etc. |
```
