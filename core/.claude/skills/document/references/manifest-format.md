# Doc Output Manifest — `manifest.json` Schema

> Loaded by `/document` (any variant). The manifest is the
> reconciliation anchor — every generated output gets a row, every
> refresh consults the manifest to know what to regenerate.

## Why a manifest

Without it, `/document refresh` cannot tell:

- Which output files are generated vs hand-written.
- What tool + version produced each output (so regeneration is
  reproducible).
- Which source commit each output corresponds to (so drift is
  detectable).
- Whether an output is stale relative to its source.

The manifest is checked into Git alongside the generated docs.

## Location

```
docs/.manifest.json              # repo-wide manifest
docs/api/.manifest.json          # per-scope manifest (alternative)
docs/user-guide/.manifest.json
sdk/.manifest.json
```

Single repo-wide manifest is simpler; per-scope manifests scale better
when scopes have different refresh cadences. Pick one and stick to it.

## Schema (JSON Schema)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Doc Output Manifest",
  "type": "object",
  "required": ["version", "entries"],
  "additionalProperties": false,
  "properties": {
    "version": {
      "type": "string",
      "const": "1",
      "description": "Manifest schema version"
    },
    "generated_at": {
      "type": "string",
      "format": "date-time",
      "description": "When this manifest was last refreshed"
    },
    "entries": {
      "type": "array",
      "items": { "$ref": "#/definitions/Entry" }
    }
  },
  "definitions": {
    "Entry": {
      "type": "object",
      "required": ["scope", "source", "outputs", "generated_at"],
      "additionalProperties": false,
      "properties": {
        "scope": {
          "type": "string",
          "description": "Logical grouping: 'api', 'user-guide', 'sdk-ts', 'sdk-go', etc."
        },
        "source": {
          "type": "string",
          "description": "Source-of-truth path or URL (e.g. contracts/openapi/v1.yaml or https://app.example.com)"
        },
        "source_sha": {
          "type": "string",
          "description": "Git SHA of the source at generation time (omit for live-app sources)"
        },
        "outputs": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "object",
            "required": ["path", "tool"],
            "properties": {
              "path": {
                "type": "string",
                "description": "Repo-relative path of the generated file"
              },
              "tool": {
                "type": "string",
                "description": "Tool + pinned version, e.g. '@redocly/cli@1.16.0'"
              },
              "sha256": {
                "type": "string",
                "pattern": "^[a-f0-9]{64}$",
                "description": "Optional: SHA-256 of the output content (drift detection)"
              }
            }
          }
        },
        "generated_at": {
          "type": "string",
          "format": "date-time"
        },
        "published": {
          "type": "object",
          "description": "For SDK scopes — where the artifact was published",
          "properties": {
            "registry": { "type": "string", "enum": ["npm", "pypi", "maven", "go", "nuget", "rubygems", "internal"] },
            "package": { "type": "string" },
            "version": { "type": "string" }
          }
        }
      }
    }
  }
}
```

## Example manifest (small project)

```json
{
  "version": "1",
  "generated_at": "2026-05-22T10:30:00Z",
  "entries": [
    {
      "scope": "api",
      "source": "contracts/openapi/v1.yaml",
      "source_sha": "abc1234567890",
      "outputs": [
        { "path": "docs/api/v1.html", "tool": "@redocly/cli@1.16.0" },
        { "path": "docs/api/v1.md",   "tool": "widdershins@4.0.1" }
      ],
      "generated_at": "2026-05-22T10:25:00Z"
    },
    {
      "scope": "user-guide",
      "source": "https://app.example.com",
      "outputs": [
        { "path": "docs/user-guide/dashboard.md", "tool": "playwright@1.43.0" },
        { "path": "docs/user-guide/_shots/dashboard-en-light-1440.png", "tool": "playwright@1.43.0" }
      ],
      "generated_at": "2026-05-22T10:28:00Z"
    },
    {
      "scope": "sdk-ts",
      "source": "contracts/openapi/v1.yaml",
      "source_sha": "abc1234567890",
      "outputs": [
        { "path": "sdk/ts/src/index.ts", "tool": "openapi-generator-cli@7.4.0" }
      ],
      "generated_at": "2026-05-22T10:29:00Z",
      "published": {
        "registry": "npm",
        "package": "@myorg/api-sdk",
        "version": "1.1.0"
      }
    }
  ]
}
```

## How `/document refresh` uses the manifest

1. For each entry: check `source_sha` against the current Git HEAD of
   the source path.
2. If `source_sha` differs (or `source_sha` is absent for live-app
   sources), the entry is stale → regenerate.
3. After regeneration, update `generated_at`, `source_sha`, and
   `outputs[].sha256` (if used).
4. Commit the manifest with the regenerated outputs in the SAME
   commit. (Manifest must always match the outputs.)

## How `/document status` uses the manifest

```bash
# What scopes are documented?
jq '.entries[].scope' docs/.manifest.json | sort -u

# What's stale? (for git-tracked sources)
jq -r '.entries[] | select(.source_sha) | "\(.source) \(.source_sha)"' docs/.manifest.json | \
  while read source sha; do
    current_sha=$(git log -1 --format=%H -- "$source")
    if [ "$sha" != "$current_sha" ]; then
      echo "STALE: $source (manifest: $sha, current: $current_sha)"
    fi
  done
```

## Rules

- **Every generated output gets a manifest entry.** No orphans.
- **Hand-written docs do NOT appear in the manifest** — they're not
  generated.
- **The manifest is checked into Git.** It's part of the source of
  truth for "what we ship."
- **Refresh = regenerate the manifest + the outputs atomically.**
  A manifest pointing at an output that no longer exists is a bug.
- **Pin tool versions.** `@redocly/cli@1.x` is a smell — pin to
  `@redocly/cli@1.16.0` so refreshes are reproducible.

## Validation

Validate the manifest in CI:

```bash
npx ajv validate \
  --schema docs/.manifest.schema.json \
  --data docs/.manifest.json
```

Add a CI job that fails if:
- An entry's `outputs[].path` doesn't exist on disk.
- An on-disk generated file (header-detected) has no manifest entry.
- `source_sha` is absent for a git-tracked source.

## Migration from no-manifest

If your repo has generated docs but no manifest, bootstrap one:

```bash
# 1. Inventory generated files (look for AUTO-GENERATED headers)
find docs sdk -type f \( -name '*.md' -o -name '*.ts' -o -name '*.go' \) \
  | xargs grep -l 'AUTO-GENERATED\|DO NOT EDIT' 2>/dev/null > /tmp/generated-files

# 2. For each, identify the source-of-truth + tool (manual scan)
# 3. Author docs/.manifest.json from the inventory
# 4. Commit + add the CI validation
```

## Related

- `api-openapi.md` / `api-proto.md` / `user-guide-playwright.md` /
  `sdk-codegen.md` — each shows the manifest entry it produces
- `/document refresh` — consumes the manifest to decide what to
  regenerate
