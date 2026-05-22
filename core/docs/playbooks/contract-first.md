# Playbook — Contract-First for Cross-Service Changes (A003 / N3)

> Operator playbook. The deep-dive that [`CLAUDE.md`](../../CLAUDE.md) §N3 and [`.claude/rules/project-local.md`](../../.claude/rules/project-local.md) A003 point to. Execute it whenever a change touches an **inter-service interface**: an event / message shape or a REST / RPC API shape.
>
> **Core principle**: the contract is the single source of truth that both sides of the interface consume. **Contracts change first, in their own commit. Code follows contracts — never the reverse.**

## Why this exists

Drift across services is the failure this prevents. When a producer edits an event shape and the consumer follows informally, the two artifacts diverge silently — and because each service passes its own tests, the drift survives for weeks. A standalone contract commit makes the interface a reviewable, versioned, single artifact that downstream code is checked against.

## What counts as an "external surface" (triggers this playbook)

| Change | Contract artifact | Lives at |
|---|---|---|
| Event / message shape (new topic, new field, field rename, enum value) | JSON Schema (or your preferred IDL) | `contracts/events/<topic>.json` |
| REST / RPC API shape (new endpoint, request/response body, status codes) | OpenAPI / proto / equivalent | `contracts/openapi/<service>.yaml` |

A change **inside** a single service (a private use-case, an adapter implementation detail) is NOT an external surface — it does not trigger this playbook.

---

## Flow A — Event / message shape change

Mechanical, ordered. Each step is its own commit; the contract commit is **first and standalone**.

```bash
# 1. Edit the canonical schema FIRST (JSON Schema draft-07 — or your IDL).
#    contracts/events/<topic>.v1.json
#    (bump the version suffix .vN for a breaking change; new file for a new major.)

# 2. Commit it STANDALONE — nothing else in this commit.
git add contracts/events/<topic>.v1.json
git commit -m "contracts: <topic> v1 — <change> (A003)"

# 3. THEN port the language-specific mirror in the shared lib (separate commit):
#    shared/contracts/<topic>_v1.{ext}    (struct / class + enum consts)
#    shared/contracts/<topic>_v1_test.{ext}  (parity test — see Parity guard)
git -C shared add contracts/
git -C shared commit -m "contracts: mirror <topic> v1 (A003)"

# 4. Regenerate the cross-language shared-types from the canonical contract:
make codegen        # whichever generator you use (e.g. tygo, oapi-codegen, ts-rs)
#    commit the regenerated dist under the shared-types package.

# 5. THEN the consuming services (producer + consumers),
#    each in its own commit / PR, building against the now-stable contract.
```

**Commit order is the rule, not a suggestion**: contract → mirror → codegen → consumers. A reviewer who sees a consumer commit without a preceding contract commit blocks the PR (see [Pre-PR grep gate](#pre-pr-grep-gate)).

---

## Flow B — REST / RPC API change

```bash
# 1. Edit the API spec FIRST:
#    contracts/openapi/<service>.yaml

# 2. Commit it STANDALONE:
git add contracts/openapi/<service>.yaml
git commit -m "contracts: <service> openapi — <change> (A003)"

# 3. THEN implement the handlers in the service's inbound HTTP adapter,
#    in subsequent commits / its own PR.
```

---

## Pre-PR grep gate

Before opening a PR that touches a service's external surface, confirm a matching contract update exists. **Refuse to merge if missing** (this is Gate 5 of [`post-delegation-review.md`](post-delegation-review.md#gate-5--wiring)).

```bash
# Did this branch touch a service's external surface (producer/consumer, HTTP routes)?
git -C <service> diff main...HEAD --stat | grep -E 'kafka|http|routes|consumer|producer|grpc'

# If yes — confirm a contracts commit landed on the branch (and landed FIRST):
git log --oneline -- contracts/                 # meta-repo: was the contract committed?
git -C shared log --oneline -- contracts/       # was the language mirror updated?

# Confirm the codegen is in sync (no uncommitted drift after regenerating):
make codegen && git -C packages/shared-types status -s   # empty = in sync
```

**On gate failure** (external surface changed, no contract commit): STOP. Author the contract change first (Flow A or B), commit it standalone, then rebase the code commits on top. Do not merge code ahead of its contract.

---

## Parity guard

The parity guard is what keeps the **three representations** of a contract from drifting: the canonical schema, the language-specific mirror, and the generated cross-language types.

| Representation | Where | Guarded by |
|---|---|---|
| Canonical schema (source of truth) | `contracts/events/<topic>.v1.json` | source of truth |
| Language-specific mirror | `shared/contracts/<topic>_v1.{ext}` | a parity test that asserts the mirror against the canonical schema (or an embedded copy of the key-set, if the canonical file is outside the mirror's build context) |
| Generated types in other languages | `packages/shared-types/` | the codegen step + a literal-union drift guard |

**Known trade-off.** When the language mirror builds standalone (separate repo / submodule), its parity test usually asserts against an embedded copy of the key-set — not the canonical file directly — because the canonical file is outside the mirror's build root. The trade-off: if someone edits the canonical schema and the embedded expectations in the same commit but gets one wrong, the test can't catch the divergence from the canonical file. Mitigation: a meta-repo audit script that diffs all three sites (canonical ↔ mirror ↔ generated) from the full checkout.

Until that audit script lands: when you edit the canonical schema, update the embedded mirror expectations **in the same commit that updates the mirror**, and re-run codegen to keep generated types aligned.

---

## Copy-paste checklist

```text
Contract-first — <topic-or-service>  (event | REST)

[ ] 1. Edit canonical artifact FIRST    (contracts/events/<topic>.json  OR  contracts/openapi/<service>.yaml)
[ ] 2. Commit it STANDALONE             (message: "contracts: <topic/service> v<N> — <change> (A003)")
[ ] 3. Port language mirror             (shared/contracts/*.{ext}  +  update parity test in same commit)
[ ] 4. Regenerate codegen               (make codegen ; commit packages/shared-types ; status -s empty)
[ ] 5. Implement consumers / handlers   (separate commits / PRs, building against the stable contract)
[ ] Gate  Pre-PR grep: external surface touched ⇒ matching contract commit exists & landed first
```

## What to NEVER do

- Edit code before the contract — code follows contracts, never the reverse (A003).
- Bundle the contract change into the same commit as the code that consumes it (it must be standalone and first).
- Merge a PR that changed a service's external surface without a matching `contracts/` commit (pre-PR grep gate / Gate 5).
- Edit the canonical schema without updating the language mirror parity expectations + re-running codegen in lockstep.
- Embed provider-specific wire encoding in a contract — provider semantics live in the provider plane, the project integrates via a generic provider port (A002).

## Related

- [`../../CLAUDE.md`](../../CLAUDE.md) §N3 — the contract-first skeleton this expands.
- [`../../.claude/rules/project-local.md`](../../.claude/rules/project-local.md) A003 (contract-first), A002 (provider port).
- [`post-delegation-review.md`](post-delegation-review.md) Gate 5 — where the pre-PR contract check runs.
- [`parallel-conflict-prevention.md`](parallel-conflict-prevention.md) Layer 3 — land the contract commit before parallel producer/consumer agents.
