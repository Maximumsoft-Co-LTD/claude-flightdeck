---
name: deploy
description: "Drive a deployment through its canonical 5 phases — pre-flight check, CI verification, deploy, health + smoke, sign-off report. Use when the user says '/deploy uat', '/deploy production', '/deploy <env>', 'ship it', or anytime an environment promotion is needed. Canonical reference: docs/setup/deployment-workflow.md."
user_invocable: true
---

# /deploy — Stage-Gated Deployment Orchestrator

Walk a deployment through 5 phases with explicit gates between them.
Ensures no env var, secret, migration, or config is missed.

## Variant router — load before Phase 1

Before reading further, identify the project's tooling and load the
matching reference deep-dives. Each reference is opinionated + concrete
(real commands, real failure modes, real fixes).

| If the project uses... | Load before reaching... |
|---|---|
| ArgoCD as GitOps controller | `references/gitops-argocd.md` → Phase 3 |
| Flux v2 as GitOps controller | `references/gitops-flux.md` → Phase 3 |
| External Secrets Operator (ESO) | `references/secrets-externalsecrets.md` → Phase 1.4 |
| Sealed-secrets (Bitnami) | `references/secrets-sealedsecrets.md` → Phase 1.4 |
| Any DB schema in the deploy scope | `references/migrations-patterns.md` → Phase 1.5 |
| Always (for the smoke + sign-off matrix) | `references/health-probes.md` → Phase 4 |

**You can scope check** with `Grep` on the gitops repo:
- ArgoCD: `Grep "kind: Application" deploy/` finds Application CRs.
- Flux: `Grep "kind: Kustomization" deploy/` finds Flux Kustomizations.
- ESO: `Grep "kind: ExternalSecret" deploy/`.
- Sealed: `Grep "kind: SealedSecret" deploy/`.

## When to split: `/deploy-preflight` vs `/deploy`

- `/deploy-preflight <env>` — read-only Phase 1 only. No env risk. Use
  when you want to know "what would deploy break?" without committing
  to a deploy.
- `/deploy <env>` — full 5-phase orchestration.

## Token budget (MANDATORY)

- Use `Grep` against the deploy-changes file + secret / configmap
  manifests — do not full-Read large YAML.
- The sign-off report is the only file this skill writes; everything
  else is verification via shell.

## Input

User provides: `/deploy <environment>`

- `/deploy <staging-env>` — deploy current `main` to staging
  (auto-sync via your GitOps controller, if applicable)
- `/deploy <prod-env>` — tag + deploy to production (manual sync)

If user just types `/deploy` without args, ask: "Which environment?
`/deploy <staging>` or `/deploy <prod>`?"

## Prerequisites

- Cloud / cluster credentials configured (always confirm context
  first via `kubectl config current-context`).
- All repos accessible from the current working tree.
- Deployment-tool CLI ready (`kubectl`, `helm`, `gh`, your GitOps CLI,
  etc.).
- `gh` (or your platform CLI) authenticated.

---

## Phase 0 — Create task list (TaskCreate)

Create visible tasks for tracking:

- `Deploy P1 — Pre-flight check`
- `Deploy P2 — CI verification`
- `Deploy P3 — Deploy to {env}`
- `Deploy P4 — Health check & smoke test`
- `Deploy P5 — Sign-off report`

Update status as each phase completes.

## Phase 1 — Pre-flight check

### 1.1 Switch cloud / cluster context
Confirm you are pointing at the **target** environment.

### 1.2 Scan repo state
For each repo in the deployment scope:

```bash
git branch --show-current
git status -s
git fetch origin
git log --oneline origin/main..HEAD   # unpushed
git log --oneline HEAD..origin/main   # behind
```

**Gate:** all repos on `main`, synced with origin. No uncommitted
changes except docs.

### 1.3 Read the deploy-changes file
Check `docs/releases/deploy-changes-S<N>.md` for: new env vars, new
migrations, new secrets, new ConfigMap entries, new RBAC modules. If
missing, scan manually with `Grep`.

### 1.4 Secrets & environment sync
**→ Load the secrets variant reference now** (ESO or sealed-secrets,
per the router above). Run the pre-flight gate from that reference.

**Gate:** all secrets exist + all manifests up to date.

