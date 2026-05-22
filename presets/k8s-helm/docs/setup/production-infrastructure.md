# Production Infrastructure — {{PROJECT_NAME}}

> **Purpose:** record everything that exists in production so the team can maintain it without rediscovering. Update this doc every time you change production. The `k8s-engineer` agent reads it before touching production.

> **How to use the placeholders:** anything in `<angle-brackets>` is a value your installation customizes (cluster name, registry host, DNS zone). Replace with your real values when you adopt this doc; keep `{{PROJECT_NAME}}` rendered by the installer.

---

## 1. Domain & DNS

| Item | Value |
|------|-------|
| **Production URL** | `https://<prod-domain>` |
| **Staging URL** | `https://<staging-domain>` |
| **DNS provider** | <provider> (Cloudflare / Route 53 / etc.) |
| **SSL** | cert-manager + Let's Encrypt, OR provider-managed (e.g. Cloudflare proxy) |
| **DNS records** | `<env-subdomain>` → Ingress LB IP / CNAME |

To edit DNS: provider dashboard → DNS → records → update the A / CNAME for the relevant subdomain.

---

## 2. Cluster

| Item | Value |
|------|-------|
| **Provider** | <managed K8s service: GKE / EKS / AKS / self-hosted> |
| **Cluster name** | `<cluster-name>` |
| **Region / zone** | `<region>` |
| **Node pools** | `<pool-name>` (n2-standard-2 / m5.large / equivalent), min/max <n> |
| **Access** | `kubectl` via cluster credentials in CI + admin keys for ops |

```bash
# Connect (provider-specific; example shapes only)
gcloud container clusters get-credentials <cluster-name> --region=<region>
# OR
aws eks update-kubeconfig --name <cluster-name> --region=<region>
# OR
kubectl --kubeconfig=<path> get nodes
```

---

## 3. Managed databases

### Primary RDBMS

| Item | Value |
|------|-------|
| **Engine** | PostgreSQL <version> (or MySQL / MariaDB) |
| **Instance** | `<instance-name>` |
| **Tier / size** | `<tier>` (vCPU / RAM) |
| **Storage** | `<size>` (auto-increase enabled?) |
| **Network** | Private IP via VPC peering / Private Service Connect |
| **Database** | `<db-name>` |
| **App user** | `<app-user>` |
| **Backup** | auto daily + PITR <retention> days |
| **Maintenance window** | <day + time + timezone> |
| **Max connections** | <n> (matches backend pool config) |

```bash
# Status (provider-specific shape)
<cli> instances describe <instance> --format="value(state)"

# Connect for ops
<cli> connect <instance> --user=<app-user> --database=<db>

# Storage size
<cli> instances describe <instance> --format="value(settings.dataDiskSizeGb)"
```

### Cache / KV

In-cluster Redis (via Bitnami chart) OR managed (ElastiCache / Memorystore). One per environment.

### Object storage

In-cluster MinIO (via Bitnami chart) OR cloud-native (S3 / GCS / Azure Blob).

### Search / analytics

ClickHouse / OpenSearch / Typesense as needed.

### Messaging

Kafka / NATS / Pub-Sub / SQS — one cluster per environment, topics provisioned via IaC.

---

## 4. Namespace & resource policy

| Item | Value |
|------|-------|
| **Namespaces** | `<prod-ns>`, `<staging-ns>`, `<dev-ns>`, `<monitoring-ns>` |
| **ResourceQuota** | CPU <req>/<limit>, Memory <req>/<limit> per app namespace |
| **LimitRange** | Default per-container req / limit; max per container |
| **NetworkPolicy** | Deny ingress from non-app namespaces; allow ingress controller + monitoring scrape |

```bash
kubectl get all -n <prod-ns>
kubectl get resourcequota -n <prod-ns>
kubectl get limitrange -n <prod-ns>
kubectl get networkpolicy -n <prod-ns>
```

