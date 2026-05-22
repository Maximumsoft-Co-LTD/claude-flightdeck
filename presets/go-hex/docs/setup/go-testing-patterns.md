# Go Testing Patterns — {{PROJECT_NAME}}

> Canonical testing patterns for Go services in this repo. Every coding agent in the `go-hex` preset is expected to follow these patterns — see `.claude/agents/go-hexagonal-engineer.md`. The hex rule (`.claude/rules/hex-boundaries.md`) decides *where* a test lives; this doc decides *how* it's written.

## The three test tiers

| Tier | What it tests | Where it lives | Infra |
|---|---|---|---|
| **Unit** | A single use-case / function with mocked ports | next to the code (`internal/usecase/<verb>_test.go`) | none — pure Go |
| **Integration** | An adapter against real infrastructure | `tests/integration/<driver>/` | testcontainers-go: real Postgres / Redis / Kafka / object-store |
| **End-to-end / smoke** | A user-visible flow against the running service | `tests/e2e/` or external (Playwright if there's a UI) | full local stack (`make up`) |

Coding agents author tiers 1 and 2. Tier 3 is the smoke check in gate 6 of the 6-gate post-delegation review.

## Tier 1 — unit tests for use-cases

Use-cases consume `ports`. Mock the ports; run pure Go in memory.

### Table-driven tests

The canonical Go pattern. One test function, N rows, one `t.Run` per row.

```go
func TestRegisterOperator(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name       string
        input      domain.OperatorInput
        repoSetup  func(*mocks.OperatorRepo)
        wantErr    error
        wantResult domain.Operator
    }{
        {
            name:  "happy path",
            input: domain.OperatorInput{Email: "a@b.c"},
            repoSetup: func(r *mocks.OperatorRepo) {
                r.On("Save", mock.Anything, mock.Anything).Return(nil)
            },
            wantResult: domain.Operator{Email: "a@b.c"},
        },
        {
            name:  "duplicate email returns ErrConflict",
            input: domain.OperatorInput{Email: "a@b.c"},
            repoSetup: func(r *mocks.OperatorRepo) {
                r.On("Save", mock.Anything, mock.Anything).Return(domain.ErrConflict)
            },
            wantErr: domain.ErrConflict,
        },
    }

    for _, tc := range tests {
        tc := tc                      // capture range var (still required for some linters)
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()              // each row runs in parallel
            repo := mocks.NewOperatorRepo(t)
            tc.repoSetup(repo)
            uc := usecase.NewRegisterOperator(repo)

            got, err := uc.Run(context.Background(), tc.input)

            if tc.wantErr != nil {
                require.ErrorIs(t, err, tc.wantErr)
                return
            }
            require.NoError(t, err)
            require.Equal(t, tc.wantResult.Email, got.Email)
        })
    }
}
```

Rules:
- `t.Parallel()` at both the outer test AND each `t.Run` row — parallelism is opt-in per level.
- One row per behavior, not one row per condition. Aim for ≤7 rows; if you need more, split the test.
- Assert **outcomes**, not interactions. `mock.AssertExpectations` is a last resort. Prefer asserting the returned value or a state read back through another port.

### Behavioral, not structural

Don't test "the mock was called with X". Test "given input I, the use-case returns J". The mock is plumbing.

```go
// Bad: structural
repo.AssertCalled(t, "Save", mock.Anything, operator)

// Good: behavioral
saved, err := uc.Run(ctx, input)
require.NoError(t, err)
got, err := readBackUseCase.Run(ctx, saved.ID)
require.NoError(t, err)
require.Equal(t, input.Email, got.Email)
```

### Golden files for complex outputs

When the use-case returns a large, structured value (rendered template, generated SQL, marshaled event), commit a golden file and diff:

```go
//go:embed testdata/operator_event.golden.json
var operatorEventGolden []byte

func TestProduceOperatorEvent(t *testing.T) {
    t.Parallel()
    got, err := producer.Marshal(sampleOperator)
    require.NoError(t, err)

    if *updateGolden {                  // `go test -update` to regenerate
        require.NoError(t, os.WriteFile("testdata/operator_event.golden.json", got, 0644))
    }
    require.JSONEq(t, string(operatorEventGolden), string(got))
}
```

Always JSON-diff (`require.JSONEq`) for JSON, never byte-diff — formatting changes will create false failures.

## Tier 2 — integration tests with testcontainers-go

Adapters touch real infrastructure. Use [`testcontainers-go`](https://golang.testcontainers.org) to spin it up per test package.

### One container per package (`TestMain`)

```go
func TestMain(m *testing.M) {
    ctx := context.Background()
    pg, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        postgres.BasicWaitStrategies(),
    )
    if err != nil { log.Fatal(err) }
    defer pg.Terminate(ctx)

    dsn, err := pg.ConnectionString(ctx, "sslmode=disable")
    if err != nil { log.Fatal(err) }
    testDSN = dsn

    code := m.Run()
    os.Exit(code)
}
```

Don't spin a container per test — startup is 1-3s per container. Share via `TestMain` and isolate per-test with transactions / unique schemas.

### Per-test isolation

Wrap each test in a transaction that rolls back, OR create a unique schema per test and drop at teardown. Transaction rollback is faster:

```go
func withTx(t *testing.T, fn func(tx *sql.Tx)) {
    t.Helper()
    db := openTestDB(t)
    tx, err := db.BeginTx(context.Background(), nil)
    require.NoError(t, err)
    t.Cleanup(func() { _ = tx.Rollback() })
    fn(tx)
}
```

### Containers for the common stack

| Infra | Image | Wait strategy |
|---|---|---|
| Postgres | `postgres:16-alpine` | `postgres.BasicWaitStrategies()` (built-in) |
| Redis | `redis:7-alpine` | wait for `PONG` on port |
| Kafka | `confluentinc/confluent-local:7.6.0` or `testcontainers-go/modules/kafka` | wait for advertised listener |
| MinIO / S3 | `minio/minio:latest` | wait for `/minio/health/ready` |
| MongoDB | `mongo:7` | wait for replica-set ready if using transactions |
| ClickHouse | `clickhouse/clickhouse-server:24-alpine` | wait for `9000/tcp` listen |

### Round-trip tests for Kafka

```go
// produce → consume → assert
err := producer.Produce(ctx, event)
require.NoError(t, err)

msg, err := consumer.Read(ctx)        // with a 10s timeout per t.Deadline
require.NoError(t, err)
require.Equal(t, event.ID, msg.ID)
```

For idempotency, produce the same message twice and assert the consumer side-effect happens once.

## The race detector + `-count=1`

**Every** test run uses both:

```bash
go test -race -count=1 ./...
```

- `-race` catches data races. They're real bugs and they're cheap to detect.
- `-count=1` defeats Go's test-result cache. A test that passes today must pass today, not because Go remembers it passed yesterday.

The `Makefile` target wires both:

```makefile
.PHONY: test
test:
	go test -race -count=1 ./...
```

## Coverage

`go test -cover -coverprofile=coverage.out ./...` followed by `go tool cover -func=coverage.out`.

- New code target: ≥80% line coverage on the use-case + adapter you touched.
- Don't chase 100% — covering trivial getters is noise. Cover branches: error paths, edge inputs, idempotency.

## Parallelism

- `t.Parallel()` at every leaf test that doesn't share mutable state with siblings.
- Integration tests that share a container can still run in parallel IF each uses its own transaction / schema.
- Set `GOMAXPROCS` in CI to the runner's CPU count; locally, the default is fine.

## What NOT to do

- **No `time.Sleep`** in tests. If you're waiting for a goroutine, use a channel or `sync.WaitGroup`. If you're waiting for an external system, use a polling loop with a deadline.
- **No mocks for things you own.** Mock external ports (DB, broker, HTTP client). For your own use-cases / domain helpers, call the real thing.
- **No `init()` in test files** that mutates shared state — use `TestMain` so teardown is explicit.
- **No tests that pass when the implementation is wrong** — write the failing test first (TDD), confirm it fails for the right reason, then make it pass.

## Related

- `.claude/rules/hex-boundaries.md` — where tests live in the hex layout
- `.claude/agents/go-hexagonal-engineer.md` — invokes this doc when authoring code
- `docs/setup/lesson-trigger-map.md` — lesson-to-trigger map (e.g. "touching Kafka adapter → round-trip + idempotency test")
- `docs/playbooks/post-delegation-review.md` — gate 2 (build + test) runs `make test`
