# Lesson Trigger Map

> Mechanical mapping of "if touching X → apply rule Y". Every specialized agent reads this file as part of [`.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md) Step 2.
>
> Two rule namespaces:
> - **A###** = project-local rules ([`.claude/rules/project-local.md`](../../.claude/rules/project-local.md)) — define per project, A001-A0NN
> - **L###** = battle-tested cross-project lessons (auto-loaded via `.claude/rules/brain-hot.md` for the highest-leverage ones)

## How to use this map

When you plan a task that touches a path or pattern listed below, you MUST mentally tag the corresponding rule and apply it. Output an `## Applied Rules` section in your task summary listing the rules you applied (verbatim IDs).

If you skip an applicable rule, the post-delegation review (Gate 4) catches it. Skipping = rework.

---

## Backend service code (your server-side codebase)

| If touching | Apply rule |
|---|---|
| Domain layer (pure types, business invariants) | **A001** (architecture boundary) — domain imports nothing outside domain |
| Ports / interfaces (consumed by both adapters and use-cases) | **A001** — interface lives here, implementation elsewhere |
| Use-cases / application layer | **A001** — use-cases import only ports + domain. **A007** (audit trail for mutations). **A008** (observability — span / metric / log). |
| Inbound adapters (HTTP / RPC / gRPC handlers) | **A001** — never import another adapter or another service. **A005** (idempotency key for write endpoints). **A008** (request span middleware). **A009** (RBAC middleware). |
| Inbound message consumers | **A001** — propagate trace context from message headers; consumer group named per service |
| Outbound adapters (DB / cache / external API) | **A001** — never read framework context keys directly; use a typed helper. **A004** (idempotent migration). |
| Message producers | **A001**. **A003** (contract-first — contract file must already be committed). |
| Cache / session layer | **A001**. **A010** (idempotency key retention / TTL pattern). |
| External provider adapters | **A001**. **A002** — only via the generic provider port; never embed provider-specific wire details in shared code. |
| Composition root (`main`, `app`, bootstrap) | **L116** (post-delegation wiring — verify every new use-case / adapter is wired). |
| Migrations | **A004** — idempotent (`IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`). Application bootstrap auto-applies before serving traffic. **L227** (auto-apply on bootstrap; snapshots are not a migration story). |
| Service / project build file | Include an isolation / boundary check target (grep gate for A001). |
| Container build | Multi-stage build. Minimal final stage. Reproducible. |
| Any test file | Use the project's standard assertion lib. Use real backends (testcontainers / docker-compose) for integration tests. **L006** (stale binary — always build to a unique path + kill stale processes before re-running). |

## Frontend code (your client codebase)

| If touching | Apply rule |
|---|---|
| Top-level pages / routes | Layer rule — top-down only (e.g., pages → widgets → features → entities → shared). |
| Composite widgets / blocks | Layer rule — import from features / entities / shared. Not from peer widgets. |
| Feature slice | Layer rule — vertical slice. Internal `{ui, model, api, lib}` only. Cross-feature import forbidden. |
| Entity slice (domain types + their UI) | Layer rule — import from shared only. |
| Shared layer (leaves) | Layer rule — no imports from other layers. |
| Any user-facing string | **A006** — use the t() / translate() helper everywhere. No hardcoded text. |
| i18n locale files | Add to BOTH (all) language files. Escape any special chars per your i18n lib. **L066** (e.g. next-intl needs `{'@'}` to literal-escape `@`). |
| API client wrappers | Use the centralized `apiPost / apiGet` (or equivalent). No raw `fetch` in features / widgets — keeps auth refresh + error envelope in one place. **L065** (never re-add BASE_URL on top of the wrapper). |
| Menu / nav config | Adding a menu item requires 3 places: menu config, layout protected-routes path, i18n key. **L073**. |
| Backend response with empty list | **A006** + **L067** — backend may return `null` for empty lists; frontend MUST `?? []` before iteration. **L074** (null guard on `= response.data` assignments — not just on `.map()`). |
| New role gate / RBAC component | **A009** — protected-route wrapper around the layout / page. |
| Any test file | Mirror the source structure in `__tests__/`. Mock the API layer, not the model layer. |
| Any browser E2E test | Use stable selectors. **L228** (avoid non-waiting visibility checks — use proper wait conditions). **L229** (avoid brittle text-substring scopes — scope to row testids). |
| Role names in code | **L025** — MUST match backend DB; runtime-verify (e.g. `curl /auth/me`). |
| App layout | **L029** — Layout in `App.tsx` / `app/layout.tsx` only; pages must NOT import Layout components. |
| `= response.data` assignments | **L074** — null guard required, not just on `.map()`. |

## Cross-service contracts

| If touching | Apply rule |
|---|---|
| Event / message schemas (`contracts/events/*.json`) | **A003** contract-first — commit standalone before downstream code. Versioned filename: `<topic>.v<N>.json`. |
| REST / OpenAPI specs (`contracts/openapi/*.yaml`) | **A003** — commit standalone. Generated client types regenerate from this. |
| Generated shared-types package | Never edit by hand. A `make codegen` (or equivalent) regenerates from `contracts/`. |
| New event topic / queue | Must appear in the bootstrap / init script. Must have a contract file. Must have ownership documented (who produces, who consumes). **L117** (producer-side struct MUST match the contract — diff fields post-delegation). |
| External provider integration | **A002** — only via the project's provider port + adapter. Never direct DB / shared-store read on the provider plane. |

## Sprint workflow

| If touching | Apply rule |
|---|---|
| `docs/spec/STATUS.md` track row | REPLACE, do not append. Move prior prose to `STATUS-archive.md` in the same commit. |
| `docs/spec/backlog.md` task row | Change status `[ ] → [~] → [x]` with date. **L087** — update backlog immediately after task close, not deferred. Never delete; never re-order without bumping a "last updated" line. |
| New sprint file `docs/spec/sprints/sprint-S<N>.md` | Use `docs/designs/_templates/` (BACKLOG_ENTRY_TEMPLATE adapted for sprint). Update `backlog-index.md`. |
| New task design doc `docs/designs/sprint-S<N>/D<NNN>-<slug>.md` | Use `docs/designs/_templates/DESIGN_TEMPLATE.md`. Must declare touched-files matrix, acceptance criteria, applicable rules. **L076** — if < 500 lines and task is non-trivial, emit "under-specified" warning. |
| Closing a sprint | Author retro at `docs/spec/retros/sprint-S<N>.md`. Move sprint file pointer to STATUS-archive. **L186** (single-day burndown — capture if applicable). |
| Adding a new rule | Author in `.claude/rules/project-local.md` (A###). Reference from this file. Mention in the next sprint retro. |

## Observability

| If touching | Apply rule |
|---|---|
| Any new handler / use-case | **A008** — wrap in a span (`tracer.Start(ctx, "<verb>.<noun>")`). |
| Any new long-running worker | **A008** — emit `<service>_alive` heartbeat metric (e.g., every 30 s). |
| Any new message consumer | **A008** — emit consumer-lag gauge. Subscribe via a stable consumer group (NOT auto-generated ID). |
| Any new error path | Capture to your error tracker (don't swallow into a log line alone). |
| Any new dashboard | Author at the canonical observability path; update the dashboard index doc. |

## Multi-repo / submodule

| If touching | Apply rule |
|---|---|
| Submodule code | Always commit + push in the SUBMODULE'S OWN git, never via meta-repo edits. **L114** — use `git -C <submodule>` (never `cd <dir>` for git). |
| `.gitmodules` | The meta-repo bumps submodule pointers via `git add <submodule>` + commit. Pointer-bump commit message: `deps: bump <submodule> to <description>`. **L141** — verify the submodule branch is mergeable before bumping. |
| Any cross-service shared import | **A001** — FORBIDDEN. Use the message bus or REST through the shared lib. |
| Sub-agent invocation | **A011** — use the `Agent` tool from the main session. NEVER `claude -p` (L169 / L256 deprecated). |
| `cd <dir>` for git operations | **L114** — FORBIDDEN. Use `git -C <dir>` instead. |

## Code review (mandatory gates)

| Gate | Trigger | Action |
|---|---|---|
| Gate 1 — Inspect | After every coding subagent returns | `git diff --stat` + `git diff <files>`. Read the actual diff. |
| Gate 2 — Build + Test | After every coding subagent returns | The project's build + test command in touched modules. |
| Gate 3 — Boundary | After every coding subagent returns | **Preset-specific** — if the project has a `go-hex` preset installed, dispatch `hexagonal-reviewer`; if `nextjs-fsd`, run FSD lint; if `vue-pinia`, run the appropriate boundary check. See `.claude/rules/project-local.md` for the project's specific Gate 3. |
| Gate 4 — Quality (parallel) | After every coding subagent returns | Dispatch `pr-review-toolkit:{code-reviewer, silent-failure-hunter, type-design-analyzer}` + `:pr-test-analyzer` if tests touched + `:comment-analyzer` if comments touched. |
| Gate 5 — Wiring | After every coding subagent returns | Grep composition root for new code usage. Verify migrations applied, observability emits, message topic created, contracts updated. |
| Gate 6 — Integration smoke | After every coding subagent returns | Local stack up + smoke (and browser e2e if frontend touched). |

Per [`.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §4. Skipping = production bugs.

## L### lesson reference (the highest-leverage subset)

Full lesson detail lives in your brain / MemPalace / per-project rules; only IDs surfaced here.

| ID | Pitfall | Trigger / where applicable |
|---|---|---|
| L002 | Framework context keys read directly | Wrap in a typed helper |
| L004 | Seed data missing FK relationships | Migration / fixture authoring |
| L006 | Stale binary cached → tests pass against old code | After build — always build to a unique path + kill stale processes |
| L007 | Duplicate request → duplicate write | A005 / A010 — idempotency key |
| L025 | Frontend role names diverge from backend DB | Runtime-verify (e.g. `curl /auth/me`) |
| L029 | Layout imported from pages → double-render | Layout in `app/layout.tsx` only |
| L037 | Hardcoded user-facing strings | A006-extension; use t() everywhere |
| L050 | RBAC route forgets the policy seed | A009 — verify policy seeded |
| L064 | DB table-name typo in JOIN | Pre-flight schema check |
| L065 | Services re-added BASE_URL on top of the wrapper | Use the centralized api wrapper |
| L066 | i18n special-char in values | Escape per your i18n lib |
| L067 | Backend `null` for empty list crashes `.map()` | A006; frontend `?? []` |
| L073 | Menu item missing one of 3 places | menu config + layout paths + i18n |
| L074 | `= response.data` null crash | Guard on assignment, not just on `.map()` |
| L076 | Task design under 500 lines = under-specified | Pre-task ritual emits warning |
| L087 | Backlog not updated immediately after task close | Update inline, not deferred |
| L089 | Permission migration INSERT duplicated | Grep existing migrations first |
| L091 | Nullable column with no default | Provide explicit default at write site |
| L100 | snake_case → camelCase mapping with raw fetch | Use the centralized api wrapper |
| L101 | Fix from code-reading alone fails | Reproduce first |
| L114 | `cd <dir>` for git breaks parallel agents | Always `git -C <dir>` |
| L116 | Post-delegation: composition root not wired | Gate 5 verifies |
| L117 | Producer-side struct mismatched with contract | Diff fields post-delegation |
| L127 | Config lib missing `SetDefault` / `BindEnv` | Both required even with auto-env binding |
| L141 | Submodule SHA bump without verifying mergeable | Always check sub-repo state before bumping |
| L147 | LSP-first for semantic queries; grep only for text | A013 / `.claude/rules/lsp-first.md` |
| L153 | `/clear` between skill invocations to avoid pollution | Token hygiene |
| L154 | Index-first for sprint/backlog/design-doc creation | See `index-discipline.md` |
| L169 / L256 | `claude -p` is deprecated → use Agent tool | A011 |
| L186 | Single-day burndown evidence | Sprint retro pattern |
| L227 | Migration authored but not auto-applied → schema gap surfaces in UAT | A004 — auto-apply on bootstrap |
| L228 | Browser e2e non-waiting visibility check → race | Use proper wait conditions |
| L229 | Brittle text-substring scope | Scope to row testids |

## When this map is incomplete

- If you find a pattern that should be in this map but isn't → add it in the same commit as the task that surfaced it.
- If a rule cited here isn't documented in `project-local.md` yet → add it; this file is the leading edge.
- Mention the addition in the next sprint retro.

## Related

- [`../../.claude/rules/project-local.md`](../../.claude/rules/project-local.md) — A001-A0NN (per-project rules)
- [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) — top-priority always-apply rules
- [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) — Gates 1-6
- [`../../.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md) — when to consult this map