Files: `charts/<chart>/templates/resource-quota.yaml`, `limit-range.yaml`, `network-policy.yaml`.

---

## 5. GitOps (ArgoCD)

| Item | Value |
|------|-------|
| **ArgoCD URL** | `https://<argocd-domain>` |
| **Applications** | `<app>-dev`, `<app>-staging`, `<app>-prod` |
| **Sync policy** | dev / staging: auto-sync. Prod: **manual** sync. |
| **Values file** | `charts/<chart>/values/<env>.yaml` |
| **Source repo** | `git@github.com:<org>/<infra-repo>.git` |

```bash
# Status
argocd app get <app>-<env>

# Manual sync (prod)
argocd app sync <app>-prod

# Rollback
argocd app history <app>-prod
argocd app rollback <app>-prod <revision>

# Fallback if argocd login fails (K5 in k8s-engineer rules)
kubectl -n argocd patch application <app>-prod --type merge \
  -p '{"operation":{"sync":{"revision":"HEAD","syncStrategy":{"hook":{}}}}}'
```

File: `argocd/<env>/<app>.yaml`

---

## 6. Service replicas & resources

| Service | Replicas | HPA | CPU req / limit | Mem req / limit | Storage |
|---------|----------|-----|-----------------|------------------|---------|
| backend | <n> | <min>-<max> @ <cpu>% | <m> / <m> | <Mi> / <Gi> | — |
| frontend | <n> | — | default | default | — |
| <stateful-1> | <n> | — | <m> / <m> | <Mi> / <Gi> | <Gi> |
| <stateful-2> | <n> | — | default | default | <Gi> |

File: `charts/<chart>/values/<env>.yaml`

---

## 7. Secrets (External Secrets Operator)

Every secret lives in your secret manager (Vault / Cloud Secret Manager / SealedSecrets) and is synced into the cluster by External Secrets Operator. Naming: `<app>-<env>-<name>`.

| # | Secret name | Type | Source |
|---|-------------|------|--------|
| 1 | `<app>-<env>-database-url` | connection string | generated from managed-DB private IP |
| 2 | `<app>-<env>-db-password` | password | auto-generated (random) |
| 3 | `<app>-<env>-jwt-secret` | JWT signing key | auto-generated (random) |
| 4 | `<app>-<env>-cache-url` | connection string | in-cluster cache |
| 5 | `<app>-<env>-object-store-access-key` | credential | auto-generated |
| 6 | `<app>-<env>-object-store-secret-key` | credential | auto-generated |
| 7 | `<app>-<env>-oauth-client-id` | OAuth | provider-issued |
| 8 | `<app>-<env>-oauth-client-secret` | OAuth | provider-issued |
| ... | ... | ... | ... |

```bash
# List
<secret-cli> secrets list --filter="name:<app>-<env>"

# View
<secret-cli> secrets versions access latest --secret=<app>-<env>-jwt-secret

# Rotate
echo -n "<new-value>" | <secret-cli> secrets versions add <app>-<env>-<name> --data-file=-

# Verify ESO synced
kubectl -n <ns> get secret <name> -o jsonpath='{.metadata.annotations.reconcile\.external-secrets\.io/data-hash}'

# Force restart for pickup
kubectl -n <ns> rollout restart deploy/<name>
```

Template: `charts/<chart>/templates/external-secrets.yaml`

---

## 8. Error tracking

| Item | Value |
|------|-------|
| **Provider** | Sentry / Rollbar / Bugsnag |
| **Setup** | shared DSN with non-prod, separated by environment tag |
| **Environment tag** | `production` (via the appropriate env var) |
| **Traces sample rate** | <e.g. 0.2> in prod, <e.g. 1.0> in dev |

Filter production errors via the provider dashboard, filtered by environment tag.

---

## 9. Monitoring & alerting

### Alert pipeline (canonical shape)

