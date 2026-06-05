# Secrets — External Secrets Operator (ESO)

> Loaded by `/ship` Phase 1.4 when the project uses
> [external-secrets.io](https://external-secrets.io) to pull secrets
> from a backend (AWS Secrets Manager, Vault, GCP SM, Azure KV,
> 1Password, etc.).

## Topology

- `SecretStore` (namespaced) or `ClusterSecretStore` (cluster-wide)
  defines the connection to the secret backend.
- `ExternalSecret` (namespaced) declares which keys to pull and what
  Kubernetes `Secret` to materialize.
- The controller (`external-secrets`) reconciles `ExternalSecret` on
  `refreshInterval` and writes the resulting `Secret` into the same
  namespace.

## SecretStore shape (cluster-wide, AWS example)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

Auth options (pick one per project):
- `jwt` — IRSA / Workload Identity (the cleanest; no long-lived
  credentials in-cluster)
- `secretRef` — AccessKeyID + SecretAccessKey from a K8s Secret
  (avoid; rotates manually)

## ExternalSecret shape

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
  namespace: staging
spec:
  refreshInterval: 1h               # how often to re-pull
  secretStoreRef:
    name: aws-secrets
    kind: ClusterSecretStore
  target:
    name: app-secrets               # name of the materialized K8s Secret
    creationPolicy: Owner           # ESO owns the Secret (deletes on EOS deletion)
  data:
    - secretKey: DB_PASSWORD        # key inside the materialized Secret
      remoteRef:
        key: prod/myapp             # backend secret name
        property: db_password       # key inside the backend JSON blob
    - secretKey: API_KEY
      remoteRef:
        key: prod/myapp
        property: api_key
  # Or, pull the whole backend blob as keys (no per-key mapping)
  # dataFrom:
  #   - extract:
  #       key: prod/myapp
```

## Refresh interval — choose carefully

| Use case | Recommended `refreshInterval` |
|---|---|
| Rotating creds (DB password rotated by Vault) | `5m` — `15m` |
| Static API keys / build-time secrets | `1h` — `24h` |
| Bootstrap-only (TLS cert injected once) | `0` (disable polling; on-demand only) |

Too short = backend hammering + IAM throttling. Too long = rotated
credentials don't reach pods. Match the backend's actual rotation
cadence.

## Force refresh (no waiting for the interval)

```bash
# Delete the cached version annotation — ESO will re-pull on next reconcile
kubectl annotate externalsecret <name> -n <ns> \
  force-sync=$(date +%s) --overwrite

# Or just delete + recreate the resource via the gitops sync
```

## Masking strategies

ESO never logs secret values, but YOUR app might:

- Set `helm.sh/hook-delete-policy` on jobs that consume secrets so the
  Job's logs are cleaned post-run.
- Filter app logs in production — never `console.log(env)`.
- Use Vault's `transform` or AWS SM's masking annotations for
  display-only contexts.

For CI / build logs that need a secret value:

```yaml
# GitHub Actions example — mask before use
- run: echo "::add-mask::$VALUE"
  env:
    VALUE: ${{ secrets.MY_SECRET }}
```

## Pre-flight check (Phase 1.4)

```bash
# All ExternalSecrets in the target ns should be SYNCED
kubectl get externalsecret -n <target-ns>
# NAME           STORE        REFRESH-INTERVAL   STATUS         READY
# app-secrets    aws-secrets  1h                 SecretSynced   True

# If any READY != True:
kubectl describe externalsecret <name> -n <target-ns>
# Look at Events for the actual error
```

Gate: every ExternalSecret in scope shows `READY=True`. Any non-True
blocks the deploy.

```bash
# One-liner for the gate
kubectl get externalsecret -A -o json | \
  jq -r '.items[] | select(.status.conditions[]?.status != "True") |
         "\(.metadata.namespace)/\(.metadata.name)"'
# Empty output = clean
```

## Common failure modes

### 1. `InvalidStore` — backend unreachable

```
status.conditions:
  reason: InvalidStore
  message: could not get provider: ...
```

**Cause:** Missing IAM permissions on the IRSA ServiceAccount, wrong
region, or backend endpoint blocked by network policy.

**Fix:**
- Verify the ServiceAccount annotation matches an IAM role with
  `secretsmanager:GetSecretValue` (AWS) or equivalent.
- `kubectl exec` into a pod with the same SA and curl the backend
  endpoint.

### 2. `SecretSyncedError` — key not found

```
reason: SecretSyncedError
message: secret "prod/myapp" not found
```

**Cause:** Secret was created in dev/staging backend but not promoted
to prod, or typo in `remoteRef.key`.

**Fix:**
- `aws secretsmanager describe-secret --secret-id prod/myapp` (or
  equivalent for your backend) to confirm existence.
- Promote / create the missing secret in the backend; ESO will pick it
  up on the next interval.

### 3. Missing target namespace

```
Error: namespaces "staging" not found
```

**Cause:** The ExternalSecret references a target namespace that
doesn't exist yet. Common during fresh environment bootstrap.

**Fix:** create the namespace BEFORE applying ExternalSecrets; pin the
order via ArgoCD sync-wave or Flux `dependsOn`.

### 4. Stale Secret after backend rotation

**Cause:** `refreshInterval` is too long for the rotation cadence, OR
the controller pod is unhealthy.

**Fix:**
- Force refresh via the annotation above.
- Check the controller: `kubectl logs -n external-secrets
  deploy/external-secrets`.

### 5. Race with pods (Secret created after pod starts)

**Cause:** Pods read env vars from the Secret at start time. If the
Secret didn't exist yet, pods crash-loop until it appears.

**Fix:**
- Add `dependsOn` (Flux) or sync-wave (ArgoCD) so ExternalSecret
  reconciles BEFORE the Deployment rolls out.
- For runtime updates without restart, mount via projected volume +
  use a reload-on-change sidecar (e.g.
  [reloader](https://github.com/stakater/Reloader)).

## Restart pods on Secret change

The Secret value updates, but pods don't see it until restarted.
Options:

- **Stakater Reloader** — annotate the Deployment with
  `secret.reloader.stakater.com/reload: "app-secrets"`. Reloader does
  a rolling restart on Secret change.
- **Manual** — `kubectl rollout restart deployment/<name>` after a
  rotation.

## Related

- `references/secrets-sealedsecrets.md` — the alternative for projects
  that prefer Git-committed encrypted secrets
- ESO docs: https://external-secrets.io
- For backend-specific bootstrap (Vault auth method, AWS IAM role
  setup, etc.), see your project's `docs/setup/secrets-backend.md`
