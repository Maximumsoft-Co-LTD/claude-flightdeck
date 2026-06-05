---
name: ship
description: "Use when the user says '/ship uat', '/ship production', 'ship it', '/ship <env>', or needs to deploy to uat/production. Use '/ship --check <env>' for a read-only preflight: 'check the deploy', 'what would deploy break', 'validate before deploy'. Use '/ship changelog' to 'generate a changelog', 'what changed since v1.2.0', or produce Keep-a-Changelog output before tagging. Modes: --check <env> (read-only risk scan, GO/NO-GO), <env> (5-phase deploy), changelog [since <ref>] (CHANGELOG.md generation, also auto-runs at sign-off)."
user_invocable: true
---

# /ship — Deploy Orchestrator + Changelog

**Announce:** Using /ship — identify the mode from the arguments and jump to the
matching section.

## Mode router

| Invocation | Mode | What runs |
|---|---|---|
| `/ship --check <env>` | Pre-flight only (read-only) | Steps 1-8 → risk report |
| `/ship <env>` | Full deploy | Phase 0-5 (pre-flight is Phase 1) |
| `/ship changelog [since <ref>]` | Changelog generation | Steps 1-7, writes CHANGELOG.md |

Bare `/ship` with no args → ask which mode.

## Token budget

- `Grep` against deploy-changes, secret manifests, gitops diffs — never
  full-Read large YAML. Bound `git log` by tag range; never log entire history.
- Read existing `CHANGELOG.md` once. The sign-off report
  (`docs/releases/<env>-signoff-S<N>.md`) is the only file `/ship <env>` writes
  during deploy; `--check` writes nothing.

## Variant router — load before Phase 1 / Step 1

Identify the project's tooling and lazy-load the matching reference (each has
concrete commands, failure modes, fixes).

| If the project uses… | Load before… |
|---|---|
| ArgoCD (GitOps) | `references/gitops-argocd.md` → Phase 3 / Step 6 |
| Flux v2 (GitOps) | `references/gitops-flux.md` → Phase 3 / Step 6 |
| External Secrets Operator | `references/secrets-externalsecrets.md` → Phase 1.4 / Step 4 |
| Sealed-secrets (Bitnami) | `references/secrets-sealedsecrets.md` → Phase 1.4 / Step 4 |
| Any DB schema in scope | `references/migrations-patterns.md` → Phase 1.5 / Step 5 |
| Always (smoke + sign-off) | `references/health-probes.md` → Phase 4 / Step 8 |

Scope-check with `Grep` on the gitops repo (`kind: Application` / `kind: Kustomization` / `kind: ExternalSecret` / `kind: SealedSecret`).

---

## MODE A — `/ship --check <env>` (read-only pre-flight)

**No environment risk.** Does not sync, commit, or mutate cluster state. Outputs
a risk report so a human can decide whether to proceed.

**Step 1 — Confirm cluster context:** `kubectl config current-context` — is this
the TARGET env? Switch before continuing.

**Step 2 — Scan repo state:**
```bash
git -C <repo> branch --show-current
git -C <repo> status -s
git -C <repo> fetch origin
git -C <repo> log --oneline origin/main..HEAD    # unpushed
git -C <repo> log --oneline HEAD..origin/main    # behind
```
Branch not `main` → BLOCKER; dirty (non-docs) tree → BLOCKER; unpushed → WARN; behind → WARN.

**Step 3 — Read the deploy-changes file** `docs/releases/deploy-changes-S<N>.md`.
If missing, scan manually: `.env` vs secret manifests; new migrations
(`git log --diff-filter=A -- migrations/`); new Role/ClusterRole/RoleBinding.

**Step 4 — Secrets sync check** (load the ESO / sealed-secrets reference): every
declared secret exists + is synced in the target namespace. Non-synced/missing → BLOCKER.

**Step 5 — Migration verify locally** (load `references/migrations-patterns.md`):
rehearse each new migration up → down → up on a fresh DB; the schema dump diff
must be empty. Failure → BLOCKER.

**Step 6 — GitOps diff** (`argocd app diff` / `flux diff kustomization … | head -200`):
an image-tag change with no source commit behind it → BLOCKER.

**Step 7 — Image existence check:**
```bash
for img in $(grep -h "image:" deploy/<env>/**/*.yaml | awk '{print $2}'); do
  crane manifest "$img" >/dev/null 2>&1 && echo "OK   $img" || echo "MISS $img"
done
```
Any `MISS` → BLOCKER.

**Step 8 — Health-probe sanity** (load `references/health-probes.md`): liveness ==
readiness (both checking downstreams) → WARN (cascade-failure risk).

