# {{PROJECT_NAME}} — Deployment Workflow

> **Status:** Active
> **Applies to:** every service / app repo in this project

## Context

Many projects start with a single-branch (`main`) workflow — commit directly to main, then auto-deploy. That works for an MVP. As soon as the project enters UAT / Production, a deploy needs quality gates: code review, PR process, staging gate before production. This document is the loop.

---

## 1. Git Branch Strategy

### Branch Model: Environment-Based Flow

```
feature/{{TASK_ID_PREFIX}}-XXX-desc  ──PR──→  dev  ──PR──→  main  ──tag v*──→  production
              │                       │              │                    │
         Developer                Local Dev      UAT (auto)         Production
         workspace               integration     uat.<domain>       <domain>
```

### Branch Rules

| Branch | Purpose | Deploy Target | Protection Rules |
|--------|---------|---------------|-----------------|
| `feature/*` | Feature development | — (local only) | Branch from `dev`, naming: `feature/{{TASK_ID_PREFIX}}-{ticket}-{short-desc}` |
| `bugfix/*` | Bug fixes | — (local only) | Branch from `dev`, naming: `bugfix/{{TASK_ID_PREFIX}}-{ticket}-{short-desc}` |
| `hotfix/*` | Production emergency | — | Branch from `main`, merge back to `main` AND `dev` |
| `dev` | Integration branch | Local dev env | PR required, CI must pass, self-merge OK for solo dev |
| `main` | UAT release branch | UAT (auto-deploy) | PR from `dev` required, CI + checklist must pass, 1 approval (or self-review with checklist) |
| `v*.*.*` (tag) | Production release | Production (manual sync) | Tag from `main` only, checklist signed off, rollback plan documented |

### Branch Lifecycle

```
1. Developer creates feature/{{TASK_ID_PREFIX}}-XXX from dev
2. Work + commit (conventional commits)
3. PR → dev (CI runs: test + build)
4. Merge to dev → local integration test
5. Accumulate features → PR dev → main (UAT Checklist)
6. Merge to main → auto-deploy UAT
7. UAT testing + sign-off
8. Tag v*.*.* on main → manual deploy to production
```

### Naming Convention

```
feature/{{TASK_ID_PREFIX}}-123-feature-name        # New feature
bugfix/{{TASK_ID_PREFIX}}-456-bug-name             # Bug fix
hotfix/{{TASK_ID_PREFIX}}-789-fix-name             # Production hotfix
release/v1.2.0                                     # Release prep (optional)
```

### Commit Convention (Conventional Commits)

```
feat(module): add X                                 # New feature
fix(module): correct Y                              # Bug fix
refactor(module): extract Z                         # Refactoring
docs(api): update OpenAPI spec                      # Documentation
test(rbac): add cross-role integration tests        # Tests only
chore(deps): upgrade runtime to X                   # Maintenance
perf(search): optimize query                        # Performance

Breaking change: append ! after type
feat(api)!: change pagination to cursor-based
```

---

## 2. PR Process & Code Review

### PR Template

PR template file: `.github/pull_request_template.md` — created in each repo.

Key sections:
- Summary (what changed and why)
- Type (Feature / Bug Fix / Hotfix / Refactor / Docs / Infra)
- Related (Sprint, Task, Design Doc)
- Developer Checklist
- Reviewer Checklist
- Screenshots (if UI change)
- Test Plan

### Review Process

**Solo Dev:**
- feature → dev: Self-merge OK (CI must pass)
- dev → main: **Self-review with UAT Checklist** (mandatory, documented in PR)
- Checklist acts as "second pair of eyes"

**Team (2+ developers):**
- feature → dev: 1 approval required
- dev → main: 1 approval + UAT Checklist signed
- hotfix → main: 1 approval (expedited, post-review OK)

### GitHub Branch Protection Rules

**`dev` branch:**
- Require PR (no direct push)
- Require CI status checks to pass: `test`, `build`
- Allow self-merge (solo dev mode)
- Delete branch on merge: true

**`main` branch:**
- Require PR (no direct push)
- Require CI status checks to pass: `test`, `build`, `lint`
- Require UAT deployment checklist (PR template checkbox)
- Allow force push: NEVER
- Delete branch on merge: false (dev is persistent)

---

## 3. CI/CD Pipeline

