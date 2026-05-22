# Lesson Trigger Map

> Mechanical mapping of "if touching X → apply rule Y". Every specialized agent reads this file as part of [`.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md) Step 2.
>
> **Three rule namespaces — one canonical meaning each, all defined in-repo:**
> - **A###** = the 10 always-apply rules (A001-A010), defined in [`.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md). Your project appends its own at **A011+** in the same file.
> - **N###** = the non-negotiables (N1-N6), defined in [`../../CLAUDE.md`](../../CLAUDE.md). N1 = architecture boundary, N2 = contract-first, N3 = 6-gate (= A004), N4 = parallel safety (= A007), N5 = test-first (= A001), N6 = separation of duties.
> - **L###** = battle-tested cross-project lessons. The full list with its one-line summary is the [L### table](#l-lesson-reference) at the bottom of this file — **you do not need an external brain to apply any of them.**

## How to use this map

When you plan a task that touches a path or pattern listed below, you MUST mentally tag the corresponding rule and apply it. Output an `## Applied Rules` section in your task summary listing the rules you applied (verbatim IDs).

If you skip an applicable rule, the post-delegation review (Gate 4) catches it. Skipping = rework.

The rows below are **stack-neutral**. Where a row says "(per preset)" the concrete shape lives in your installed preset's boundary rule (e.g. `go-hex` → `hex-boundaries.md`, `nextjs-fsd` → `fsd-layers.md`) or in your project-local A011+ rules.

---

## Backend / service code

| If touching | Apply rule |
|---|---|
| Domain layer (pure types, business invariants) | **N1** — domain imports nothing outward (per preset). |
| Ports / interfaces (consumed by adapters and use-cases) | **N1** — interface lives here, implementation elsewhere. |
| Use-cases / application layer | **N1** — import only ports + domain. Wrap mutations in a span / structured log (project-local observability). |
| Inbound adapters (HTTP / RPC / gRPC handlers) | **N1** — never import a peer adapter or another service. **L007** — idempotency key on write endpoints. Apply your auth/authz middleware where the route is protected. |
| Inbound message consumers | **N1** — propagate trace context from message headers; subscribe via a stable consumer group (not an auto-generated ID). |
| Outbound adapters (DB / cache / external API) | **N1** — never read framework context keys directly; use a typed helper (**L002**). |
| Message / event producers | **N2** — contract file committed first. **L117** — producer-side struct MUST match the contract; diff fields post-delegation. |
| Cache / session layer | **L007** — idempotency-key retention / TTL pattern. |
| External provider adapters | **N1** — only via a generic provider port; never embed provider-specific wire details in shared code. |
| Composition root (`main`, `app`, bootstrap) | **L116** — verify every new use-case / adapter / migration is wired post-delegation. **Compile-green ≠ feature-wired.** |
| Migrations | Idempotent (`IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`). **L227** — auto-apply on bootstrap before serving traffic; snapshots are not a migration story. **L026** — ship a verification checklist. |
| Service / project build file | Include an isolation / boundary check target (grep gate for **N1**). |
| Container build | Multi-stage build. Minimal, reproducible final stage. |
| Any test file | Use the project's standard assertion lib. Use real backends (testcontainers / docker-compose) for integration tests — **never mock the DB in an integration test**. **L006** — build to a unique path + kill stale processes before re-running. |

## Frontend / client code

