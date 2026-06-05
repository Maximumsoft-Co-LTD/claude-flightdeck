# Secrets — Sealed Secrets (Bitnami)

> Loaded by `/ship` Phase 1.4 when the project uses
> [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets) to
> commit encrypted secrets directly to Git.

## Topology

- The `sealed-secrets` controller runs in `kube-system` (or
  `sealed-secrets` namespace) and owns a private key (the "sealing"
  key).
- `kubeseal` CLI encrypts a `Secret` manifest using the controller's
  public key, producing a `SealedSecret` CR that's safe to commit.
- The controller decrypts `SealedSecret` → standard `Secret` on apply.
- The sealing key is auto-rotated every 30 days by default; old keys
  are retained for decrypting historical SealedSecrets.

## Encrypt a secret (kubeseal flow)

```bash
# 1. Make a plain Secret locally (do NOT commit this)
cat > /tmp/secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: staging
type: Opaque
stringData:
  DB_PASSWORD: "hunter2"
  API_KEY: "sk_live_abc123"
EOF

# 2. Seal it (produces a committable SealedSecret)
kubeseal --controller-namespace=kube-system \
         --controller-name=sealed-secrets \
         --format=yaml \
         < /tmp/secret.yaml \
         > deploy/staging/app-secrets-sealed.yaml

# 3. Delete the plain secret
shred -u /tmp/secret.yaml

# 4. Commit + push the SealedSecret
git add deploy/staging/app-secrets-sealed.yaml
git commit -m "chore(secrets): rotate API_KEY for staging"
git push
```

## Scope modes

`kubeseal --scope <mode>`:

| Scope | Re-deployable in different namespace? | Renamable? |
|---|---|---|
| `strict` (default) | ❌ | ❌ |
| `namespace-wide` | ❌ | ✅ |
| `cluster-wide` | ✅ | ✅ |

`strict` is the safest — re-encrypting is required for any rename or
namespace move. `cluster-wide` is convenient for shared platform
secrets but defeats per-namespace isolation. Default to `strict` unless
you have a documented reason.

## Key rotation

The controller generates a new sealing key every 30 days; old keys
remain in the controller's set so older SealedSecrets keep
decrypting.

```bash
# List the active keys
kubectl get secrets -n kube-system -l sealedsecrets.bitnami.com/sealing-key=active

# Force an immediate rotation (rare; for emergency)
kubectl -n kube-system delete pod -l name=sealed-secrets-controller
```

After rotation, **existing SealedSecrets keep working** (decrypted with
the old key). New seals use the new key. You do not need to re-seal
unless you intentionally invalidate a key (e.g. compromise).

## Re-seal everything

When you DO need to re-seal (key compromise, scope change, controller
rebuild from new keys):

```bash
# Fetch current decrypted values + re-seal with the new pubkey
for f in deploy/**/secrets/*-sealed.yaml; do
  ns=$(yq '.metadata.namespace' "$f")
  name=$(yq '.metadata.name' "$f")
  kubectl get secret "$name" -n "$ns" -o yaml \
    | kubeseal --format=yaml \
    > "$f.new"
  mv "$f.new" "$f"
done
git commit -am "chore(secrets): re-seal after key rotation"
```

⚠️ This requires you to have the live decrypted secrets in-cluster. If
you're rebuilding from a clean cluster (no live state) you need the
original plaintext values from a vault or a backup.

## Controller restart procedure

When the controller pod is unhealthy or you need to upgrade it:

```bash
# 1. Backup the sealing keys FIRST (this is the recovery anchor)
kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealing-key=active \
  -o yaml > sealed-secrets-backup-$(date +%F).yaml
# Store this somewhere safe (an actual secret vault, not the repo)

# 2. Restart / upgrade
kubectl rollout restart deployment/sealed-secrets-controller -n kube-system
# or: helm upgrade sealed-secrets sealed-secrets/sealed-secrets

# 3. Verify
kubectl logs -n kube-system deploy/sealed-secrets-controller | tail
# Look for: "HTTP server starting" + "controller version" + "loaded key"
```

## Recovery — controller rebuilt without backup

**This is the worst case.** New controller = new sealing keys = all
existing SealedSecrets become un-decryptable.

Steps:

1. Restore the backed-up key Secret to `kube-system` BEFORE deploying
   the new controller:
   ```bash
   kubectl apply -f sealed-secrets-backup-YYYY-MM-DD.yaml
   ```
2. Restart the controller; it will load the restored key alongside
   any new one.
3. If NO backup exists → you must:
   a. Get the plaintext values from a real secret vault (1Password,
      Vault, ops doc, etc).
   b. Re-seal all SealedSecrets with the new public key.
   c. Apply them; the controller will materialize new Kubernetes
      Secrets.
   d. Restart workloads that consume the secrets (rolling restart).

**Lesson:** always back up the sealing key when you stand up the
controller, and treat the backup as a tier-1 secret. Many teams script
the backup into CI/CD and store it in their primary secret vault.

## Pre-flight check (Phase 1.4)

```bash
# All SealedSecrets in scope should have status = Synced
kubectl get sealedsecret -n <target-ns>

# Resulting Secrets should exist
kubectl get secret -n <target-ns> -o name | grep app-secrets

# Controller healthy
kubectl get pods -n kube-system -l name=sealed-secrets-controller
```

Gate: every SealedSecret has materialized its target `Secret`.

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `cannot decrypt: no matching key` | SealedSecret encrypted under a different cluster's key | Re-seal from plaintext for this cluster |
| Secret materializes but is empty | `kubeseal` was run without `--format=yaml` against `stringData` keys (encoded incorrectly) | Re-seal from a fresh plaintext file |
| Pod doesn't pick up new value | Pod was already running when the Secret updated | Restart the workload (`kubectl rollout restart`) — sealed-secrets doesn't restart pods |
| Different namespace seals fail | `scope=strict` is enforcing namespace pinning | Re-seal targeting the right namespace, or use `--scope namespace-wide` |
| Controller logs `unable to fetch certificate` on `kubeseal` | `kubeseal` can't reach the controller (LB / port-forward broken) | Confirm `--controller-namespace` + `--controller-name` flags |

## Related

- `references/secrets-externalsecrets.md` — alternative for backend-
  managed secrets (Vault / AWS SM / etc.)
- Sealed Secrets docs: https://github.com/bitnami-labs/sealed-secrets
