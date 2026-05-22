# Design: DXXX — [Task Name] (Light)

> **Use for:** S-tier work per [`SIZE_TIERS.md`](./SIZE_TIERS.md). XS
> work uses the full template with most sections deleted (or skips a
> design doc entirely per the A005 sentence-test). M/L tier work uses
> [`DESIGN_TEMPLATE.md`](./DESIGN_TEMPLATE.md).
>
> **Before submitting:** run
> [`SELF_REVIEW_CHECKLIST.md`](./SELF_REVIEW_CHECKLIST.md) Scans 1, 2,
> and 5 (skip 3 and 4 — a Light doc has no diagram-vs-files matrix
> and no current-state coverage section).

> **Sprint:** Sprint XX | **Task:** X.X | **Repo:** frontend | backend
> **Status:** Draft | Approved | Done
> **Type:** feat | fix | refactor | chore | docs | spike | release
> **Size:** S  (Light template assumes S — bump to M/L → use the full template)
> **Date:** YYYY-MM-DD

## Overview
[1-2 sentences: what this task does]

## Approach
[How to implement — key files, key changes]

## Routing & Navigation (if has a UI page)
> Delete this section if backend-only.

| Path | Route Name | Menu? | Roles |
|------|-----------|-------|-------|
| /path/:param | route-name | yes/no | [roles] |

**Navigation:** user enters from [source] → exits to [destinations]
**Route Params → API:** `:routeParam` → API `:apiParam` ([mapping notes])
**Route Registry:** update `docs/contracts/route-registry.md`

## Frontend Component Spec (if has UI)
> Delete this section if backend-only.

**Layout:** `main` / `auth` / `portal` / `none` (via `route.meta.layout` — do NOT import Layout in a page)
**State:** centralized store / local ref — fetch trigger: onMounted / route watcher

| UX State | Pattern |
|----------|---------|
| Loading | skeleton / spinner |
| Empty | icon + message + CTA |
| Error | inline message + retry / toast |
| Success | redirect / toast |

**Error handling:** 401→login, 403→access denied, 500→toast+retry
**Form (if any):** validation timing, submit behavior, unsaved changes warning
**Responsive:** desktop default → tablet [changes] → mobile [changes]

## Interactive Behavior Map (P012)
> Every clickable element must spell out its behavior — do NOT create elements that do nothing on click.

| Element | Trigger | Action | Target/Result | Feedback |
|---------|---------|--------|---------------|----------|
| "[Button]" btn | click | navigate / API call | [path or result] | [loading/toast/confirm] |
| "Cancel" btn | click | confirm if dirty → back | previous page | confirm dialog |
| "Delete" btn | click | confirm → DELETE API | redirect to list | confirm → loading → toast |

**Rules:** API buttons = disabled+spinner+error toast | Navigate = explicit target path | Destructive = confirm dialog | Login redirect = router.replace

## User Journey (P012)
> Happy path step-by-step + error flows + browser back behavior

**Happy path:**
```
1. [Entry: sidebar/card/link] → [Page] loads → skeleton
2. Data loaded → content → [primary action] → [result + feedback]
3. Back: goes to [previous page]
```

**Errors:** 400→inline errors | 403→access denied | 500→toast+retry | Network→offline banner
**Browser nav:** Back=[behavior] | Refresh=reload from API | Direct URL=auth guard | After login=router.replace

## Data Flow & Side-Effects (L023)
> Delete this section if the task has no write operations or side-effects.

```
[Write action]:
  1. Main write
  2. → [Side-effect] ...
  3. → [Side-effect] ...
```

## API Body Schema (L008/L020)
> Delete this section if frontend-only and no new API.
> Field names declared here = source of truth for backend + frontend + E2E.

```
Request body: { field_name: type, ... }   ← real field names used
```

## E2E Selector Map (L020)
> Delete this section if backend-only.
> List the selectors frontend must include and E2E will use.

| Element | selector |
|---------|--------------|
| [button/input name] | `noun-action` |

## Content Visibility (L022)
> Delete this section if no content lifecycle / access control.
> Spell out what HTTP code backend returns to each role.

| Role | draft | published | API |
|------|-------|-----------|-----|
| Reader | 403 | 200 | enforced |

## Test Plan
| Test | Role | Expected | What it verifies |
|------|------|----------|-----------------|
| [happy path] | admin | 200 | feature works |
| [RBAC] | reader | 403 | API enforces access |

## Tasks
| # | Task | Status |
|---|------|--------|
| 1 | Write unit + cross-role tests | [ ] |
| 2 | Implement (with selectors + side-effects) | [ ] |
| 3 | **Run E2E — must pass** | [ ] |

## Acceptance Criteria
- [ ] [AC from sprint]
- [ ] E2E spec passes (run, not just written)
- [ ] selectors match the selector map above
- [ ] Side-effects verified (if applicable)
