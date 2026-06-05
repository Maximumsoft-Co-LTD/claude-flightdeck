# Health Probes — `readyz` vs `healthz` Semantics

> Loaded by `/ship` Phase 4. The two probes mean different things and
> the deploy gate depends on understanding the difference.

## The two probes — one-line semantics

- **`/healthz` (liveness)** — *Am I still able to process requests?*
  - `200`: keep me running.
  - non-200: kill me; Kubernetes will restart me.
  - **MUST NOT** depend on downstream services. If the DB is down,
    that's not your liveness problem — you're still alive; you just
    can't serve.

- **`/readyz` (readiness)** — *Am I ready to accept traffic?*
  - `200`: route traffic to me.
  - non-200: take me out of the load-balancer pool.
  - **SHOULD** depend on downstreams the request path needs (DB ping,
    cache reachable, migrations complete).

The classic bug: tying `/healthz` to the DB. The DB blips, every pod
fails liveness, every pod restarts, restart storm, cascading failure.
**Liveness only checks the process itself.** Readiness handles
dependents.

## Probe shape — minimum viable

```go
// healthz — process is alive, no dependents
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
})

// readyz — process is ready for traffic
http.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
    if err := pingDB(r.Context()); err != nil {
        http.Error(w, "db not ready", http.StatusServiceUnavailable)
        return
    }
    if !migrationsApplied.Load() {
        http.Error(w, "migrations pending", http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
})
```

## Pod spec — wire the probes

```yaml
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
      failureThreshold: 3       # 30s of failure → restart
    readinessProbe:
      httpGet:
        path: /readyz
        port: 8080
      initialDelaySeconds: 2
      periodSeconds: 5
      failureThreshold: 2       # 10s of failure → out of LB pool
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
      failureThreshold: 30      # 150s grace for slow boot
```

**Startup probe** is the unsung hero: lets a slow-starting app boot
without the liveness probe killing it during startup. Once
startupProbe passes, liveness + readiness take over.

## Dependent checks — what readyz SHOULD check

| Check | When to include | Example |
|---|---|---|
| DB ping | Service that reads/writes the DB | `SELECT 1` with 1s timeout |
| Migration state | Same DB; migrations gated on a runtime flag | `migrationsApplied.Load()` |
| Cache reachable | Hard dependency on cache | Redis PING with 200ms timeout |
| Upstream API auth refresh | Token-based auth that expires | Token TTL > 5m |
| Topic existence (Kafka) | Producer that requires the topic exists | Admin client describe-topic |
| Worker pool | Service that processes off a queue | Goroutine pool > 0 healthy |

**Avoid:** deep transitive checks (DB ready AND backend X ready AND
backend Y ready). One readiness check should be O(1) for your service.
Cascaded readiness creates flap-amplification across the cluster.

## Smoke-test matrix per stack

After Phase 3 (deploy completes), run a small matrix at the edge to
verify the new code is actually serving:

### HTTP / REST API stack

```bash
TARGET=https://<env-host>

# 1. Liveness — should always be 200 for a running pod
curl -fsS -o /dev/null -w "healthz: %{http_code}\n" $TARGET/healthz

# 2. Readiness — should be 200 once warmup completes
curl -fsS -o /dev/null -w "readyz:  %{http_code}\n" $TARGET/readyz

# 3. Unauthenticated → 401 (proves auth middleware mounted)
curl -fsS -o /dev/null -w "protected:  %{http_code}\n" $TARGET/api/me
# expect: 401

# 4. Version endpoint — proves the new SHA shipped
curl -fsS $TARGET/version
# expect: {"sha": "<expected-sha>", "built_at": "..."}

# 5. One golden-path endpoint with a known fixture
curl -fsS -H "Authorization: Bearer $TOKEN" $TARGET/api/health/detailed | jq
```

### Worker / async stack

```bash
# Probe the worker's own admin port
curl -fsS -o /dev/null -w "%{http_code}\n" http://<worker>:9090/healthz

# Verify it's consuming from its queue
kubectl exec deploy/<worker> -- /bin/sh -c \
  'curl -fsS localhost:9090/admin/queue-depth'
# expect: a number that's actively changing over time
```

### Frontend SPA stack

```bash
# Don't curl /; SPAs return the empty shell. Use Playwright or a
# headless browser to confirm the JS bundle hydrates.
playwright open https://<frontend-host>
# Or scripted: navigate + wait for #app element + assert no console errors

# Curl is OK for the bundle integrity:
curl -fsS -o /dev/null -w "%{http_code} %{size_download}\n" \
  https://<frontend-host>/static/js/main.<hash>.js
# expect: 200 + size matches the build artifact
```

### gRPC stack

```bash
grpcurl -plaintext <host>:9090 grpc.health.v1.Health/Check
# expect: {"status": "SERVING"}

# List services (reflection enabled?)
grpcurl -plaintext <host>:9090 list

# Probe a real RPC
grpcurl -plaintext -d '{"id": "test"}' <host>:9090 myapi.Service/Method
```

## Deploy-gate criteria

Gate Phase 4 PASS = all of:

- Every pod in scope `Ready: True`
- Every Deployment's `availableReplicas == replicas`
- HTTP `/healthz` returns 200 (or gRPC `Health/Check` SERVING)
- HTTP `/readyz` returns 200
- Protected endpoint returns the expected auth-error code
- `/version` (or equivalent) returns the just-deployed SHA
- One golden-path action succeeds end-to-end

```bash
# One-liner pod gate
kubectl get pods -n <ns> --field-selector=status.phase!=Running -o name
# Empty output = clean

kubectl get deploy -n <ns> -o json | jq '
  .items[]
  | select(.status.availableReplicas != .status.replicas)
  | "\(.metadata.name): \(.status.availableReplicas)/\(.status.replicas)"'
# Empty output = clean
```

Any failure → roll back (see `references/gitops-argocd.md` §Rollback
or `references/gitops-flux.md` §Rollback).

## Common probe mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| `/healthz` checks DB | Cascading restart storm during DB blip | Move DB check to `/readyz` only |
| `initialDelaySeconds: 0` on liveness | Pods killed before app boots | Use `startupProbe` OR a sane `initialDelaySeconds` |
| `/readyz` always returns 200 | Traffic routed to half-warm pods → 5xx spike | Add real dependency checks |
| `periodSeconds` too aggressive (1s) | API getting hammered by probes | 5-10s for readiness; 10-30s for liveness |
| Probe times out without explicit `timeoutSeconds` | Default 1s; long DB queries kill the pod | Set `timeoutSeconds: 3-5` for `/readyz` |
| `/healthz` returns 200 from a hung pod (deadlock) | Pod stays in pool forever | Add a "watchdog" goroutine that toggles a flag; healthz reads it |

## Related

- `references/gitops-argocd.md` — `Healthy` status depends on these
  probes
- `references/migrations-patterns.md` — migration-pending state must
  block `/readyz`
- Kubernetes probe docs:
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