| If touching | Apply rule |
|---|---|
| Top-level pages / routes | Layer rule — top-down only (per preset, e.g. pages → widgets → features → entities → shared). |
| Composite widgets / blocks | Layer rule — import from features / entities / shared, not peer widgets. |
| Feature slice | Layer rule — vertical slice; internal `{ui, model, api, lib}` only; cross-feature import forbidden. |
| Entity slice (domain types + their UI) | Layer rule — import from shared only. |
| Shared layer (leaves) | Layer rule — no imports from other layers. |
| Any user-facing string | **L037** — use the `t()` / translate() helper everywhere; no hardcoded text. |
| i18n locale files | Add the key to ALL language files. **L063** — declare keys in the D-doc. **L066** — escape special chars per your i18n lib. |
| API client wrappers | Use the centralized `apiPost / apiGet` (or equivalent). No raw `fetch` in features / widgets. **L065** — never re-add the base URL on top of the wrapper. **L100** — apply snake_case → camelCase mapping if hitting a raw endpoint. |
| Menu / nav config | **L058** — every page needs ≥1 entry point (menu / button / link); never URL-only. **L073** — a menu item needs all three: menu config + layout protected-route path + i18n key. |
| Backend response with empty list | **L067** — backend may return `null` for empty lists; frontend MUST `?? []` before iteration. **L074** — null-guard on `= response.data` assignments, not just on `.map()`. |
| New role gate / protected route | Wrap the layout / page in your auth/authz route guard (project-local). |
| List + detail API shapes | **L005** — when an API exposes both list and detail, the frontend type uses optional fields rather than two divergent types. |
| Any test file | Mirror the source structure in `__tests__/`. Mock the API layer, not the model layer. |
| Any browser E2E test | Use stable selectors. **L021** — the E2E spec is spelled out in the task, never deferred. **L228** — use proper wait conditions (no non-waiting visibility checks). **L229** — scope to row testids, not brittle text substrings. |
| Role names in code | **L025** — MUST match the backend; runtime-verify (e.g. `curl /auth/me`). |
| App layout | **L029** — layout mounts in the app root only; pages must NOT import layout components. **L030** — new pages declare their layout + nav placement. |
| Error handling in UI | **L041** — every `catch` shows a user-facing error (toast / message) or re-throws; no empty `catch {}`. |
| Percentage / rate / unit fields | **L042** — carry a JSDoc / comment specifying range + display unit. |
| Nullable data from the API | **L102** — guard nullable fields at the assignment site; verify component lifecycle + route safety. |

## Cross-service contracts

| If touching | Apply rule |
|---|---|
| Event / message schemas (`contracts/events/*.json`) | **N2** contract-first — commit standalone before downstream code. Versioned filename: `<topic>.v<N>.json`. |
| REST / OpenAPI specs (`contracts/openapi/*.yaml`) | **N2** — commit standalone. Generated client types regenerate from this. |
| Generated shared-types package | Never edit by hand. A `make codegen` (or equivalent) regenerates from `contracts/`. |
| New event topic / queue | Must appear in the bootstrap / init script. Must have a contract file. Ownership documented (who produces, who consumes). **L117** — producer struct MUST match the contract. |
| External provider integration | **N1** — only via the project's provider port + adapter; never a direct shared-store read on the provider plane. |

## Sprint workflow

| If touching | Apply rule |
|---|---|
| `docs/spec/STATUS.md` track row | **A008** — REPLACE, do not append. Move prior prose to `STATUS-archive.md` in the same commit. |
| `docs/spec/backlog.md` task row | Change status `[ ] → [~] → [x]` with date. **L087** — update immediately after task close, not deferred. **L049** — if discovery finds work already done, record `done (S## — reason)` instead of redoing it. Never delete; never re-order without bumping a "last updated" line. |
| New sprint file `docs/spec/sprints/sprint-S<N>.md` | Use `docs/designs/_templates/` (BACKLOG_ENTRY adapted for sprint). Update `backlog-index.md`. |
| New task design doc `docs/designs/sprint-S<N>/D<NNN>-<slug>.md` | **A005** — use `DESIGN_TEMPLATE.md`. Declare touched-files matrix (**L035**), acceptance criteria, applicable rules. **L008** — body field names here are the ONLY names impl may use. **L023** — enumerate side-effects of every write. **L022** — content with lifecycle needs a visibility matrix. **L076** — < 500 lines on a non-trivial task → emit "under-specified" warning. |
| Long multi-session task | **L040** — keep a `PROGRESS.md` context bridge so state survives a `/clear`. |
| Closing a sprint | **A009** — author retro at `docs/spec/retros/sprint-S<N>.md`. Move sprint file pointer to STATUS-archive. **L186** — capture single-day burndown if applicable. |
| Keeping docs in sync | **L033** — root / area / deep docs are a 3-tier set; update the tier your change touches. |
| Adding a new rule | Author it as **A011+** in `brain-hot.md` (or a `<slug>-local.md` rules file). Reference it from this map. Mention it in the next sprint retro. |

## Observability (project-local practice)

> These are not global A-rules — wire them to your stack. Listed here so agents apply them by reflex.