| Stage | Trigger | Jobs |
|-------|---------|------|
| **PR Check** | PR to `dev` or `main` | lint → test → build (no image push) |
| **Dev Build** | Push to `dev` | test → build → push `dev-{sha}` image (optional) |
| **UAT Deploy** | Push to `main` | test → build → push `uat-{sha}` → deploy → sync |
| **Prod Deploy** | Tag `v*.*.*` | retag `uat-{sha}` as `v*.*.*` → deploy → manual sync |

---

## 4. Deployment Checklists

### 4.1 DEV → UAT Checklist (PR: dev → main)

#### Step 0: Secrets & Environment Sync (MANDATORY before deploy)

Compare your secret manager listing with the project's master list (kept in the repo as `docs/releases/secrets-master.md` or similar).
Every row MUST exist before deploy — create missing ones from local `.env` or generate new values.

When adding new features that need env vars:
1. Add to `.env.example`
2. If secret → add to secret manager + secrets sync resource
3. If config → add to deployment values / configmap
4. Update the master-list table

#### Pre-Merge
- [ ] All tests pass on `dev` branch (CI green)
- [ ] Build succeeds
- [ ] No lint errors (or lint is non-blocking with TODO)
- [ ] De-sloppify done (no debug prints, no dead code)
- [ ] API contract synced: backend response ↔ frontend types
- [ ] Database / store migration reviewed:
  - [ ] Migration tested locally (up + down)
  - [ ] No destructive DDL without data migration plan
  - [ ] Migration file numbered correctly (no conflict)
- [ ] **Secrets & env vars synced (Step 0):**
  - [ ] Secret count matches master list
  - [ ] Sync resource entries match secret manager
  - [ ] Configmap env vars correct for target environment
- [ ] i18n: all keys in every language file (no raw keys)
- [ ] RBAC: permission modules seeded
- [ ] Feature flags: partial features OFF by default

#### Post-Merge (Auto-deploy to UAT)
- [ ] Sync controller completed
- [ ] Migration job succeeded
- [ ] Health check passes
- [ ] Readiness check passes
- [ ] Smoke test: login → navigate to changed feature → verify UI
- [ ] No 500 errors in backend logs
- [ ] No console errors in browser
- [ ] Cross-role test if RBAC change

### 4.2 UAT Verification Gate (Sprint End — MANDATORY)

> **Every sprint must pass UAT verification before production tag.**

#### Step 1: Automated Health Check
```
- [ ] /healthz → 200
- [ ] /readyz → 200
- [ ] Pods Running
- [ ] Sync status: Synced
```

#### Step 2: Browser Smoke Test
Uses a browser MCP / Playwright to open UAT live:
```
- [ ] Login page loads — no blank / 404
- [ ] No browser console errors (red)
- [ ] Dashboard loads after login
- [ ] Each sprint feature verified:
  - [ ] Navigate to feature URL → page renders
  - [ ] No raw i18n keys visible
  - [ ] Core actions work (create, edit, delete if applicable)
  - [ ] Screenshot captured as evidence
- [ ] Cross-role test (if RBAC changes):
  - [ ] Login as privileged → verify access
  - [ ] Login as non-privileged → verify restricted access
  - [ ] Sidebar shows correct menu items per role
```

#### Step 3: Sign-off Report
Generates `docs/releases/uat-signoff-SXX.md`:
```
- [ ] Health check results recorded
- [ ] Feature verification table filled in (PASS/FAIL per feature)
- [ ] Browser smoke test results with evidence
- [ ] Sign-off decision: APPROVED or REJECTED
- [ ] If REJECTED: issues listed with severity
```

#### Step 4: Decision Gate
```
APPROVED → proceed to production tag
REJECTED → create bugfix branches → fix → re-merge → re-verify
```

### 4.3 UAT → PRODUCTION Checklist (Tag v*.*.*)

#### A. Pre-Release Preparation (1-2 days before)
- [ ] All UAT testing completed — no open P0/P1 bugs
- [ ] Sprint retro done — lessons captured
- [ ] Release notes drafted (`docs/releases/v*.*.*.md`)
  - New features list
  - Bug fixes list
  - Breaking changes (if any)
  - Migration notes
  - Known issues
- [ ] Database migration plan:
  - [ ] Total migrations to apply (count)
  - [ ] Estimated migration time
  - [ ] Rollback migration tested
  - [ ] Data backup scheduled before deploy
