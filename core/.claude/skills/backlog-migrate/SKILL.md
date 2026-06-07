---
name: backlog-migrate
description: "Use when a project's backlog has drifted — '/backlog-migrate', 'the backlog status is wrong/unreliable', 'we keep re-picking work that's already done', 'backlog.md is huge / hundreds of KB', 'clean up the backlog', 'too many sprint folders', 'migrate the backlog to the new format', or after adopting the open/wip enum on an existing project. One-time reconcile: classify every row by sprint evidence (not the drifted Status column), rewrite the hot file to open/wip-only, emit the cold archive + an uncertain list for review, and roll old sprints to historical/."
user_invocable: true
---

# /backlog-migrate — one-time reconcile of a drifted backlog

**Announce:** Using /backlog-migrate to reconcile the backlog against real sprint
evidence and split hot/cold.

The disease this cures: a `backlog.md` whose `Status` column drifted from reality
(rows marked `verified`/`scheduled`/blob-text that were actually shipped sprints
ago), grown to hundreds of KB because done items never left the file, with a
sprints/ dir cluttered by dozens of closed folders. The result is `/work`
re-picking already-shipped work. This skill rebuilds trust **from evidence, not
from the status column** — once. After it, the mechanism (`scripts/backlog.sh`
check/sweep/verify + the CI gate) keeps it clean.

## Token budget

- **Never Read the giant `backlog.md` wholesale into the main session.** Dispatch
  the per-row evidence gathering to an `Explore` subagent (read-heavy fan-out over
  `sprints/`) — it returns a slim classification table, not file dumps.
- The main session holds only: the classification table + the rewrite it authors.
- Use `scripts/backlog.sh` for the deterministic steps (sweep/index/check/
  archive-sprints) — 0 LLM tokens.

---

## Preconditions

1. **Clean git tree** on a fresh branch (`chore/backlog-migrate`). Everything this
   skill does is a reviewable diff; the original `backlog.md` is preserved in git
   — **nothing is deleted**, only moved/rewritten. Confirm with the user first.
2. The new schema docs are in place (`docs/designs/_templates/BACKLOG_ENTRY_TEMPLATE.md`
   Status enum: `open | wip S## | done S## | wontfix | superseded-by B###`).

## Procedure

### Legacy structures you'll actually meet (real-world)

A drifted backlog is NOT one clean `## Active` table. Expect, in one file:
- Multiple status-bearing sections (`## Active`, `## Unscheduled`, `## Scheduled`,
  `## Deferred`, `## Archive`) **with inconsistent columns** — some end in
  `Status`, some in `Source`, some in a `Task` number with no status at all.
- **Initiative sub-tables** (`## ... Initiative (INIT-001)` → `### Phase F/T/W/…`),
  each its own table — a common place closed work hides (the `## Active` sweep
  never reached it).
- **Detail blocks** (`### B### — …`) holding prose state below the tables.
- **Blob Status cells**: a single cell that is a *log* —
  `discovery D067 (ready S130) … **IMPL DONE S130** … promoted dev→main`. The
  real state is buried mid-cell after a stale prefix; a prefix/`cut` read lies.
- A **partially-migrated** file: the cold archive may already hold a bulk sweep —
  don't re-process IDs already there.

Section → status hint (a starting guess, always confirmed by evidence): Active=already-swept ·
Unscheduled→`open` · Scheduled→evidence · Deferred→`open`/`wontfix` · Archive→`done` ·
INIT phases→evidence.

**Two board formats + the board can drift too.** Newer boards use the backlog ID
as the task ID (`| B524 | … | `[x]` |` — `scripts/backlog.sh verify` reads these).
Older boards use a sprint-task ID with a **`Backlog` column mapping one task to
many IDs** (`| 83.A | … | B413+B414+B415 | … | [ ] Not Started |`) — and these
often **drifted to "Not Started" even for shipped work**. So a board `[x]` is
proof-of-done, but *no* board mark is **not** proof-of-open. **Git is the
authoritative arbiter**: a merged branch/PR for the ID (or the feature code
existing) settles a row the board+backlog both fail to. When git can't settle it
either → `uncertain` (never guess).

### 1. Inventory (delegated — keep main context lean)