### 1.5 Migration check
**→ Load `references/migrations-patterns.md` now.** Verify any new
migration is idempotent + reversible (or documented-irreversible) +
rehearsed locally.

---

## Phase 2 — CI verification

### 2.1 Check latest CI status
```bash
gh run list --limit 1   # per repo
```
If CI failed: read logs, fix, push, wait for green.

### 2.2 Verify images / artifacts exist
After CI passes, confirm the deployment manifests reference the new
image SHA / artifact version.

**Gate:** every deployment's image tag matches the latest `main` SHA.

---

## Phase 3 — Deploy (staging or production)

**→ Load the GitOps variant reference now** (ArgoCD or Flux). Follow
its `diff before sync` + `sync` flow.

### 3.1 Push deployment config (if needed)
If your deployment-config repo has uncommitted changes:

```bash
git add -A && git commit -m "feat(<env>): update config for sprint S<N>"
git push origin main
```

### 3.2 Diff + sync
Per the variant reference (`argocd app diff` + `argocd app sync
--prune` OR `flux diff kustomization` + `flux reconcile kustomization
--with-source`).

### 3.3 Wait for rollout
```bash
kubectl rollout status deploy/<name> -n <ns>
```

**Gate:** all deployments running new images, any migration job
completed.

### 3.4 Production-only — tag the release
For prod, gate the sync behind an explicit tag:

```bash
git checkout main && git pull origin main
git tag -a v1.X.X -m "Release v1.X.X: Sprint S<N> summary"
git push origin v1.X.X
```

Review the diff in your GitOps UI before syncing (manual sync, no
auto-sync to prod).

---

## Phase 4 — Health check & smoke test

**→ Load `references/health-probes.md` now** for the per-stack smoke
matrix.

### 4.1 Automated health
```bash
TARGET=https://<target>
curl -fsS -o /dev/null -w "healthz: %{http_code}\n" $TARGET/healthz
curl -fsS -o /dev/null -w "readyz:  %{http_code}\n" $TARGET/readyz
curl -fsS -o /dev/null -w "protected: %{http_code}\n" $TARGET/api/me   # expect 401
```

### 4.2 Pod / process status
```bash
kubectl get pods -n <ns> --field-selector=status.phase!=Running -o name
# Empty output = clean
```

### 4.3 Browser smoke test
Open the target in a browser (or use Playwright MCP):
- [ ] Login page loads — no blank / 404
- [ ] No browser console errors
- [ ] Dashboard loads after login
- [ ] Sprint features accessible
- [ ] No raw i18n keys visible
- [ ] Cross-role test (if RBAC changed)

### 4.4 Migration verify
Check the migration job log; confirm `applied N migrations` matches
the count from Phase 1.5.

---

## Phase 5 — Sign-off report

Generate `docs/releases/<env>-signoff-S<N>.md` with: date, deployer,
image SHAs, health-check checklist, secrets + config check, feature
verification table, browser smoke results, and a decision line
(APPROVED for prod / REJECTED + issues).

---

## Deploy-changes tracking (during development)

After each post-delegation review, auto-append new env vars / secrets
/ migrations / RBAC modules to:

`docs/releases/deploy-changes-S<N>.md`

Sections: New Migrations · New Secrets Required · New
ExternalSecret / SealedSecret Entries · New ConfigMap Entries · New
Permission Modules · CI Changes.

---

## Error recovery

| Issue | Fix |
|---|---|
| CI lint fails | Check tooling version compat |
| Receiver / GitOps controller not triggered | Check webhook secrets in the app repo |
| Out-of-sync | Force-sync (see variant reference §Sync) |
| Pod stuck `ContainerCreating` | Check PVC multi-attach; delete the old pod |
| Migration failed | Check pod logs; fix SQL; push a new commit (see `references/migrations-patterns.md` §Rollback drill) |
| Old image still serving | Force-sync; confirm immutable image tag |
| Health check 502 | Pod starting; wait 30s; if persistent, check logs |
| Secret not syncing | See `references/secrets-externalsecrets.md` §Common failure modes |
| Need to roll back | See `references/gitops-argocd.md` or `references/gitops-flux.md` §Rollback |

## Canonical reference

`docs/setup/deployment-workflow.md` — the full per-step playbook for
{{PROJECT_NAME}}.
