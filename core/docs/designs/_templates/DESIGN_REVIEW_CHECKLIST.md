# Design Review Checklist

> Tech Lead must self-review the design doc with this checklist **before approving**.
> Every relevant item must pass — mark non-relevant items N/A.
> If checklist fails → fix design doc → review again.

---

## Step 0: Determine Task Tier (MANDATORY — before choosing template)

| Tier | Scope | Template | 3-Tier Docs? |
|------|-------|----------|-------------|
| **XS** | 1-2 files, no new routes/endpoints | no Design Doc | no |
| **S** | 3-5 files, add fields/filters | Light Template | no |
| **M** | 6-15 files, new pages/endpoints | Full Template | yes |
| **L** | 15+ files or cross-repo | Full Template + reviewer | yes |

XL backlog items split into multiple L docs (one per coherent slice).
See [`SIZE_TIERS.md`](./SIZE_TIERS.md) for the canonical picker.

- [ ] **Tier assigned:** tier chosen before starting design (XS → skip design, S → Light, M/L → Full)
- [ ] **Template matches tier:** the right template is in use

---

## Backend Checklist (if there are API/DB changes)

- [ ] **API Contract (Section 3):** every endpoint spells out method, path, auth, roles, request body, response shape, error codes
- [ ] **Response Envelope:** matches the project standard `{ data, meta, pagination, error }`
- [ ] **Migration (Section 4):** has up + down SQL, index strategy spelled out
- [ ] **Migration Verification (L026):** has a checklist for Root PM to run `migrate up` + verify
- [ ] **Side-Effects (Section 2, L023):** every write operation spells out side-effects (backlinks, notifications, versioning, etc.)
- [ ] **Idempotency (L007):** write endpoints affecting data integrity carry an Idempotency-Key
- [ ] **RBAC Matrix (Section 8B):** covers every project role — allow / deny per row
- [ ] **Content Visibility (Section 8C, L022):** if there is content lifecycle → Visibility Matrix is filled in
- [ ] **Error Codes:** uses domain-specific codes (not just generic 400/500)

## Frontend Checklist (if there are UI pages/components)

- [ ] **Routes (Section 2.5):** every page spells out path, name, layout, auth, roles
- [ ] **Route Names Unique (L063):** route name in design isn't a duplicate of an existing route in `src/router/index.ts` — grep before approve
- [ ] **Route Names in Task File (L063):** task file has the route name matching the design — agent must use this name only
- [ ] **Route Registry:** `docs/contracts/route-registry.md` updated — no duplicate / conflicting routes
- [ ] **Menu Integration (L058 — MANDATORY):** every page has at least one entry point — sidebar menu / cross-page button / card link — never a page reachable only by typing the URL
- [ ] **Menu Roles (L058):** role visibility + file to modify (`src/config/menu.ts`) spelled out
- [ ] **Navigation Flow:** spells out where the user enters from + exits to — cross-references the menu entry point
- [ ] **Route Params → API Params:** mapping table is correct (e.g. slug vs id)
- [ ] **E2E Selectors (Section 6, L020):** every interactive element has a stable selector locked in
- [ ] **Design Aesthetic (Section 5, P011):** if a new user-facing page → has a P011 section
- [ ] **Component Hierarchy:** file structure spells out CREATE/MODIFY clearly

### Frontend Component Spec (Section 2.6 — MANDATORY for UI tasks)
- [ ] **Layout Assignment (L029):** layout spelled out — do NOT import Layout in a page
- [ ] **State Management:** centralized store vs local ref, fetch trigger, cache strategy
- [ ] **UX States all 4:** Loading (skeleton/spinner), Empty (icon+CTA), Error (message+retry), Success (redirect/toast)
- [ ] **Error Handling:** spells out action for 401/403/404/500/network error
- [ ] **Form Spec (if form):** validation timing, submit behavior, unsaved changes, double-submit prevention
- [ ] **Responsive:** spells out changes for Desktop/Tablet/Mobile breakpoints

### i18n Translation Keys (Section 2.10 — L063 — MANDATORY for UI tasks)
- [ ] **Key list complete:** every user-facing text (title, columns, buttons, status labels, messages, placeholders) has a key in Section 2.10
- [ ] **Key path convention:** uses `{module}.{page}.{element}` format consistently
- [ ] **Both languages:** every key has values in every project language in the design doc
- [ ] **Keys in task file:** task file copies the i18n key list from design — agent sees every key to add

### Interactive Behavior Map (Section 2.7 — P012 — MANDATORY for UI tasks)
- [ ] **Every button has a behavior:** every button/link in the Behavior Map has a non-empty Action column
- [ ] **API buttons:** API-calling buttons spell out disabled+spinner+error handling
- [ ] **Navigate buttons:** navigation buttons spell out target path (not just "goes somewhere")
- [ ] **Cancel/Back:** spelled out — router.back() vs specific route + dirty check
- [ ] **Destructive actions:** delete/archive/discard have a confirmation dialog
- [ ] **Login redirect:** uses router.replace (not push) — prevents back to login

### User Journey (Section 2.8 — P012 — MANDATORY for pages with UI)
- [ ] **Happy path:** has step-by-step flow from entry → action → result → exit
- [ ] **Error flows:** covers 400/403/404/500/network error — what user sees and can do
- [ ] **Browser back:** spells out where back goes + state
- [ ] **Refresh:** spells out F5 behavior (reload from API / state lost)
- [ ] **Direct URL:** spells out direct-URL paste + auth guard behavior

