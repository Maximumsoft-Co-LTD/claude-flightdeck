---
name: deploy-preflight
description: "Read-only deployment pre-flight scan — repo state, secrets sync check, deploy-changes diff, migration verify locally. Reports what WOULD break a deploy without committing to one. Use when the user says '/deploy-preflight', 'check the deploy', 'what would deploy break', 'preflight', or wants to validate readiness before running /deploy."
user_invocable: true
---

# /deploy-preflight — Read-Only Deploy Risk Scan

The split-off of `/deploy` Phase 1. **No environment risk** — does not
sync, does not commit, does not mutate any cluster state. Outputs a
risk report so a human can decide whether to proceed to `/deploy`.

## When to run

- Before announcing a deploy slot to the team.
- After a sprint promotion, before bumping the meta submodule pointer.
- Any time you want a confidence check without holding the deploy
  slot.

Sister skill: `/deploy` (drives the full 5-phase orchestration).

## Token budget (MANDATORY)

- Pure read + Grep. No Write. No mutation.
- Reuses the same references as `/deploy` — load lazily as you
  encounter each sub-step.

## Input

`/deploy-preflight <environment>`

Environment is required (the secrets / cluster state differs per env).

## Variant router

Same routing as `/deploy` Phase 1. Load when you reach each sub-step:

| If the project uses... | Load before... |
|---|---|
| External Secrets Operator (ESO) | Step 4 — `../deploy/references/secrets-externalsecrets.md` |
| Sealed-secrets (Bitnami) | Step 4 — `../deploy/references/secrets-sealedsecrets.md` |
| Any DB schema change in scope | Step 5 — `../deploy/references/migrations-patterns.md` |
| Always (to know the smoke-gate criteria) | Step 6 — `../deploy/references/health-probes.md` |

## Steps

### 1. Confirm cluster context

```bash
kubectl config current-context     # is this the TARGET env?
```

If it's not the target environment, switch BEFORE continuing. The
pre-flight queries the live cluster.

### 2. Scan repo state

For each repo in the deployment scope:

```bash
git -C <repo> branch --show-current
git -C <repo> status -s
git -C <repo> fetch origin
git -C <repo> log --oneline origin/main..HEAD    # unpushed
git -C <repo> log --oneline HEAD..origin/main    # behind
```

Risk findings:
- Branch not `main` → BLOCKER
- Dirty working tree (anything but docs) → BLOCKER
- Unpushed commits → WARN (will not deploy)
- Behind origin → WARN (deploy will pull origin)

### 3. Read the deploy-changes file

```bash
ls docs/releases/deploy-changes-S<N>.md 2>/dev/null
```

If exists → Grep for the headings (`## New Secrets`, `## New
Migrations`, `## New ConfigMap`, `## New RBAC`). Each row drives a
follow-up scan in Step 4 / 5.

If missing → scan manually:
- `Grep '^[A-Z_]*=' .env` vs the secret manifests
- `git log --diff-filter=A --since="<last deploy>" -- migrations/`
- `Grep` for new `Role` / `ClusterRole` / `RoleBinding` manifests

### 4. Secrets sync check (per the variant reference)

For each declared secret in the deploy-changes file, verify:

- The backend has it (ESO) OR the SealedSecret YAML is committed.
- The target namespace has the resulting `Secret`.

Use the one-liner gates from the variant reference:

ESO:
```bash
kubectl get externalsecret -n <ns> -o json | \
  jq -r '.items[] | select(.status.conditions[]?.status != "True") |
         "\(.metadata.namespace)/\(.metadata.name)"'
# Empty output = clean
```

Sealed:
```bash
kubectl get sealedsecret -n <ns>
# All should have status: Synced
```

Findings: every non-synced or missing secret is a BLOCKER.

### 5. Migration verify (locally)

For each new migration in scope:

```bash
# Rehearse up + down + up locally against a fresh DB
<your migrate up>
<your migrate down 1>
<your migrate up>

# Schema-identical after up→down→up?
<your schema-dump command> > /tmp/before.sql
<your migrate up>
<your migrate down 1>
<your migrate up>
<your schema-dump command> > /tmp/after.sql
diff /tmp/before.sql /tmp/after.sql      # should be empty
```

Findings:
- `up` fails on fresh DB → BLOCKER
- `down` fails when `down` is supposed to work → BLOCKER (irreversible
  migrations need an explicit header note per
  `references/migrations-patterns.md` §When migrations cannot be
  reversed)
- Schema differs after up→down→up → BLOCKER

### 6. Deploy-changes diff (what WILL the GitOps controller apply)

GitOps diff WITHOUT applying:

```bash
# ArgoCD
argocd app diff <app-name> | head -200

# Flux
flux diff kustomization <name> --path ./apps/<env>/<service> | head -200
```

Read the diff. Anything unexpected is a WARN. A diff that includes a
`Deployment` image tag change without any code change in the source
repo is a BLOCKER (someone bumped manually).

### 7. Image / artifact existence check

For every Deployment in scope, confirm the image referenced actually
exists in the registry:

```bash
# Extract images from the gitops repo
grep -h "image:" deploy/<env>/**/*.yaml | sort -u

# Pull the manifest (no fetch of layers) to confirm existence
for img in $(grep -h "image:" deploy/<env>/**/*.yaml | awk '{print $2}'); do
  crane manifest "$img" >/dev/null 2>&1 && echo "OK   $img" || echo "MISS $img"
done
```

Any `MISS` is a BLOCKER.

### 8. Health-probe sanity check (current state)

Spot-check the current pods' probe configuration matches the gates in
`../deploy/references/health-probes.md`:

```bash
kubectl get deploy -n <ns> -o json | \
  jq -r '.items[] | "\(.metadata.name)
    liveness:  \(.spec.template.spec.containers[0].livenessProbe.httpGet.path)
    readiness: \(.spec.template.spec.containers[0].readinessProbe.httpGet.path)"'
```

If `liveness` is the same as `readiness` (both check downstreams) →
WARN about cascade-failure risk.

## Output — risk report

Print a single block summarizing all findings:

```
========== PRE-FLIGHT REPORT — <env> ==========
Generated: <YYYY-MM-DD HH:MM>
Cluster:   <context>
Scope:     <repos>

BLOCKERS (must fix before /deploy):
  • <finding 1>
  • <finding 2>

WARNINGS (review before /deploy):
  • <finding>

CLEAN:
  ✓ Repo state
  ✓ Secrets sync
  ✓ Migrations rehearsed
  ✓ GitOps diff reviewed
  ✓ Images exist

VERDICT: GO | NO-GO
NEXT:    [/deploy <env>] OR [fix BLOCKERS then re-run /deploy-preflight]
===============================================
```

## Rules

- **Read-only.** Do not run `argocd app sync`, `flux reconcile`,
  `kubectl apply`, or any state-mutating command.
- **No commits.** Do not auto-fix findings — surface them so a human
  decides.
- **Cluster context first.** A pre-flight against the wrong cluster
  is worse than no pre-flight.
- **Variant references are the depth.** Don't inline the per-tool
  details here; the deploy/references/*.md files own them.

## Related

- `/deploy` — the full orchestration (this is its Phase 1, carved out)
- `../deploy/references/gitops-argocd.md` — depth on ArgoCD checks
- `../deploy/references/gitops-flux.md` — depth on Flux checks
- `../deploy/references/secrets-externalsecrets.md` — ESO checks
- `../deploy/references/secrets-sealedsecrets.md` — sealed-secrets
  checks
- `../deploy/references/migrations-patterns.md` — migration rehearsal
- `../deploy/references/health-probes.md` — what a healthy probe set
  looks like