- [ ] Secrets verified in production secret manager
- [ ] Resource limits reviewed
- [ ] PodDisruptionBudget / equivalent configured
- [ ] Rollback plan documented:
  - Previous stable tag
  - Rollback command (sync to previous revision)
  - Database rollback steps

#### B. Release Execution
- [ ] Notify stakeholders: "Production deploy starting"
- [ ] Create git tag on `main`:
  ```bash
  git tag -a v1.X.X -m "Release v1.X.X: <summary>"
  git push origin v1.X.X
  ```
- [ ] CI tagging job completes
- [ ] **Review diff in deploy UI** before sync
- [ ] Click "Sync" / manual deploy approval
- [ ] Watch rolling update:
  - [ ] New pods start
  - [ ] Health checks pass on new pods
  - [ ] Old pods terminate gracefully
  - [ ] Zero downtime confirmed

#### C. Post-Release Verification (within 30 minutes)
- [ ] Health endpoint → 200
- [ ] Ready endpoint → 200
- [ ] Login works
- [ ] Core flows verified
- [ ] No 500s in logs (last 15 minutes)
- [ ] No error spike in application metrics
- [ ] Datastore connection pool healthy
- [ ] Message bus connected
- [ ] Notify stakeholders: "Production deploy complete"

#### D. Rollback Procedure (if issues found)

**Severity Assessment:**
- P0 (system down): Rollback immediately
- P1 (major feature broken): Rollback within 30 min
- P2 (minor issue): Hotfix forward

**Rollback Steps:**
```
1. Deploy UI → History → Select previous revision → Sync
2. If DB migration needs rollback:
   Run the down migration to the target version
3. Verify health + smoke test
4. Notify stakeholders: "Rolled back to v*.*.*, investigating"
```

**Post-Rollback:**
- Create incident report
- Root cause analysis
- Fix forward on `dev` → test → re-release

### 4.4 Documentation Lifecycle (Product Knowledge)

> **Docs are part of the deliverable** — a feature with no docs is a feature that is not done.

#### Documentation in Sprint Workflow

```
Phase: Tasks Done
  ↓
Step 12: Documentation Update (before PR to main)
  1. doc-impact SPRINT=XX     → check what needs to update
  2. Start local stack
  3. /document refresh         → re-capture + update content
  4. /document export          → generate deploy artifact
  5. Include artifact in PR    → deploys with backend code
  ↓
Step 13: UAT Verification
  - doc-verify                → verify docs on UAT via browser
  - Check: pages exist, content current, screenshots match
  ↓
Production Tag → docs auto-deploy → users see updated guides
```

#### When to Update Docs

| Sprint Change | Doc Action |
|--------------|-----------|
| New user-facing page | Add new guide page |
| UI layout / flow changed | Re-capture screenshots |
| New admin feature | Add section to admin guide |
| Permission changes | Update role reference page |
| Backend-only (no UI) | No doc update needed |
| Bug fix (no UI change) | No doc update needed |

### 4.5 HOTFIX Process (Production Emergency)

```
1. Branch: hotfix/{{TASK_ID_PREFIX}}-XXX from main
2. Fix + test locally
3. PR → main (expedited review: checklist only, post-review OK)
4. Merge → UAT auto-deploy → quick smoke test (15 min max)
5. Tag vX.Y.Z+1 → production deploy
6. Merge hotfix back to dev (prevent divergence)
7. Incident report + RCA
```

---

## 5. Versioning Strategy

### Semantic Versioning

```
v{MAJOR}.{MINOR}.{PATCH}

MAJOR: Breaking API changes, incompatible DB changes
MINOR: New features, backward-compatible
PATCH: Bug fixes, hotfixes

Examples:
v1.0.0  — Initial production release
v1.1.0  — Sprint NN features
v1.1.1  — Hotfix for bug
v1.2.0  — Sprint MM features
v2.0.0  — Major API redesign (breaking)
```

### Tag Commands

```bash
git tag -l 'v*' --sort=-v:refname
git checkout main && git pull origin main
git tag -a v1.1.0 -m "Release v1.1.0: <summary>"
git push origin v1.1.0
```

---

## 6. Release Notes Template

**File location:** `docs/releases/vX.Y.Z.md`