```
Cluster metric / log / trace
  → alert source (Prometheus rule / Cloud Monitoring policy / Grafana alert)
    → notification channel (PagerDuty / Opsgenie / Slack / Telegram / email)
      → on-call rotation
  → email fallback for unacknowledged
```

### Alert policies (suggested baseline)

| # | Alert | Condition | Priority |
|---|-------|-----------|----------|
| 1 | Pod CrashLoopBackOff | restart_count > 3 / 5min | P0 |
| 2 | Backend 5xx spike | error log > 10/min for 2min | P0 |
| 3 | Health check fail | uptime check `/healthz` fail for 2min | P0 |
| 4 | High pod CPU | CPU > 80% for 10min | P1 |
| 5 | High pod memory | Memory > 85% for 5min | P1 |
| 6 | PVC disk > 80% | volume utilization > 80% for 5min | P1 |
| 7 | DB CPU > 80% | DB CPU > 80% for 15min | P1 |
| 8 | DB connections high | active connections approaching pool max | P1 |
| 9 | DB disk > 80% | DB disk > 80% for 5min | P2 |

### Uptime check

| Item | Value |
|------|-------|
| **URL** | `https://<prod-domain>/healthz` |
| **Interval** | 60s |
| **Timeout** | 10s |
| **Expected** | HTTP 2xx |

### Alert pipeline IAM check (K10 in k8s-engineer rules)

After wiring an alert, **test it with a synthetic event** matching the condition. IAM gaps on the notification path silently drop alerts; only an end-to-end test catches this.

---

## 10. Backup

### Managed DB

- **Method:** provider auto-backup + PITR
- **Schedule:** daily (provider-managed)
- **Retention:** <n> days
- **PITR:** continuous transaction log
- **Restore:** provider console → backups → restore (or `<cli> instances clone <instance> <restore-instance> --point-in-time=<RFC3339>`)

### Object storage

- **Method:** CronJob in the app namespace (e.g. `<store>-backup`)
- **Schedule:** daily off-peak (e.g. 02:00 ICT)
- **Destination:** off-cluster bucket (`<offsite-bucket>`)
- **Retention:** <n> days (cleanup in the CronJob script)
- **Template:** `charts/<chart>/templates/<store>-backup-cronjob.yaml`

### Verifying backups

```bash
# List
<storage-cli> ls <offsite-bucket>/<store>/

# Manual run
kubectl create job --from=cronjob/<store>-backup manual-backup -n <ns>

# Managed-DB backup list
<cli> backups list --instance=<instance>
```

---

## 11. Backend migrations (production-specific)

| Migration | Purpose | Safe re-run? |
|-----------|---------|--------------|
| `<NNN>_seed_default_config.up.sql` | Seed: admin user, default org, default workflow, templates, tags | Yes (`ON CONFLICT DO NOTHING`) |
| `<NNN>_cleanup_demo_data.up.sql` | Remove demo data (only tagged rows) | Yes (only deletes tagged) |

Seeded data summary — document the actual rows your seed migration inserts (admin email, default org name, default project key, workflow states + transitions, tags, etc.).

---

## 12. Helm values — key environment variables

File: `charts/<chart>/values/<env>.yaml`

| Env var | Value | Notes |
|---------|-------|-------|
| `FRONTEND_URL` | `https://<prod-domain>` | |
| `APP_BASE_URL` | `https://<prod-domain>` | |
| `<RUNTIME>_MODE` | `release` / `production` | No debug, no API explorer |
| `CORS_ALLOWED_ORIGINS` | `https://<prod-domain>` | |
| `<TRACER>_ENVIRONMENT` | `production` | |
| `<TRACER>_TRACES_SAMPLE_RATE` | `0.2` | 20% sampling |
| `<OBJECT_STORE>_PUBLIC_ENDPOINT` | `<prod-domain>` | |

---

## 13. Runbooks

Location: `docs/runbooks/`