Dispatch one `Explore` agent: *"From `docs/project/backlog.md`, list EVERY `B###`
across ALL sections (Active/Unscheduled/Scheduled/Deferred/Archive, every
`### Phase` initiative table, and `### B###` detail blocks) with its raw Status/
Source cell. For EACH id, gather ship evidence: run `scripts/backlog.sh verify
<B###>` (it cross-checks the sprint boards + cold archive), and also scan the
WHOLE status cell for terminal markers (`done`/`DONE`/`SHIPPED`/`LIVE`/`merged
PR`) — not just its prefix. Return `ID | section | raw-status | board-evidence
(S<N> [x] | NONE) | whole-cell-marker`. Never trust the status prefix."*

### 2. Classify each row (evidence wins, not the Status cell)

| Bucket | Rule (in priority order) |
|---|---|
| **confirmed-done** | a sprint board marks the ID `[x]` (`scripts/backlog.sh verify` → CLOSED) — **authoritative, beats any Status text**; OR a terminal marker anywhere in the cell corroborated by a retro/merged-PR |
| **confirmed-open** | NO board `[x]`, no ship marker anywhere, section isn't Archive |
| **uncertain** | board says nothing but the cell hints done; conflicting signals; blob mixing states with no board row to settle it |

> This is exactly the two-layer check done by hand: (1) the sprint board `[x]`
> (the backlog ID *is* the task ID on most projects — `verify` exploits that);
> (2) a done-marker *anywhere in the row*, never just the prefix. Board evidence
> outranks the Status cell — that cell is the thing that drifted.

### 3. Rewrite — hot file, cold ledger, uncertain list (one commit)

- **`docs/project/backlog.md` `## Active`** ← confirmed-open rows only, Status
  normalized to `open` (or `wip S<N>` if genuinely in the current sprint). Drop
  the old `## Unscheduled/Scheduled/Recently Done/Archive` sections — the
  template is now `## Active` + `## Follow-ups` only.
- **`docs/project/archive/backlog-archive.md`** ← one thin line per confirmed-done
  (`| B### | done S<N> | title |`), pointing at the closing sprint. Detail stays
  in the sprint files + git — never copied here.
- **`docs/project/archive/backlog-uncertain.md`** ← the uncertain bucket, with the
  conflicting evidence for each, for the user to adjudicate. **Do not silently
  guess** a 50/50 row into done or open — surface it. (This is the user-facing
  "🟡 needs reconcile" list.)

### 4. De-clutter sprints + regenerate derived files

```bash
scripts/backlog.sh archive-sprints --keep 3          # dry-run: preview the roll
scripts/backlog.sh archive-sprints --keep 3 --apply  # git mv closed → historical/
scripts/backlog.sh index                             # regenerate backlog-index.md
scripts/backlog.sh check                             # MUST exit 0 (enum + size cap)
scripts/backlog.sh install-hook                      # commit-time gate → stays synced from now on
```

### 5. Hand back for review

Report: counts per bucket (done / open / uncertain), backlog.md before→after size,
sprint folders rolled, and the path to `backlog-uncertain.md`. **The uncertain list
is the deliverable that needs a human** — walk the user through it; each
resolution is a one-line edit (`open`, or `done S<N>` → re-run `sweep`).

## What to NEVER do

- ❌ Trust the Status column to decide done-ness — that's the drift you're fixing.
- ❌ Delete the original backlog or any sprint folder (only `git mv` / rewrite —
  git keeps history).
- ❌ Force an `uncertain` row into a bucket to make the numbers clean — surface it.
- ❌ Read the whole legacy backlog into the main session — delegate to `Explore`.

## See also

- [`../../../docs/designs/_templates/BACKLOG_ENTRY_TEMPLATE.md`](../../../docs/designs/_templates/BACKLOG_ENTRY_TEMPLATE.md) — the Status enum this migrates to
- [`../../../docs/setup/index-discipline.md`](../../../docs/setup/index-discipline.md) — the hot/cold split + why the enum exists
- [`../retro/SKILL.md`](../retro/SKILL.md) — the recurring sweep that keeps it clean after migration
- [`../work/SKILL.md`](../work/SKILL.md) — the confirm-open pick-gate that consumes a clean backlog
