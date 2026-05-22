# API Docs from Protobuf / gRPC

> Loaded by `/document` when the source-of-truth is `.proto` files
> (typically in `contracts/proto/`). Covers Buf flow, `protoc-gen-doc`,
> and the reflection fallback when proto sources are not available.

## When this reference applies

- The repo has `contracts/proto/**/*.proto` or `proto/**/*.proto`.
- `/document api`, `/document <service-name>` against a gRPC service.

## Buf flow (the modern default)

[Buf](https://buf.build) is the right toolchain for proto. It owns
linting, breaking-change detection, and code generation.

### `buf.yaml` + `buf.gen.yaml`

```yaml
# buf.yaml — at repo root
version: v2
modules:
  - path: contracts/proto
lint:
  use: [DEFAULT]
breaking:
  use: [WIRE]    # WIRE = wire-compatibility, the right default
```

```yaml
# buf.gen.yaml — at repo root (drives codegen + docs)
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: gen/go
    opt: paths=source_relative
  - remote: buf.build/grpc/go
    out: gen/go
    opt:
      - paths=source_relative
      - require_unimplemented_servers=false
  - remote: buf.build/community/pseudomuto-doc
    out: docs/api
    opt:
      - markdown,proto.md
```

### Generate

```bash
buf lint                       # gate first
buf format -w                  # auto-format the .proto
buf breaking --against ".git#branch=main"   # backward compat check
buf generate                   # codegen + docs in one step
```

The `buf.build/community/pseudomuto-doc` plugin is the canonical
proto → Markdown / HTML doc generator (a remote-hosted wrapper around
`protoc-gen-doc`).

## Protoc-gen-doc — direct (without Buf)

When the project predates Buf (or you can't use a remote plugin):

```bash
# Install
go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@latest

# Run via protoc
protoc \
  --doc_out=docs/api \
  --doc_opt=markdown,proto.md \
  --proto_path=contracts/proto \
  contracts/proto/**/*.proto
```

Output formats: `markdown,proto.md` | `html,proto.html` | `json,proto.json`.
For embedding into Docusaurus / mkdocs, prefer Markdown.

## Comments are the documentation

Proto-doc generators read leading comments. Treat them as the doc
source:

```proto
// UserService manages user CRUD operations.
//
// Authentication: every RPC requires a Bearer token in the
// `authorization` metadata key.
service UserService {
  // CreateUser creates a new user.
  //
  // Returns CREATED with the new user; ALREADY_EXISTS if the email
  // collides with an existing user.
  rpc CreateUser(CreateUserRequest) returns (User);
}

// CreateUserRequest is the input for UserService.CreateUser.
message CreateUserRequest {
  // email must be a valid RFC 5322 address.
  string email = 1;

  // role determines the user's permissions.
  Role role = 2;
}
```

Without leading comments, the generated doc is just signatures and is
useless. Every service, RPC, message, enum, and field gets a comment
or the doc is incomplete.

## Examples in proto docs

Proto doesn't have a first-class `example` annotation. Two patterns:

### Pattern A — examples in a separate Markdown

```
docs/api/
├── proto.md         # auto-generated reference
└── proto-examples.md # hand-curated examples per RPC
```

### Pattern B — examples in `// Example:` blocks

```proto
// CreateUser creates a new user.
//
// Example:
//   request:
//     email: "alice@example.com"
//     role: ROLE_MEMBER
//   response:
//     id: "usr_abc123"
//     email: "alice@example.com"
//     role: ROLE_MEMBER
//     created_at: "2026-05-22T10:00:00Z"
rpc CreateUser(CreateUserRequest) returns (User);
```

Pattern B keeps examples adjacent to the RPC; the doc generator
renders the comment block as-is in the output.

## Reflection fallback (proto source unavailable)

If you only have a running gRPC server (no `.proto` checked in):

```bash
# Confirm reflection is on
grpcurl -plaintext <host>:9090 list

# Dump the proto-equivalent IDL
grpcurl -plaintext <host>:9090 describe pkg.MyService > /tmp/myservice.proto-text
```

`grpcurl describe` emits a `proto-text` shape (close to but not
identical to `.proto` source). You can convert to real `.proto` via:

```bash
# protoreflect tools
protoc --include_imports \
  --descriptor_set_out=/tmp/desc.bin \
  --proto_path=... ...

# Or use buf to fetch a remote descriptor
buf build buf.build/<owner>/<repo> -o /tmp/desc.bin
```

The reflection path is documentation-of-last-resort: prefer to ship
real `.proto` sources to consumers.

## Versioning gRPC

gRPC versions live in the package name:

```proto
syntax = "proto3";

package myorg.user.v1;

service UserService { ... }
```

When breaking changes ship:

```proto
package myorg.user.v2;     // new package, parallel deploy

service UserService { ... }
```

Generate one doc page per package version. The migration guide is
hand-curated; `buf breaking` produces the change-set to feed it.

## Versioning + buf

`buf breaking --against ".git#branch=main"` is the canonical CI gate.
Run on every PR; refuse merges that introduce wire-incompatible
changes without an explicit `v2` package.

```yaml
# In your CI workflow
- run: buf breaking --against ".git#branch=main"
```

## Hand-edit forbidden

Same rule as OpenAPI docs: generated files carry a header,
hand-editing the spec is the only way to change the doc.

```markdown
<!--
  AUTO-GENERATED from contracts/proto/myorg/user/v1/*.proto
  Do not hand-edit. Run /document api proto-v1 to regenerate.
-->
```

## Manifest entry

```json
{
  "scope": "api",
  "source": "contracts/proto/myorg/user/v1/",
  "outputs": [
    {"path": "docs/api/proto-v1.md", "tool": "protoc-gen-doc@1.5.x"}
  ],
  "generated_at": "2026-05-22T10:30:00Z",
  "source_sha": "<git SHA covering all proto files in scope>"
}
```

## Common pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| No leading comments | Doc is just signatures, no prose | Comment every RPC + message + field |
| Field numbers reused after removal | Wire-incompatible — buf flags it | Reserve removed numbers: `reserved 3, 5;` |
| `enum` without `_UNSPECIFIED = 0` | Clients can't differentiate "missing" from "default" | Always start enums at `_UNSPECIFIED = 0` |
| Same `package` across multiple files | Doc generator merges them weirdly | One service per package is cleanest |
| Reflection disabled in prod | Doc-by-reflection path doesn't work | Reflection ON in non-prod; consider ON in prod too (it's metadata only) |
| Buf remote plugins blocked by firewall | `buf generate` fails | Use local `protoc` + locally-installed plugins (slower setup, no internet) |

## Related

- `api-openapi.md` — sibling reference for REST / OpenAPI sources
- `sdk-codegen.md` — generating gRPC client SDKs
- Buf docs: https://buf.build/docs
