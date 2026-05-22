# Sprint S01 — Bootstrap

> **Theme:** hex skeleton, first feature end-to-end, smoke test
> **Window:** 2026-04-06 → 2026-04-17
> **Status:** ✅ Closed (5/5 done — 100%)
> **Retro:** [`../retros/sprint-S01.md`](../retros/sprint-S01.md)

## Goal

Establish the production shape of the service — hex layout (`cmd/`,
`internal/app`, `internal/adapters`, `internal/domain`) — and ship
one feature (`POST /shorten` → `GET /{code}`) end-to-end with a
real smoke test, so subsequent sprints have a working chassis to
build on.

## Tasks

| ID | Title | Type | Size | Owner | Design doc | AC short | Status |
|----|-------|------|------|-------|------------|---------------------------------------------------------------|--------|
| URLSH-S01.01 | Hex skeleton + `cmd/server` wiring | feat | M | @alice | [`D001`](../../designs/sprint-S01/D001-hex-skeleton.md) | `go build ./...` green; ports & adapters dirs exist; `Wire()` boots | [x] Done |
| URLSH-S01.02 | `GET /healthz` returns build SHA + uptime | feat | XS | @alice | (inline — sentence test passed; no doc) | `curl /healthz` → 200 with JSON `{sha,uptime_s}` | [x] Done |
| URLSH-S01.03 | In-memory `urlrepo.Store` (concurrent-safe) | feat | S | @bob | (inline — sentence test passed) | `Save`/`Lookup` table tests; race detector clean | [x] Done |
| URLSH-S01.04 | First redirect handler — `POST /shorten` + `GET /{code}` | feat | L | @alice | [`D003`](../../designs/sprint-S01/D003-first-redirect-handler.md) | E2E: shorten → 201 with `code`; redirect → 308 to original URL | [x] Done |
| URLSH-S01.05 | Smoke test — `make smoke` driven by curl + compose-up | feat | S | @bob | (inline) | `make smoke` boots compose, hits both endpoints, exits 0 | [x] Done |

## Acceptance gate (sprint close)

- [x] Tag `v0.1.0` cut on `main` after URLSH-S01.05 merge
- [x] `make smoke` passes in CI from a clean checkout
- [x] Hex boundary scan (`hexagonal-reviewer` agent) reports 0 violations
- [x] All 5 tasks have a row in [`../retros/sprint-S01.md`](../retros/sprint-S01.md) per-task summary

## Notes during sprint

- URLSH-S01.04 caught one cross-cutting issue (idempotency on duplicate body) — captured as F0001 in [`../FOLLOWUPS.md`](../FOLLOWUPS.md); planned for S02 (consumed by URLSH-S02.03).
- URLSH-S01.02 + URLSH-S01.05 both used the "sentence test" path (A005) — no design doc, just AC inline in this file.