### Web Interface Guidelines (Section 2.9 — P013 — MANDATORY for UI tasks)
> **Reference:** `docs/contracts/web-interface-guidelines.md`
- [ ] **Accessibility:** icon buttons have `aria-label`, decorative icons `aria-hidden`, async updates `aria-live`
- [ ] **Focus states:** `:focus-visible` on all interactive elements, no bare `outline: none`
- [ ] **Form quality:** correct `type`/`autocomplete`, `spellcheck="false"` on emails, placeholder ends with `…`, focus first error on submit
- [ ] **Animation:** `prefers-reduced-motion` respected, only `transform`/`opacity`, no `transition: all`
- [ ] **Theming:** all colors via CSS variables (no hardcoded hex in components)
- [ ] **Touch:** `touch-action: manipulation` on interactive containers
- [ ] **Content:** text overflow handled (truncate/clamp), empty states defined, loading uses `…`
- [ ] **Anti-patterns:** no `<div onClick>`, no images without dimensions, no `autoFocus` without justification

## Null Safety & Data Contract (L102 — from feedback loops)

- [ ] **API list response null safety:** every endpoint returning a list — design spells out "default `[]` if empty, frontend must guard `?? []`"
- [ ] **Optional fields default:** every optional field spells out a default value in design (null / undefined / empty string / 0)
- [ ] **Computed properties null-safe:** every computed using API data uses `?.` optional chain

## Component Lifecycle (L102 — from feedback loops)

- [ ] **Editor/Timer/WebSocket cleanup:** every component with an editor, timer, or WebSocket spells out cleanup in `onUnmounted`
- [ ] **Async guard:** every async op — check component mounted before setState (for long-running ops)
- [ ] **Dynamic import error:** lazy-loaded components have a chunk load error handler (retry/refresh)

## Navigation & Route Safety (L102 — from feedback loops)

- [ ] **Sidebar/Menu links verified:** every `router.push({name})` in layout/sidebar → grep that `name` exists in `router/index.ts`
- [ ] **URL params validated:** every route accepting a param (UUID, slug) → validate format before API call
- [ ] **Modal payload:** every modal posting data → field types match backend DTO (UUID vs slug vs string)

## Admin Setup Journey (L109 — if feature has admin config/settings)

- [ ] **Setup Journey complete:** answers "if a new admin sets up this feature for the first time, can they do it on their own?" — spelled out step-by-step in design
- [ ] **Output immediately usable:** if feature produces URL/token/code → has copy button + auto-fill that admin doesn't have to assemble
- [ ] **Multi-entity scope correct:** if config is org-level but data is project-level → spells out how the admin picks the project (no hard-coded default)
- [ ] **AC are user-outcomes:** at least one AC is "Admin can [accomplish X]" not just "API returns 200"

## Cross-Repo Checklist (if design covers both backend + frontend)

- [ ] **Field Names Match:** backend DTO field names = frontend interface = E2E selectors
- [ ] **Role Names Match (L025):** frontend `UserRole` type values match backend DB role names
- [ ] **API Path Match:** frontend service calls match the path backend registers in router
- [ ] **List vs Detail Interface (L005):** if API has both list + detail → frontend interface uses optional fields
- [ ] **Seed Data (L004):** test plan spells out seed data — parents before children

### Layout & Navigation (L029, L030)
- [ ] Page component does NOT import any Layout (uses route.meta.layout)
- [ ] Menu active state correct for nested routes (prefix match, not exact)
- [ ] Every user action (click) has visual feedback
- [ ] Destructive actions (logout, delete) have confirmation step or dropdown menu

## 3-Tier Sync Checklist (L035 — MANDATORY before approve)

> Check after Root + Repo + Task File all exist — **do NOT approve if not in sync.**

- [ ] **Repo Doc has every section from Root:** S1 (Overview), S2.5-S2.8, S3 (API Contract), S6 (Test Plan), S8 (RBAC), S9 (AC), S10 (Questions)
- [ ] **Repo Doc does NOT abridge sections copied from Root:** must be verbatim
- [ ] **Types match 100%:** field name, type, optional/required match across Root, Repo, Task File
- [ ] **Types match backend DTO:** e.g. backend `string` → frontend must be `string`; backend always sends → must not be optional
- [ ] **API endpoints match:** method, path, request body, response shape, error codes
- [ ] **RBAC matrix matches:** Root matrix == Repo matrix == Task file RBAC
- [ ] **Selectors match:** Root selector map == Repo selector map == Task file
- [ ] **AC match:** Root AC == Repo AC

## Process Checklist

- [ ] **Acceptance Criteria:** every AC has a test reference (unit/integration/E2E)
- [ ] **Test Plan (Section 6):** has happy path + RBAC negative + edge cases
- [ ] **E2E per Task (L021):** E2E spec spelled out in tasks — not deferred
- [ ] **Dependency Check (Section 1):** every dependency is ready (status: Done)
- [ ] **Open Questions (Section 10):** no unresolved blockers

---

## How to Use

```
Tech Lead workflow:
  1. Create Design Doc from template
  2. Open DESIGN_REVIEW_CHECKLIST.md
  3. Check every relevant item / N/A non-relevant items
  4. If fails → fix design → review again
  5. All pass → approve → delegate

Agent workflow (before implementation):
  1. Read design doc
  2. Verify Section 2.5 (routes), Section 6 (selectors), Section 8 (RBAC) are complete
  3. If missing → report back to Root PM before implementing
```