```markdown
# Release v1.X.X — <Title>

**Date:** YYYY-MM-DD
**Sprint:** S##
**Tag:** v1.X.X
**Previous:** v1.X.X

## New Features
- **[B###] Feature Name** — Brief description

## Bug Fixes
- **[B###] Fix Name** — What was broken → what was fixed

## Improvements
- Performance, UX, or internal improvements

## Breaking Changes
- None (or list with migration guide)

## Database Migrations
- Migration ###: Description
- Total new migrations: N

## Infrastructure Changes
- None (or list: new env vars, new services, config changes)

## Known Issues
- None (or list with workarounds)

## Contributors
- @developer — features/fixes
```

---

## 7. Environment Parity Matrix

| Config | Local (dev) | UAT | Production |
|--------|------------|-----|------------|
| Datastore | localhost | shared instance | HA cluster |
| Cache | local | single pod | sentinel / cluster |
| Message bus | local | single pod | clustered |
| Object store | local | single pod | distributed |
| Search | local | single pod | HA |
| Log Level | debug | info | warn |
| CORS | * | uat.<domain> | <domain> |
| Rate Limit | disabled | relaxed | strict |
| Token Expiry | long (dev convenience) | short | short |
| Replicas | 1 | 1-2 | 2-3+ |
| HPA | N/A | disabled | enabled |
| PDB | N/A | N/A | enabled |
| Backup | N/A | daily | daily + PITR |

---

## 8. SDLC Complete Loop

```
┌──────────────────────────────────────────────────────────────────┐
│                    SDLC — Enterprise Grade                       │
│                                                                  │
│  1. PLAN          /idea → /idea promote → sprint plan            │
│      ↓                                                           │
│  2. DESIGN        Design Doc → 3-Tier Docs → Review              │
│      ↓                                                           │
│  3. DEVELOP       feature/* branch → TDD → commit                │
│      ↓                                                           │
│  4. CODE REVIEW   PR → dev (CI + self/peer review)               │
│      ↓                                                           │
│  5. INTEGRATE     dev branch → local integration test            │
│      ↓                                                           │
│  5.5 DOCUMENT     /document refresh → export → artifact          │
│      ↓                                                           │
│  6. UAT GATE      PR dev → main (UAT Checklist signed)           │
│      ↓                                                           │
│  7. UAT DEPLOY    Auto-deploy → sync → health check              │
│      ↓                                                           │
│  7.5 UAT VERIFY   Browser smoke test → feature verify → sign-off │
│      ↓                                                           │
│  8. RELEASE GATE  UAT sign-off APPROVED → tag v*.*.*             │
│      ↓                                                           │
│  9. DEPLOY PROD   Manual sync → rolling update                   │
│      ↓                                                           │
│  10. VERIFY       Health check → smoke test → monitor 30 min     │
│      ↓                                                           │
│  11. OPERATE      Observability → alerts → incident response     │
│      ↓                                                           │
│  12. FEEDBACK     Retro → lessons → Brain update → next sprint   │
│                                                                  │
│  HOTFIX PATH: main → hotfix/* → main → quick UAT → tag → prod    │
│  ROLLBACK: deploy previous revision → sync → verify              │
└──────────────────────────────────────────────────────────────────┘
```

---

## 9. Quick Reference

### Common Git Workflows

**Start a new feature:**
```bash
git checkout dev
git pull origin dev
git checkout -b feature/{{TASK_ID_PREFIX}}-XXX-short-desc
# ... work ...
git add -A && git commit -m "feat(module): description"
git push -u origin feature/{{TASK_ID_PREFIX}}-XXX-short-desc
# Create PR → dev on GitHub
```

**Promote to UAT:**
```bash
# On GitHub: Create PR dev → main
# Fill UAT Deployment Checklist in PR
# Merge → auto-deploy to UAT
```

**Release to Production:**
```bash
git checkout main && git pull origin main
git tag -a v1.X.X -m "Release v1.X.X: summary"
git push origin v1.X.X
# CI retags image → manual sync
```

**Hotfix:**
```bash
git checkout main && git pull origin main
git checkout -b hotfix/{{TASK_ID_PREFIX}}-XXX-desc
# Fix + test
git push -u origin hotfix/{{TASK_ID_PREFIX}}-XXX-desc
# PR → main (expedited) → merge → quick UAT test → tag → prod
# Then: git checkout dev && git merge hotfix/{{TASK_ID_PREFIX}}-XXX-desc
```
