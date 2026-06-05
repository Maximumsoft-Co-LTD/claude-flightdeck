# url-shortener — Status

> Source of truth for the url-shortener track. Each session updates its row when sprint state changes.
>
> **Discipline (per A008 source-of-truth rule)**: Each row holds **CURRENT-SPRINT STATE ONLY** (1-3 sentences). When a sprint closes, **MOVE its prose to `STATUS-archive.md` in the SAME commit** — do NOT append to your row. Active-sprint detail lives in `sprints/NN/tasks.md`, closed-sprint detail in `sprints/NN/retro.md`. `STATUS.md` is a single-pane glance, not a ledger.

## Active per track

| Track | Active sprint | In-flight task | Branch | Last update | Owner session |
|---|---|---|---|---|---|
| **url-shortener** (`urlsh-`) | **S03 ACTIVE 🚀** — Analytics (click tracking, daily rollup, admin reporting). D007 done; D008 in flight; D009 queued. | `URLSH-S03.02` — Redis hot cache for resolver | `feat/urlsh-s03.02-redis-cache` | 2026-05-21 | main-session |

## Sprint cadence (target)

| Sprint | Status | Window | Goal |
|---|---|---|---|
| **S01** | ✅ closed | 2026-04-06 → 2026-04-17 | Bootstrap: hex skeleton, `/healthz`, first redirect handler, smoke test |
| **S02** | ✅ closed | 2026-04-20 → 2026-05-01 | Persistence: Postgres adapter, migrations, Idempotency-Key, Redis cache wiring |
| **S03** | 🟢 active | 2026-05-04 → 2026-05-22 | Analytics: click tracking, daily rollup, admin reporting endpoint |
| **S04** | 🟡 next | 2026-05-25 → 2026-06-05 | Rate-limit + abuse signals (tentative) |

## Update protocol

When a session changes its track row:

1. Grep current row by track name (always unique).
2. **REPLACE** Active sprint / In-flight task / Last update / Owner session columns — do NOT append historical prose.
3. **MOVE** prior sprint's prose into `STATUS-archive.md` in the SAME commit (or confirm it already lives there). Append-only; preserve verbatim.
4. Commit with message `docs(status): url-shortener <change-summary>`.
5. If conflict on merge — both sessions closed at same time; reconcile by reading both rows and combining.

When opening a new sprint:

1. Update this row (REPLACE, not append) + move closed sprint prose to `STATUS-archive.md` in same commit.
2. Create sprint file at `docs/project/sprints/S<NN>/tasks.md`.
3. Update `backlog.md` so each newly-scheduled row tags the sprint.

## See also

- Active backlog: [`backlog.md`](./backlog.md)
- Closed-sprint prose: [`STATUS-archive.md`](./STATUS-archive.md)
- Active sprint detail: [`sprints/S03/tasks.md`](./sprints/S03/tasks.md)
- Live mini-retros (this sprint): [`sprints/S03/tasks.md`](./sprints/S03/tasks.md)
- Follow-up registry: [`FOLLOWUPS.md`](./FOLLOWUPS.md)