| # | File | Trigger |
|---|------|---------|
| R01 | `R01-db-disk-full.md` | DB disk > 80% |
| R02 | `R02-object-store-disk-full.md` | Object-store PVC > 80% |
| R03 | `R03-cache-memory-full.md` | Cache memory > 85% |
| R04 | `R04-messaging-disk-full.md` | Messaging broker PVC > 80% |
| R05 | `R05-pod-crashloop.md` | Pod CrashLoopBackOff |
| R06 | `R06-backend-5xx-spike.md` | 5xx > 10/min |
| R07 | `R07-migration-failed.md` | Migration dirty / failed |
| R08 | `R08-ssl-cert-expired.md` | SSL cert issue |
| R09 | `R09-full-site-down.md` | Site unreachable |
| R10 | `R10-db-connection-exhaustion.md` | DB connections at pool max |
| R11 | `R11-rollback-deployment.md` | Manual rollback |

---

## 14. OAuth / SSO — redirect URI

When adding or changing a domain, update the OAuth provider's allowed redirect URIs:

1. Open the OAuth provider's console → Credentials
2. Edit the OAuth Client used by this app
3. Add Authorized redirect URI: `https://<prod-domain>/api/v1/auth/<provider>/callback`
4. Add Authorized JavaScript origin: `https://<prod-domain>`

**If you forget:** SSO login fails with `redirect_uri_mismatch`.

---

## 15. CI / CD — production release flow

```
1. Merge dev → main (PR with checklist)
2. Tag: git tag v1.x.x origin/main && git push origin v1.x.x
3. CI builds image: <registry>/<app>/<service>:v1.x.x
4. CI triggers repository_dispatch → infra repo receiver updates Helm values
5. ArgoCD manual sync → deploy to <prod-ns>
6. Argo Rollouts executes canary (10% → 30% → 100%) with health checks between steps
```

```bash
# Check CI status
gh run list --limit 5

# After CI pass, ArgoCD sync (manual)
argocd app sync <app>-prod
# OR fallback (K5)
kubectl patch application <app>-prod --type=merge \
  -p '{"operation":{"sync":{"revision":"HEAD","syncStrategy":{"hook":{}}}}}'

# Verify pods
kubectl get pods -n <prod-ns>
```

---

## 16. Key files reference

| File | Repo | Purpose |
|------|------|---------|
| `argocd/<env>/<app>.yaml` | infra | ArgoCD application (per env) |
| `charts/<chart>/values/<env>.yaml` | infra | All env-specific Helm overrides |
| `charts/<chart>/templates/resource-quota.yaml` | infra | ResourceQuota |
| `charts/<chart>/templates/limit-range.yaml` | infra | LimitRange |
| `charts/<chart>/templates/network-policy.yaml` | infra | NetworkPolicy |
| `charts/<chart>/templates/<store>-backup-cronjob.yaml` | infra | Off-cluster backup CronJob |
| `charts/<chart>/templates/external-secrets.yaml` | infra | ESO sync (pattern: `<app>-<env>-*`) |
| `migrations/<NNN>_seed_default_config.up.sql` | backend | Admin + config seed |
| `migrations/<NNN>_cleanup_demo_data.up.sql` | backend | Demo data cleanup |
| `docs/runbooks/R01-R11.md` | infra | Operational runbooks |
| `docs/setup/production-infrastructure.md` | infra | **This document** |

---

## Checklist for the next change

When you modify production infrastructure:

- [ ] Check the cluster context: `kubectl config view --minify | grep namespace` = `<prod-ns>`
- [ ] If editing Helm values → commit + push → ArgoCD manual sync
- [ ] If editing secrets → update via your secret manager (never commit secrets, K1)
- [ ] If adding a migration → test on staging first → then apply to prod
- [ ] If adding an alert → update this document section 9 + verify end-to-end (K10)
- [ ] If scaling up → update this document section 6
- [ ] After the change → update "Last Updated" date at the top of the document
