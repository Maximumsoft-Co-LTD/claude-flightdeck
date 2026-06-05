# GitOps with ArgoCD — Sync, Diff, Rollback

> Loaded by `/deploy` Phase 3 when the project uses ArgoCD as its GitOps
> controller. Assumes the `argocd` CLI is installed in-cluster (run from
> a bastion / jump pod) and authenticated against the in-cluster API
> server. For out-of-cluster CLI use, swap `argocd login --core` for the
> `argocd login <argo-host>` flow.

## Topology assumptions

- ArgoCD control plane lives in the `argocd` namespace.
- Each `Application` CR lives in `argocd` and points at a target
  namespace (e.g. `staging`, `prod`).
- `ApplicationSet` rolls multiple `Application` resources from a single
  template (per-env, per-service patterns).
- The Git source is the `deploy/` or `gitops/` mono-repo with one
  directory per Application.

## CLI auth (in-cluster)

```bash
# Pod with kubeconfig already mounted (e.g. tools pod)
argocd login --core                      # uses kube API for auth
argocd context                           # confirm the right cluster

# Out-of-cluster
argocd login argocd.example.com \
  --username admin --password "$ARGOCD_PASSWORD" --grpc-web
```

## Read app state (Phase 1.2 — pre-flight)

```bash
# List all applications + sync + health
argocd app list -o wide

# Single app status (this is your gate signal)
argocd app get <app-name>
# Fields to gate on:
#   Sync Status:       Synced | OutOfSync
#   Health Status:     Healthy | Progressing | Degraded | Missing
#   Operation State:   Succeeded | Running | Failed
#   Sync Revision:     <git SHA>
```

A clean pre-flight requires **Synced + Healthy + Succeeded + revision
matches `git rev-parse origin/main`** of the gitops repo.

## Diff before sync (Phase 3.1)

Never sync blind. Always diff first — even on staging.

```bash
# Diff what ArgoCD will apply vs current cluster state
argocd app diff <app-name>

# Show the diff for a specific revision (e.g. a tag)
argocd app diff <app-name> --revision v1.5.0
```

The diff is the contract for "what will change." If it surprises you —
stop. Investigate the gitops repo before syncing.

## Sync (Phase 3.2)

### Staging (auto-sync usually enabled, but force is safe)

```bash
argocd app sync <app-name> --prune
```

- `--prune` removes resources deleted from Git. Without it, orphans
  accumulate and you'll hit "deployed something that no longer exists
  in source."
- `--strategy hook` runs Sync hooks (PreSync / Sync / PostSync /
  SyncFail). PostSync is where a migration Job typically lives.

### Production (manual sync mandatory)

```bash
# Set auto-sync OFF on prod Applications (one-time):
argocd app set <prod-app> --sync-policy none

# Manual sync only when ready
argocd app sync <prod-app> --prune --strategy apply
```

### Partial sync (one resource only)

```bash
argocd app sync <app-name> --resource :Deployment:my-deploy
# or
argocd app sync <app-name> --resource apps:Deployment:my-deploy
```

Useful when you want to push a single fix without resyncing the whole
app (e.g. emergency env-var change).

## Wait for sync to complete

```bash
argocd app wait <app-name> --health --timeout 300
# Exits 0 when Healthy, non-zero on timeout / Degraded
```

Pair with `kubectl rollout status` for the underlying Deployment if you
need rollout-level granularity.

## Sync hooks + migration jobs

Migration patterns (annotate the Job manifest):

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync         # run before applying others
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
    argocd.argoproj.io/sync-wave: "-5"       # lower = earlier
```

- `PreSync` blocks the rest of the sync until the Job succeeds — use
  for forward migrations that the new pods require.
- `PostSync` runs after Deployments are Healthy — use for cache warm,
  smoke probes.
- `SyncFail` runs only if the sync failed — use for cleanup / alerts.

## Retry semantics

ArgoCD retries failed sync operations according to the Application's
retry policy:

```yaml
spec:
  syncPolicy:
    retry:
      limit: 3
      backoff:
        duration: 30s
        factor: 2
        maxDuration: 5m
```

Manual retry: `argocd app sync <app> --retry-limit 3`. After a
`SyncFailed` state, ArgoCD won't auto-retry past the limit — you must
intervene.

## Rollback

When a sync introduced a regression and you need to revert:

```bash
# Show sync history
argocd app history <app-name>
# ID  REVISION
# 0   abc123 (the bad one — current)
# 1   def456 (the previous good one)

# Roll back to ID 1
argocd app rollback <app-name> 1
```

**Rollback only reverts the Application's deployed revision pointer.**
It does NOT revert the Git source. Follow up with a Git revert PR so
the rollback survives the next sync.

```bash
git revert <bad-sha>           # in the gitops repo
git push origin main
argocd app sync <app-name>     # re-pin to the reverted state
```

For data migrations: rollback of the manifests does NOT roll back the
DB. Plan an explicit down-migration path (see
`references/migrations-patterns.md`).

## Namespace patterns

| Resource | Namespace |
|---|---|
| `Application` CR | `argocd` (always) |
| `ApplicationSet` | `argocd` |
| `AppProject` | `argocd` |
| Workload (Deployment, Job, Service) | per-env target namespace from `spec.destination.namespace` |

**Common bug:** putting the workload's `Namespace` resource inside the
Application's source tree but setting `spec.destination.namespace`
differently. Result: ArgoCD creates the workload in the destination
namespace while the `Namespace` resource lives in `argocd`. Always pin
`spec.destination.namespace` to the same value as the workloads it
contains.

## Common failure modes + fixes

| Symptom | Cause | Fix |
|---|---|---|
| `OutOfSync` permanent | Drift from a `kubectl apply` outside ArgoCD | `argocd app sync --prune` |
| `Degraded` after sync | Container CrashLoop / image pull fail | `kubectl logs` + `kubectl describe pod` in target ns |
| `Sync` hangs forever | PreSync hook Job stuck | Check the Job's pod logs; delete the Job + retry |
| `ComparisonError` | Manifest YAML invalid or refs missing CRD | `argocd app get <app> --show-managed-fields`; fix the YAML |
| Hook not running | Missing `argocd.argoproj.io/hook` annotation | Annotate + commit |
| `app sync` returns immediately "synced" but pods unchanged | Image tag pinned to a moving tag (`:latest`) and digest didn't change | Use immutable tags (`:v1.2.3` or `@sha256:...`) |

## Pre-flight gate (Phase 1)

```bash
# All apps for the target env must be Synced + Healthy
argocd app list -o wide | awk '$3 != "Synced" || $4 != "Healthy" {print}'
# Empty output = clean gate
```

If output is non-empty → stop pre-flight; investigate the offending
app before proceeding.

## Related

- `references/gitops-flux.md` — same role, Flux controller
- `references/migrations-patterns.md` — PreSync Job patterns
- `references/health-probes.md` — readyz / healthz semantics for the
  Healthy gate
