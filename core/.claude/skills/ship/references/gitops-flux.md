# GitOps with Flux — Reconcile, Suspend, Image Automation

> Loaded by `/deploy` Phase 3 when the project uses Flux v2 as its
> GitOps controller. Assumes `flux` CLI installed locally and a kube
> context pointing at the target cluster.

## Topology assumptions

- Flux v2 lives in `flux-system` namespace.
- `GitRepository` resources reference the gitops repo branch.
- `Kustomization` resources point at directories within that repo.
- `HelmRelease` resources drive Helm charts (optional).
- `ImageRepository` + `ImageUpdateAutomation` drive image automation
  (optional but common).

## Auth (in-cluster)

```bash
kubectl config use-context <target-cluster>
flux check                      # all controllers Healthy?
flux get sources git -A         # list GitRepositories
flux get kustomizations -A      # list Kustomizations
```

## Read app state (Phase 1.2 — pre-flight)

```bash
# Single Kustomization status
flux get kustomization <name> -n <namespace>
# READY   STATUS
# True    Applied revision: main/<sha>

# HelmRelease status
flux get helmrelease <name> -n <namespace>

# Drift detection
flux diff kustomization <name> --path ./clusters/staging
```

A clean pre-flight requires every `Kustomization` and `HelmRelease`
`READY=True` AND `Applied revision` matching the gitops repo's latest
`main`.

## Reconcile (Phase 3.2)

Flux reconciles on a schedule (default 10 min for GitRepository, 5 min
for Kustomization). For a deploy, force immediate reconciliation:

```bash
# Pull latest from Git
flux reconcile source git <git-repo-name> -n flux-system

# Apply the new revision
flux reconcile kustomization <ks-name> -n <namespace>

# Force a HelmRelease release
flux reconcile helmrelease <hr-name> -n <namespace>
```

`flux reconcile` blocks until the reconciliation completes or fails.
The `--with-source` flag chains source pull + apply:

```bash
flux reconcile kustomization <ks-name> --with-source
```

## Diff before apply

```bash
# Show what reconcile WILL apply
flux diff kustomization <ks-name> --path ./apps/<env>/<service>
```

If the diff surprises you — stop. Investigate the gitops repo before
forcing reconcile.

## Suspend / resume

When you need to pause Flux without uninstalling (e.g. emergency
manual fix, debugging drift):

```bash
flux suspend kustomization <ks-name> -n <namespace>
# ... do manual work ...
flux resume kustomization <ks-name> -n <namespace>
```

Suspended resources don't reconcile. Don't forget to resume — a forgotten
suspend is the #1 cause of "I deployed and nothing happened" in Flux
projects.

```bash
# List all suspended (sanity sweep before sign-off)
flux get all -A | grep -i suspended
```

## Image automation

Flux can auto-update image tags in Git when a new image is pushed
(via `ImageRepository` + `ImagePolicy` + `ImageUpdateAutomation`).

```bash
# What images is Flux tracking?
flux get image repository -A
flux get image policy -A

# Force a re-scan (manual trigger; usually scheduled)
flux reconcile image repository <name> -n <namespace>
flux reconcile image update <name> -n <namespace>
```

When image automation is on, Flux writes commits back to the gitops
repo (commits attributed to the configured `gitImplementation`'s git
identity). Pre-flight gate: confirm those commits land on a branch
auto-merged into `main`, not into a pending PR.

## Common failure modes + fixes

| Symptom | Cause | Fix |
|---|---|---|
| `READY=False` after reconcile | Manifest invalid or CRD missing | `kubectl describe kustomization <name>` for the error |
| `Stalled` for >2 reconcile cycles | Resource health-check probe failing | Inspect the workload — usually a pod crash, not a Flux problem |
| Reconcile loop never picks up new commits | `GitRepository.spec.interval` too long | `flux reconcile source git <name>` to force |
| HelmRelease stuck `upgrade in progress` | Previous release failed mid-way | `helm rollback <name> 0` then `flux reconcile helmrelease` |
| `ImageUpdateAutomation` not writing commits | SSH deploy key lacks write access | Check the secret + grant write |
| Drift between cluster and Git | Someone ran `kubectl apply` directly | Re-reconcile to revert; pin RBAC to forbid direct apply |

## Rollback

Flux rollback is "revert the Git commit, then reconcile":

```bash
git -C <gitops-repo> revert <bad-sha>
git -C <gitops-repo> push origin main
flux reconcile source git <git-repo-name> --with-source
```

For HelmRelease specifically, you can roll back the Helm release
directly (Flux will detect the drift and re-apply unless suspended):

```bash
flux suspend helmrelease <name> -n <namespace>
helm rollback <name> <previous-revision>
# fix the manifest in Git
git revert <bad-sha> && git push
flux resume helmrelease <name> -n <namespace>
```

For data migrations: same caveat as ArgoCD — manifests revert, DB
doesn't. See `references/migrations-patterns.md`.

## Pre-flight gate (Phase 1)

```bash
# All Kustomizations + HelmReleases must be READY=True
flux get kustomizations -A | awk 'NR>1 && $4 != "True" {print}'
flux get helmreleases -A    | awk 'NR>1 && $4 != "True" {print}'
# Empty output = clean gate
```

## Related

- `references/gitops-argocd.md` — same role, ArgoCD controller
- `references/migrations-patterns.md` — handling DB schema with Flux
- `references/health-probes.md` — what "Healthy" means for the gate
