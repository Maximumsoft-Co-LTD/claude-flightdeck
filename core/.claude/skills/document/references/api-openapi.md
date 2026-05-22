# API Docs from OpenAPI

> Loaded by `/document` when the source-of-truth is one or more
> OpenAPI specs (`contracts/openapi/*.yaml`). Covers: rendering to
> Markdown / static HTML, embedding examples, version handling, and
> common pitfalls.

## When this reference applies

- The repo has `contracts/openapi/*.yaml` (or `*.json`).
- `/document api`, `/document <endpoint-group>`, or `/document` against
  a service whose contract is REST.

## Tool choice

| Tool | Output | Strength |
|---|---|---|
| `redoc-cli` | Single-file HTML (interactive) | Best for hosted docs (one file, no build step) |
| `redocly build-docs` | Same as redoc-cli, newer + maintained | Use this; redoc-cli is unmaintained |
| `swagger-codegen` | Multi-page HTML + clients | Use when you also want SDK generation |
| `widdershins` | Markdown (for Docusaurus / mkdocs) | Use when docs live alongside other markdown |
| `openapi-to-md` (or hand-format via `oasdiff`) | Plain Markdown | Use when you need terse contract-only docs |

For most projects in this template, the right default is:
**`@redocly/cli build-docs`** for hosted HTML + **`widdershins`** for
in-repo Markdown.

## Install + run

### Redocly (HTML)

```bash
npx @redocly/cli build-docs contracts/openapi/v1.yaml \
  --output docs/api/v1.html \
  --title "MyAPI v1"
```

### Widdershins (Markdown)

```bash
npx widdershins contracts/openapi/v1.yaml \
  --language_tabs 'shell:cURL' 'go:Go' 'typescript:TypeScript' \
  --summary \
  --omitHeader \
  -o docs/api/v1.md
```

## Embedding examples

Every operation in the OpenAPI spec should carry an `example` (per-field)
or `examples` (named) block. `widdershins` and Redocly both render
these prominently. Keep examples real (not placeholder) so the doc
becomes copy-pasteable curl.

```yaml
# In the OpenAPI spec
paths:
  /users:
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            examples:
              valid:
                summary: Valid request
                value:
                  email: alice@example.com
                  role: member
              invalidEmail:
                summary: Invalid email (returns 400)
                value:
                  email: not-an-email
                  role: member
```

## Version handling

For services that publish multiple major versions in parallel:

```
contracts/openapi/
├── v1.yaml          # current stable
├── v2.yaml          # next stable
└── v0.yaml          # deprecated, still served
```

Generate one doc page per version, named so users can link directly:

```bash
for v in v0 v1 v2; do
  npx @redocly/cli build-docs contracts/openapi/$v.yaml \
    --output docs/api/$v.html --title "MyAPI $v"
done
```

In the top-level docs index, list versions with status:

```markdown
- **[v2 (current)](./v2.html)** — recommended for new integrations
- [v1 (stable)](./v1.html) — supported through 2027-01
- [v0 (deprecated)](./v0.html) — sunset 2026-07
```

## Diff between versions

When promoting v1 → v2, generate a diff to inform the migration guide:

```bash
npx @redocly/cli diff contracts/openapi/v1.yaml contracts/openapi/v2.yaml \
  --format markdown > docs/api/migration-v1-to-v2.md
```

`oasdiff` is the more opinionated alternative:

```bash
oasdiff -base contracts/openapi/v1.yaml \
        -revision contracts/openapi/v2.yaml \
        -format markdown > docs/api/migration-v1-to-v2.md
```

Breaking changes (removed paths, narrowed types, required-flipped) get
flagged automatically. Use this output as the skeleton of the
migration guide — never write it from scratch.

## Validation BEFORE rendering

Always lint the spec first. A broken spec produces silent bad docs.

```bash
npx @redocly/cli lint contracts/openapi/v1.yaml
# Exit 0 = clean; non-zero = fix the spec
```

Add to CI as a gate. The render step should never run against an
unlinted spec.

## Code samples (`x-codeSamples`)

For hand-curated language samples in the docs (when the auto-generated
ones are wrong):

```yaml
paths:
  /users:
    post:
      x-codeSamples:
        - lang: curl
          label: cURL
          source: |
            curl -X POST https://api.example.com/users \
              -H "Authorization: Bearer $TOKEN" \
              -H "Content-Type: application/json" \
              -d '{"email":"alice@example.com","role":"member"}'
        - lang: go
          label: Go
          source: |
            client := myapi.NewClient(token)
            user, err := client.CreateUser(ctx, &myapi.CreateUserRequest{
              Email: "alice@example.com",
              Role:  myapi.RoleMember,
            })
```

Both Redocly and widdershins honor `x-codeSamples` and prefer them
over their own generators.

## Hand-edit forbidden

Generated HTML / Markdown lives under `docs/api/` and MUST carry a
header:

```html
<!--
  AUTO-GENERATED from contracts/openapi/v1.yaml
  Do not hand-edit. Run /document api v1 to regenerate.
-->
```

If you find yourself wanting to tweak the rendered file, the right
move is to:

1. Add the change to the OpenAPI spec (`description`, `example`,
   `x-codeSamples`, etc.).
2. Re-render.

## Manifest entry

After generating, update the doc index manifest (per
`manifest-format.md`):

```json
{
  "scope": "api",
  "source": "contracts/openapi/v1.yaml",
  "outputs": [
    {"path": "docs/api/v1.html", "tool": "@redocly/cli@1.x"},
    {"path": "docs/api/v1.md", "tool": "widdershins@4.x"}
  ],
  "generated_at": "2026-05-22T10:30:00Z",
  "source_sha": "<git SHA of the source file>"
}
```

## Common pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Examples don't match the schema | Doc shows a value that the API would 422 on | Lint with `--severity error` on schema/example mismatch |
| Inline schemas without `$ref` | Repeated definitions; rename one of them and they drift | Extract to `components.schemas` and `$ref` from each path |
| Missing operationId | Generated SDK methods get auto-named badly | Add `operationId: createUser` on every operation |
| `oneOf` without `discriminator` | Renders an unreadable union; clients can't deserialize | Add `discriminator.propertyName` |
| Server URL is `localhost` | Doc tells users to call `localhost` in prod | Set `servers:` to the real env URLs (one per env) |
| Auth scheme missing | Doc doesn't tell users how to authenticate | Define `components.securitySchemes` + `security` at the operation level |
| Tags inconsistent | Operations grouped under different headings | One tag set, applied to every operation; document the tag taxonomy in `info.description` |

## Related

- `api-proto.md` — sibling reference for gRPC / proto sources
- `sdk-codegen.md` — generating SDKs from the same OpenAPI spec
- `manifest-format.md` — the index manifest the auto-generator updates
