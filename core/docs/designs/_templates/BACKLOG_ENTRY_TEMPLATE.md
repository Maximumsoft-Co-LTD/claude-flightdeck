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

> **The Status enum is the contract that keeps the backlog trustworthy.** The #1
> backlog failure is a Status cell that becomes a free-text *log*
> (`discovery → verified → …done` buried mid-cell): no fixed position is
> authoritative, greps see only the stale prefix, and `/work` re-picks shipped
> work. So:
>
> - **Status is exactly one token** from the enum — no narrative, no accumulation,
>   no second clause. History belongs in git + the sprint files, not the cell.
> - **`open` / `wip S##` are the only values allowed in `## Active`.** Terminal
>   values (`done S##` / `wontfix` / `superseded-by B###`) are *swept out* to the
>   cold archive — they never sit in the hot file. `scripts/backlog.sh sweep`
>   does this; `scripts/backlog.sh check` fails CI if one lingers.
> - **Design-review status is NOT a backlog status.** "Verified at design review"
>   lives in the sprint's `designs/INDEX.md` Status column — putting it in the
>   backlog is what made `verified` collide with shipped-`done`. The backlog
>   Status tracks **delivery lifecycle only**.
| **Pri** | `P0` / `P1` / `P2` / `P3` | No suffixes (-CRITICAL, -HIGH, -LOW). Just P0–P3 |
| **Size** | `S` / `M` / `L` / `XL` | S=~1 task group, M=~2-3, L=~4-6, XL=~7+ |
| **Status** | **exactly one** of: `open` · `wip S##` · `done S##` · `wontfix` · `superseded-by B###` | **One token, never a log** — see the enum rules below |

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

The hot `backlog.md` has just **two** sections — it is a working set, not an
archive of all work ever:

```markdown
## Active        ← open + wip rows ONLY (the whole hot working set)
## Follow-ups    ← Open / Closed retro follow-ups (F#### lifecycle)
```

Closed items do **not** get an `## Archive` section in `backlog.md`. They are
swept to a sibling **cold ledger** that is grepped, never Read wholesale:

```
docs/project/archive/backlog-archive.md   ← one thin line per closed item
```

### Rules

1. **New entries** go to `## Active` with status `open`.
2. **Sprint planning** sets the row's status → `wip S##` (it stays in `## Active`).
3. **On close** the status becomes terminal (`done S##` / `wontfix` /
   `superseded-by B###`) and the row is **swept out** of `## Active` into
   `archive/backlog-archive.md` — `scripts/backlog.sh sweep` (run by `/retro`).
4. **Postponed** = leave it `open` (re-prioritize by row order); a genuine
   "won't do" is `wontfix` → swept. There is no separate Deferred section.
5. **`## Active` uses the 6-column table**; the cold archive uses a thin
   3-column line (`| ID | Status | Title |`) — full detail stays in the sprint
   files + `ideas/` + git, never duplicated into the archive.

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
