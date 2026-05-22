# SDK Code Generation — From Contract to Client

> Loaded by `/document export` (or `/document sdk`) when the goal is
> to emit client SDKs from the API contract. Covers tool selection per
> source-of-truth, per-language templates, and the publishing flow.

## When this reference applies

- The project ships an SDK to consumers (internal teams or external).
- A contract change must propagate to client code (TS, Go, Python,
  Java, etc.).
- `/document export ts | go | py | java`.

## Tool selection — by source-of-truth

| Source | Tool | Why |
|---|---|---|
| OpenAPI YAML/JSON | `@openapitools/openapi-generator-cli` | Multi-language, widely supported, generators for 50+ langs |
| OpenAPI (TS only, modern) | [Orval](https://orval.dev) | TS-native, hooks for TanStack Query, Zod schemas |
| OpenAPI (TS only, alt) | [swagger-typescript-api](https://github.com/acacode/swagger-typescript-api) | Faster than openapi-generator for TS, less framework opinion |
| Protobuf (any lang) | `buf generate` + remote plugins | Native gRPC support; first-class |
| GraphQL | `graphql-code-generator` | TS/JS focus, plugin ecosystem |

Default = **openapi-generator-cli** for multi-language uniformity,
**orval** when the consumer is exclusively TS + React Query.

## openapi-generator-cli (multi-language)

### Install + run

```bash
# Pin to a specific generator version — generators evolve, regressions happen
npx @openapitools/openapi-generator-cli@2.x version-manager set 7.4.0

# Generate TS (fetch-based)
npx @openapitools/openapi-generator-cli generate \
  -i contracts/openapi/v1.yaml \
  -g typescript-fetch \
  -o sdk/ts \
  --additional-properties=npmName=@myorg/api-sdk,supportsES6=true

# Generate Go
npx @openapitools/openapi-generator-cli generate \
  -i contracts/openapi/v1.yaml \
  -g go \
  -o sdk/go \
  --additional-properties=packageName=apisdk,packageVersion=1.0.0

# Generate Python (urllib3)
npx @openapitools/openapi-generator-cli generate \
  -i contracts/openapi/v1.yaml \
  -g python \
  -o sdk/python \
  --additional-properties=packageName=myorg_api_sdk,projectName=myorg-api-sdk

# Generate Java (OkHttp + Gson)
npx @openapitools/openapi-generator-cli generate \
  -i contracts/openapi/v1.yaml \
  -g java \
  -o sdk/java \
  --additional-properties=groupId=com.myorg,artifactId=api-sdk,library=okhttp-gson
```

### Per-language generator choice

| Language | Recommended generator | Notes |
|---|---|---|
| TypeScript | `typescript-fetch` | No deps; works in browser + Node |
| TypeScript (Axios) | `typescript-axios` | Use if you want interceptors / cancel tokens |
| Go | `go` | Single-file per resource; no deps |
| Python | `python` | urllib3 + pydantic v1 models |
| Python (modern) | `python-pydantic-v1` | Pin v1 or v2 deliberately |
| Java | `java` (library=okhttp-gson) | The okhttp-gson combo is most stable |
| Kotlin | `kotlin` | Coroutines if `useCoroutines=true` |
| Rust | `rust` | Async ready (`supportAsync=true`) |
| Swift | `swift5` | Combine if `useCombine=true` |

### Templates (when the default doesn't fit)

openapi-generator lets you override Mustache templates:

```bash
# Get the default templates to a local dir
npx openapi-generator-cli author template -g typescript-fetch -o templates/ts

# Edit templates/ts/apis.mustache (e.g. add custom auth interceptor)

# Use the overridden templates
npx openapi-generator-cli generate \
  -i contracts/openapi/v1.yaml -g typescript-fetch -o sdk/ts \
  -t templates/ts
```

Keep template overrides in the repo. The diff vs default templates is
your project's "what we changed" doc.

## Orval (TS-only, modern)

### `orval.config.ts`

```typescript
import { defineConfig } from 'orval';

export default defineConfig({
  api: {
    input: 'contracts/openapi/v1.yaml',
    output: {
      target: 'sdk/ts/src/index.ts',
      schemas: 'sdk/ts/src/schemas',
      client: 'react-query',         // TanStack Query hooks
      mode: 'tags-split',            // one file per OpenAPI tag
      mock: true,                    // generate MSW mocks too
      override: {
        mutator: {
          path: './src/api-client.ts',
          name: 'customInstance',     // user-provided fetch wrapper
        },
      },
    },
  },
});
```

```bash
npx orval
# emits sdk/ts/src/{api.ts, schemas/*.ts, mocks.ts}
```

Strengths over openapi-generator-cli:
- TanStack Query hooks out of the box.
- Zod runtime validation.
- MSW mocks for tests, generated from the same spec.

Weaknesses:
- TS only. If you need multi-lang, use openapi-generator.

## swagger-typescript-api (TS, minimal)

When you want lighter output than openapi-generator's TS:

```bash
npx swagger-typescript-api \
  -p contracts/openapi/v1.yaml \
  -o sdk/ts/src \
  --modular \
  --route-types \
  --client-type axios
```

Output is a thinner single-file API class — fewer wrappers, no
framework opinion.

## Protobuf SDK gen (Buf)

Already covered in `api-proto.md`; the same `buf generate` step that
produces docs also produces SDK code. Per-language plugin example:

```yaml
# buf.gen.yaml
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: sdk/go
  - remote: buf.build/grpc/go
    out: sdk/go
  - remote: buf.build/connectrpc/es
    out: sdk/ts/src
    opt: target=ts
  - remote: buf.build/protocolbuffers/python
    out: sdk/python
  - remote: buf.build/grpc/python
    out: sdk/python
```

`buf generate` produces all language outputs in a single run.

## Publishing flow

### TS — npm

```bash
cd sdk/ts
# 1. Build the JS + types
npm run build
# 2. Bump version (use the same semver bump as the contract)
npm version minor      # 1.0.0 → 1.1.0
# 3. Tag the repo
git tag sdk-ts-v1.1.0 && git push --tags
# 4. Publish
npm publish --access public
```

CI flow: on push to a tag matching `sdk-ts-v*`, run `npm publish` with
an automation token. Never publish from a dev machine in a steady-state
project.

### Go — module path (no registry)

Go modules are version-pinned by Git tag. No registry publish needed.

```bash
# Tag the SDK directory (assumes monorepo with sdk/go as module root)
git tag sdk/go/v1.1.0
git push origin sdk/go/v1.1.0

# Consumers fetch via:
go get github.com/myorg/myrepo/sdk/go@v1.1.0
```

For Go major versions ≥2, the module path includes `/v2`:
```
sdk/go/v2/   (with go.mod declaring `module github.com/myorg/.../sdk/go/v2`)
```

### Python — PyPI

```bash
cd sdk/python
# pyproject.toml manages metadata
python -m build              # creates dist/*.tar.gz + dist/*.whl
twine upload dist/*           # publishes to PyPI
```

For pre-release / internal: use TestPyPI or a private index.

### Java — Maven Central

```bash
cd sdk/java
./gradlew publish
# Configure publishing repo in build.gradle (Sonatype OSSRH for Maven Central)
```

Maven Central requires GPG-signed artifacts and a one-time
project-coordinate claim. For internal-only SDKs, use a Nexus / JFrog
repo and skip the Central path.

## Version-pinning the contract

The SDK version embeds the contract version it was generated from.
Set it at generation time:

```bash
# openapi-generator
--additional-properties=packageVersion=$(yq '.info.version' contracts/openapi/v1.yaml)

# Buf
# version comes from the proto package + git tag

# Orval
# version comes from the SDK's own package.json
```

The SDK's README states the contract version + commit SHA it was
generated from. Consumers can match their dependency to a contract
state.

## Hand-edit forbidden

The same rule as docs: every generated file carries a header noting
its source + tool + version:

```typescript
/* tslint:disable */
/* eslint-disable */
/**
 * MyAPI
 * Generated from contracts/openapi/v1.yaml (commit abc1234)
 * Tool: openapi-generator-cli@7.4.0 (typescript-fetch)
 * DO NOT EDIT BY HAND.
 */
```

If consumers need an extension (a custom retry policy, an interceptor),
they wrap the generated client in their own code — they do NOT edit
the generated file.

## Manifest entry

```json
{
  "scope": "sdk-ts",
  "source": "contracts/openapi/v1.yaml",
  "outputs": [
    {"path": "sdk/ts/src/index.ts", "tool": "openapi-generator-cli@7.4.0"}
  ],
  "generated_at": "2026-05-22T10:30:00Z",
  "source_sha": "<git SHA of the source>",
  "published": {
    "registry": "npm",
    "package": "@myorg/api-sdk",
    "version": "1.1.0"
  }
}
```

## Common pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Hand-edit a generated file | Regen wipes the edits; CI keeps re-applying them; flaky drift | Move the customization to a template override or a wrapper |
| Generator version unpinned | Today's generate diff is huge after `npm update` | Pin the version in `package.json` (or `buf.gen.yaml`) |
| OpenAPI `oneOf` without `discriminator` | TS SDK can't auto-narrow; runtime confusion | Add `discriminator` to the spec |
| Missing `operationId` | Methods named `usersIdGet` instead of `getUser` | Add `operationId` to every operation |
| Empty `tags` | Single file with hundreds of methods | Tag operations by domain; generators split per tag |
| SDK version drifts from contract | Consumer can't tell which contract their SDK speaks | Embed contract version in the SDK's README + `version()` method |

## Related

- `api-openapi.md` — the OpenAPI spec is the input to most SDKs here
- `api-proto.md` — proto-driven SDKs via Buf
- `manifest-format.md` — manifest spec for the doc/SDK index
