# Hex Boundaries (non-negotiable)

Auto-loaded for every session in this repo. Applies to every Go service in {{PROJECT_NAME}}. Enforced by `make verify-isolation` (grep gate) + the `hexagonal-reviewer` agent on every PR.

## Layer graph (allowed import direction)

```
cmd/<service>/main.go      composition root (the sink; never imported)
  └─→ adapters/
        inbound/             driving adapters (HTTP, Kafka consumer, cron)
        outbound/            driven adapters (DB, cache, Kafka producer, HTTP client, object store)
  └─→ usecase/               orchestration over ports (no I/O, no HTTP framework)
        └─→ ports/
              inbound.go     interfaces that drive use-cases
              outbound.go    interfaces that use-cases drive
              └─→ domain/    pure types: entities, value objects, domain services
```

**Arrows go down only. Never up. Never sideways across siblings at the same level.**

## Forbidden imports (and why)

| Import | Reason | Failure mode if violated |
|---|---|---|
| `domain` → anything outside `domain` | Domain must be infrastructure-agnostic | Hard to test in isolation; changes to e.g. DB driver leak into business types |
| `ports` → `adapters` or `usecase` | Ports define interfaces consumed in both directions | Circular dep; can't mock for tests |
| `usecase` → `adapters/*` | Use-cases orchestrate via ports, not concrete drivers | Can't swap adapter; can't unit-test use-case without spinning up infra |
| `adapters/inbound/X` → `adapters/inbound/Y` | Adapters compose at the use-case layer, not at each other | Same as above, transitive |
| `adapters/inbound/*` → `adapters/outbound/*` (or vice versa) | Driving adapters never know about driven | Coupling that defeats the whole pattern |
| `cmd/*` imported from anywhere except `cmd/*_test.go` | The composition root is a sink | Tests of business logic shouldn't depend on the binary |
| `<service-A>` → `<service-B>` (cross-service) | Services communicate via Kafka or REST, not direct Go imports | Tight runtime coupling; can't deploy independently |

## Mechanisms

1. **Go package layout.** `internal/` is enforced by the toolchain — outside packages can't reach into `internal/*`. We further subdivide `internal/{domain,ports,usecase,adapters,config}` and ban cross-imports by convention.
2. **`make verify-isolation`** in every service's Makefile. A grep gate that fails on any forbidden import. Sample patterns:
   ```bash
   # adapter ↔ adapter forbidden
   grep -rE '<module-path>/internal/adapters/(inbound|outbound)/.+' internal/adapters/ \
     | grep -v "^internal/adapters/$1/" && exit 1
   # usecase importing adapters forbidden
   grep -rE '<module-path>/internal/adapters/' internal/usecase/ && exit 1
   # domain importing anything outside domain forbidden
   grep -rE '<module-path>/internal/(?!domain)' internal/domain/ && exit 1
   ```
3. **CI gate (reusable workflow).** A reusable `workflow_call` runs the submodule's `make verify-isolation`. Each service repo adopts it with a thin caller — until adopted everywhere, the rule is enforced locally + by the `hexagonal-reviewer` agent (gate 3 of the 6-gate review).
4. **`hexagonal-reviewer` agent.** Dispatched as part of the 6-gate post-delegation review per `docs/playbooks/post-delegation-review.md` — the human-review half of gate 3.

## When you need to share

| Situation | Where it goes |
|---|---|
| Cross-cutting infra primitive (Kafka client config, JWT verifier, DB tx helper) | `<shared-lib>/<package>/` |
| Domain type shared across two services (e.g., a reference ID) | `<shared-lib>/contracts/` (codegen from `contracts/events/*.json`) |
| A new adapter type used by 2+ services | Promote to `<shared-lib>/<adapter-kind>/` and import from there |
| A use-case shared across services | Don't. If you think you need this, the bounded context is wrong — discuss in a design doc first |

**Never** copy-paste code across services. **Never** add a "temporary" cross-import — `make verify-isolation` catches it and the review will block it.

## Why so strict

Two failure classes that flat / convention-only layouts suffer from, both eliminated by structure:

1. **Wire-encoding leaked into business types.** When the only resolver in the system directly uses a third-party API's field names, swapping to a second provider requires copy-paste. Hex puts the resolver in `usecase`, the wire encoding in `adapters/outbound/<provider>/`.
2. **Cross-track logic drift.** A "common" helper subtly tuned for one consumer changes another consumer's behavior. Both pass their own tests for weeks. Per-context isolation (bounded contexts) plus the hex layer rule is a structural defense, not a naming convention.

## Related

- `.claude/agents/hexagonal-reviewer.md` — authoritative reviewer
- `.claude/skills/hex-check/SKILL.md` — fast grep-only pre-commit check
- `.claude/rules/sub-agent-workflow.md` — `hexagonal-reviewer` is gate 3 of the 6-gate review
- `.claude/rules/brain-hot.md` — references this rule