| If touching | Apply |
|---|---|
| Any new handler / use-case | Wrap in a span (`tracer.Start(ctx, "<verb>.<noun>")` or your tracer's equivalent). |
| Any new long-running worker | Emit an `<service>_alive` heartbeat metric (e.g. every 30 s). |
| Any new message consumer | Emit a consumer-lag gauge. Subscribe via a stable consumer group. |
| Any new error path | Capture to your error tracker — don't swallow into a log line alone (ties to **L041**). |
| Any new dashboard | Author at the canonical observability path; update the dashboard index doc. |
| Admin config / settings feature | **L109** — document the admin's first-run setup journey. |

## Multi-repo / submodule

| If touching | Apply rule |
|---|---|
| Submodule code | Always commit + push in the SUBMODULE'S OWN git, never via meta-repo edits. **L114** — use `git -C <submodule>` (never `cd <dir>` for git). |
| `.gitmodules` | The meta-repo bumps submodule pointers via `git add <submodule>` + commit. Message: `deps: bump <submodule> to <description>`. **L141** — verify the submodule branch is mergeable before bumping. |
| Any cross-service shared import | **N1** — FORBIDDEN. Use the message bus or REST through the shared lib. |
| Sub-agent invocation | **A006** — use the `Agent` tool from the main session. NEVER `claude -p`. |
| `cd <dir>` for git operations | **L114** — FORBIDDEN. Use `git -C <dir>` instead. |

## Code review (mandatory gates)

| Gate | Trigger | Action |
|---|---|---|
| Gate 1 — Inspect | After every coding subagent returns | `git diff --stat` + `git diff <files>`. Read the actual diff. |
| Gate 2 — Build + Test | After every coding subagent returns | The project's build + test command in touched modules. |
| Gate 3 — Boundary | After every coding subagent returns | **Preset-specific** — if `go-hex` is installed, dispatch `hexagonal-reviewer`; if `nextjs-fsd`, run FSD lint; if `vue-pinia`, run the boundary check. See your preset for the project's Gate 3. |
| Gate 4a — Spec-compliance | After every coding subagent returns | Read code vs the D-doc AC: every AC built, nothing extra (over/under-build). Verify by reading code, not the report. Gates 4b. |
| Gate 4b — Quality (parallel) | After 4a passes | Dispatch `pr-review-toolkit:{code-reviewer, silent-failure-hunter, type-design-analyzer}` + `:pr-test-analyzer` if tests touched + `:comment-analyzer` if comments touched. |
| Gate 5 — Wiring | After every coding subagent returns | **L116** — grep composition root for new code usage. Verify migrations applied, observability emits, message topic created, contracts updated. |
| Gate 6 — Integration smoke | After every coding subagent returns | Local stack up + smoke (and browser e2e if frontend touched). |

This is **A004** (= **N3**). Per [`.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) §4. Skipping = production bugs.

---

## L### lesson reference

Every lesson below is defined here in one line — this IS the source of truth, no external brain required. The highest-leverage ones (L020, L035, L076, L087, L101, L116, L147, L149, L156, L182) are also auto-loaded via [`.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md).

| ID | Pitfall it prevents | Trigger / where applicable |
|---|---|---|
| L002 | Framework context keys read directly | Wrap in a typed helper |
| L004 | Seed data missing FK relationships | Migration / fixture authoring |
| L005 | List + detail API modeled as two divergent FE types | Use one type with optional fields |
| L006 | Stale binary cached → tests pass against old code | After build — unique output path + kill stale processes |
| L007 | Duplicate request → duplicate write | Idempotency key on write endpoints + cache TTL |
| L008 | Agents invent synonym field names | Body field names in the D-doc are the ONLY names impl may use |
| L020 | Selector contract drift | `data-testid` ships in the D-doc selector map BEFORE UI + E2E |
| L021 | E2E deferred "to later" → never written | E2E spec spelled out in the task itself |
| L022 | Content visibility enforced only in UI | Per-role visibility matrix enforced at the API layer |
| L023 | Side-effects of a write left implicit | D-doc enumerates backlinks / notifications / versioning |
| L025 | Frontend role names diverge from backend | Runtime-verify (e.g. `curl /auth/me`) |
| L026 | Migration authored but never verified | Ship a `migrate up` + verify checklist |
| L029 | Layout imported from pages → double-render | Layout in the app root only |
| L030 | New page with no layout / nav placement | Declare layout + nav entry in the D-doc |
| L033 | Doc tiers drift out of sync | Update the root / area / deep tier your change touches |
| L035 | Touched-files matrix missing | Every D-doc declares files it touches (Conflict Radar input) |
| L036 | Per-task learning lost before sprint close | = **A009** — append the 6-field mini-retro after each task |
| L037 | Hardcoded user-facing strings | Use `t()` everywhere |
| L040 | Long task loses context across `/clear` | Keep a `PROGRESS.md` context bridge |
| L041 | Empty `catch {}` swallows UI errors | Show a user-facing error or re-throw |
| L042 | Rate / percentage field ambiguous | JSDoc the range + display unit |
| L049 | Re-doing work that's already done | Mark `done (S## — reason)` in the backlog |
| L050 | RBAC route forgets the policy seed | Verify the authz policy is seeded |
| L058 | Page reachable only by typing the URL | Every page has ≥1 menu / button / link entry point |
| L063 | Duplicate route name / missing i18n key | Grep route names for uniqueness; declare i18n keys in the D-doc |
| L064 | DB table-name typo in JOIN | Pre-flight schema check |
| L065 | Services re-added base URL on top of the wrapper | Use the centralized api wrapper |
| L066 | i18n special-char in values | Escape per your i18n lib |
| L067 | Backend `null` for empty list crashes `.map()` | Frontend `?? []` |
| L073 | Menu item missing one of 3 places | menu config + layout paths + i18n key |
| L074 | `= response.data` null crash | Guard on assignment, not just on `.map()` |
| L076 | Task design under 500 lines = under-specified | Pre-task ritual emits warning |
| L087 | Backlog not updated immediately after task close | Update inline, not deferred |
| L089 | Permission migration INSERT duplicated | Grep existing migrations first |
| L091 | Nullable column with no default | Provide explicit default at write site |
| L100 | snake_case → camelCase mapping with raw fetch | Use the centralized api wrapper |
| L101 | Fix from code-reading alone fails | Reproduce / evidence first |
| L102 | Nullable API data crashes a component | Guard at assignment; verify lifecycle + route safety |
| L109 | Admin feature with no setup journey | Document the admin's first-run path |
| L114 | `cd <dir>` for git breaks parallel agents | Always `git -C <dir>` |
| L116 | Post-delegation: composition root not wired | Gate 5 verifies |
| L117 | Producer-side struct mismatched with contract | Diff fields post-delegation |
| L127 | Config lib missing `SetDefault` / `BindEnv` | Both required even with auto-env binding |
| L141 | Submodule SHA bump without verifying mergeable | Check sub-repo state before bumping |
| L147 | Wrong tool for the query class | LSP for semantic; grep only for text (= **A010**) |
| L149 | AC type-contradiction surfaces late | LSP `hover` every AC type before authoring the D-doc |
| L153 | Stale Reads pollute the next skill | `/clear` between skill invocations |
| L154 | Sprint / backlog / D-doc created without index update | Index-first (see `index-discipline.md`) |
| L156 | Hallucinated types in a D-doc code paste | LSP-verify types before pasting |
| L182 | Visual fidelity assumed from passing unit tests | UI sprints run `/design-review` (3-lens visual gate) |
| L186 | Single-day burndown evidence lost | Capture in the sprint retro |
| L227 | Migration authored but not auto-applied → UAT schema gap | Auto-apply on bootstrap |
| L228 | Browser e2e non-waiting visibility check → race | Use proper wait conditions |
| L229 | Brittle text-substring scope | Scope to row testids |

## When this map is incomplete

- If you find a pattern that should be in this map but isn't → add it in the same commit as the task that surfaced it.
- If a lesson cited here needs more than one line → add a short reference doc under `docs/setup/` and link it from the table.
- Mention the addition in the next sprint retro.

## Related

- [`../../.claude/rules/brain-hot.md`](../../.claude/rules/brain-hot.md) — A001-A010 + the highest-leverage L### subset
- [`../../CLAUDE.md`](../../CLAUDE.md) — N1-N6 non-negotiables
- [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) — Gates 1-6
- [`../../.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md) — when to consult this map
