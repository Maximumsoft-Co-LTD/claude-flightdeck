---
name: hex-check
description: "Verify hex import direction in one or more Go submodules. Wrapper around `make verify-isolation` per submodule + a grep-driven fallback if the Makefile target is missing. Use as a quick pre-commit check inside a subagent OR as gate 3 of `/post-delegation-gate`."
user_invocable: true
---

# /hex-check — hex boundary verifier

Fast local check that catches hex-rule violations BEFORE the `hexagonal-reviewer` agent runs. Cheap enough to run per-commit.

## Token budget (MANDATORY)

- Bash-only skill — no file Reads. Total token cost is the `make verify-isolation` (or grep fallback) output.
- If a service has 0 violations, output a single OK line; do not list every clean import.
- Limit violation reports to first 20 lines per service; cite file paths instead of full file contents.

## Invocation

```
/hex-check [<service> ...]
```

If no service is named, runs against every submodule with a `Makefile`.

## What it does

For each target submodule:

1. **Prefer the Makefile target** (if present):

   ```bash
   cd <submodule>
   make verify-isolation
   ```

2. **Fallback (no Makefile target yet)** — run these greps. Substitute `<module-path>` (your Go module path, e.g. `github.com/{{PROJECT_SLUG}}/<service>`) and `<other-services>` (sibling service module paths):

   ```bash
   MODULE="<module-path>"
   FAIL=0

   # 1) adapter → adapter (forbidden)
   if grep -rE "\"${MODULE}/internal/adapters/(inbound|outbound)/" internal/adapters/ \
        | grep -v "^internal/adapters/[^/]\+/[^/]\+\.go:\s*//"; then
     echo "FORBIDDEN: cross-adapter import detected"; FAIL=1
   fi

   # 2) usecase → adapter (forbidden)
   if grep -rE "\"${MODULE}/internal/adapters/" internal/usecase/; then
     echo "FORBIDDEN: usecase imports adapter"; FAIL=1
   fi

   # 3) domain → outside-domain (forbidden, except stdlib)
   if grep -rhE '^\t"' internal/domain/ \
        | grep -vE '"('"${MODULE}"'/internal/domain|context|errors|fmt|math|sort|strings|time|encoding/(json|hex)|crypto/(rand|sha256))"'; then
     echo "FORBIDDEN: domain imports outside domain"; FAIL=1
   fi

   # 4) cmd imported elsewhere (forbidden; except *_test.go)
   if grep -rE "\"${MODULE}/cmd/" \
        | grep -vE '_test\.go:' ; then
     echo "FORBIDDEN: cmd imported outside test"; FAIL=1
   fi

   # 5) cross-service Go import (forbidden — communicate via Kafka/REST or shared lib)
   if grep -rE "\"<org-prefix>/<other-service>/internal/" internal/ cmd/; then
     echo "FORBIDDEN: cross-service Go import"; FAIL=1
   fi

   exit $FAIL
   ```

3. **Report**

   ```
   <service-name>:
     Layer 1 (adapter→adapter):     ok / fail
     Layer 2 (usecase→adapter):     ok / fail
     Layer 3 (domain→outside):      ok / fail
     Layer 4 (cmd imported):        ok / fail
     Layer 5 (cross-service):       ok / fail
     Overall:                       HEX OK / VIOLATIONS
   ```

## Difference from the `hexagonal-reviewer` agent

| | `/hex-check` (this skill) | `hexagonal-reviewer` (subagent) |
|---|---|---|
| Speed | Fast (~5s per service) | Slow (~30s — full agent invocation) |
| Depth | Grep-only | Reads context, flags subtle issues |
| When | Pre-commit, every commit, every CI run | Gate 3 of post-delegation review (mandatory) |
| Output | Boolean per layer | Structured report with file:line + fix suggestions |

Both check the same layers. Use `/hex-check` for fast iteration; the `hexagonal-reviewer` agent is the authoritative gate before merge.

## Related

- `.claude/rules/hex-boundaries.md` — the rule
- `.claude/agents/hexagonal-reviewer.md` — the authoritative reviewer
- `/post-delegation-gate` — gate 3 dispatches the reviewer agent; gate 2 (build + test) often runs `/hex-check` as part of `make test` via a Makefile dependency