**Pre-flight report:**
```
========== PRE-FLIGHT — <env> ==========
Cluster: <context>    Scope: <repos>
BLOCKERS:  • <finding>
WARNINGS:  • <finding>
CLEAN: ✓ repo ✓ secrets ✓ migrations ✓ gitops-diff ✓ images
VERDICT: GO | NO-GO
NEXT: [/ship <env>] OR [fix BLOCKERs then re-run /ship --check <env>]
=========================================
```

---

## MODE B — `/ship <env>` (full 5-phase deploy)

**Phase 0 — Task list.** Create visible tasks: `Ship P1 Pre-flight`, `P2 CI
verify`, `P3 Deploy`, `P4 Health+smoke`, `P5 Sign-off`. Update as each completes.

**Phase 1 — Pre-flight.** Run all MODE A steps. Gate: GO verdict required.

**Phase 2 — CI verification.** `gh run list --limit 1` per repo; if failed, read
logs → fix → push → wait green. Gate: every image tag matches latest `main` SHA.

**Phase 3 — Deploy** (load the GitOps variant reference).
- 3.1 push config if uncommitted (`feat(<env>): update config for sprint S<N>`).
- 3.2 diff + sync per the variant (`argocd app sync --prune` / `flux reconcile --with-source`).
- 3.3 `kubectl rollout status deploy/<name> -n <ns>`.
- 3.4 **production-only** — tag before sync (manual sync only, no prod auto-sync):
  `git tag -a v1.X.X -m "Release v1.X.X: Sprint S<N>"` + push.
Gate: all deployments on new images; migration jobs completed.

**Phase 4 — Health + smoke** (load `references/health-probes.md`):
```bash
TARGET=https://<target>
curl -fsS -o /dev/null -w "healthz: %{http_code}\n" $TARGET/healthz
curl -fsS -o /dev/null -w "readyz:  %{http_code}\n" $TARGET/readyz
kubectl get pods -n <ns> --field-selector=status.phase!=Running -o name
```
Browser smoke (Playwright MCP if available): login, dashboard, sprint features,
no console errors, no raw i18n keys, cross-role test if RBAC changed.

**Phase 5 — Sign-off.** Generate `docs/releases/<env>-signoff-S<N>.md`: date,
deployer, image SHAs, health checklist, secrets/config check, feature table,
smoke results, decision line. Auto-run `/ship changelog` as part of sign-off.

---

## MODE C — `/ship changelog [since <ref>]`

Also auto-runs at Phase 5 sign-off.

1. **Context:** single repo → that repo; platform root + `--unified` → aggregate.
2. **Range:** `LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null||echo "")`;
   `RANGE="${LATEST_TAG:+${LATEST_TAG}..}HEAD"` (or `<ref>..HEAD`).
3. **Parse** `git log ${RANGE} --oneline --no-merges` per Conventional Commits.
4. **Map to Keep-a-Changelog:** feat→Added · fix→Fixed · refactor/perf/docs→Changed ·
   deprecate→Deprecated · revert/remove→Removed · security→Security · test/ci/chore/build/style→skip.
5. **Generate** Markdown (Keep a Changelog 1.1.0), newest first, with short
   commit hashes; omit empty categories.
6. **Write CHANGELOG.md** — read existing once, insert after the header, preserve
   prior entries.
7. **Unified (`--unified`):** aggregate each repo's CHANGELOG under
   `## [Sprint S<N>] - YYYY-MM-DD` with `### <repo> vX.Y.Z` subsections.

Never delete existing entries; skip merge commits; include ticket/task IDs.

---

## Error recovery

| Issue | Fix |
|---|---|
| CI lint fails | check tooling version compat |
| GitOps controller not triggered | check webhook secrets in the app repo |
| Out-of-sync | force-sync (variant reference §Sync) |
| Pod stuck `ContainerCreating` | check PVC multi-attach; delete old pod |
| Migration failed | fix SQL, push — `references/migrations-patterns.md` §Rollback |
| Health check 502 | pod starting — wait 30 s; else check logs |
| Secret not syncing | `references/secrets-externalsecrets.md` §failure modes |
| Roll back | `references/gitops-argocd.md` / `references/gitops-flux.md` §Rollback |

## Canonical reference

`docs/setup/deployment-workflow.md` — the full per-step playbook for
{{PROJECT_NAME}}.

## See also

- `references/gitops-argocd.md` · `references/gitops-flux.md` — diff, sync, rollback
- `references/secrets-externalsecrets.md` · `references/secrets-sealedsecrets.md` — secret gates
- `references/migrations-patterns.md` — rehearsal + rollback drill
- `references/health-probes.md` — smoke matrix + probe config
