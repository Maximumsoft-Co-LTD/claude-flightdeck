---
name: design-review
description: "Post-FE-sprint 3-lens design-fidelity gate. Captures real screenshots via Playwright MCP, runs mechanical token / i18n / a11y / boundary checks, scores UX·Technical·Friendly per route, logs backlog findings, returns PASS / CONDITIONAL / FIX-NOW. Use when the user says '/design-review', 'review the UI', 'check design fidelity', 'verify the redesign', or after any frontend sprint and BEFORE bumping the meta submodule pointer / promoting."
user_invocable: true
---

# /design-review — 3-Lens Design-Fidelity Gate

> **Announce on start:** open your reply with "Using /design-review to run the 3-lens fidelity gate."

Compare the **implemented UI** against its intended design (the design spec section + the project's established UI conventions). Produce a scorecard, prioritized findings, auto-logged backlog items, and a **PASS / CONDITIONAL / FIX-NOW** verdict.

## Why this gate exists (the lesson, baked in)

A redesign can pass thousands of unit tests + type-check + lint + a structural "phase gate" and still ship a wrong UI: token leakage flips a dark app to light, density is off, status labels are raw English instead of localized. **Root cause:** the review verified STRUCTURE + FUNCTION (DOM tree, unit tests, build) but never VISUAL FIDELITY (real screenshots, token coverage, theme/i18n correctness).

**Green unit / type / lint ≠ correct UI.** This gate forces a real-browser capture + mechanical checks that a structural snapshot is blind to.

## When to run

- After **every frontend sprint / feature**, BEFORE bumping the meta submodule pointer / promoting — a gate, not a courtesy.
- Ad-hoc on one route: `/design-review /<route>`.
- Input parsing:
  - `/design-review` → auto-detect changed routes (`git diff --stat <base>...HEAD -- 'src/app/**' 'src/features/**' 'src/widgets/**'` or the equivalent for your project's structure)
  - `/design-review sprint-S<N>` → review the named sprint's changed routes
  - `/design-review <route>` → one route

## Token budget

- **Capture lazily** — screenshot a route only when you reach it in Step 2.
- **Never `Read` whole page / feature components** — use Grep for token / string leakage + LSP `documentSymbol` for structure.
- Do NOT re-Read root CLAUDE.md (session-loaded). The token allowlist is in the Appendix of the project's frontend rules.

## Steps

0. **Create gate task list (TaskCreate):**
   - `"Design Review — Scope changed routes"`
   - `"Design Review — Capture screenshots (theme × responsive)"`
   - `"Design Review — Automated checks (token-leak / i18n / a11y / boundary / tsc)"`
   - `"Design Review — 3-Lens checklist per route"`
   - `"Design Review — Score + log findings + verdict"`
   - `"Design Review — Write report"`
   Update each as you progress.

### Step 1 — Scope (which routes changed)

1. Read the active sprint file task table with `limit: 80` → routes touched.
2. `git diff --stat <base-branch>...HEAD -- '<frontend-src>/**'` → changed route / feature set.
3. Map each route → its implementation path + spec section.

### Step 2 — Capture (Playwright MCP — real browser, not curl)

> A SPA needs a real browser; `curl` returns the empty app shell. Structure-only verdicts are forbidden (see Rules).

1. Prefer the existing real-backend E2E harness — it already builds the app + seeds + drives login.
2. For each in-scope route, navigate + screenshot at **1440px** (primary) plus **responsive 360 / 768 / 1024**.
3. **Theme matrix** — capture each supported theme. If the app supports dark mode, capture both light and dark to verify token flow.
4. Save to `docs/spec/reviews/_shots/sprint-S<N>/<route>-<theme>-<width>.png`.

### Step 3 — Automated checks (cheap, run first)

1. **Token-leak scan** — UI must use **semantic** tokens (the project's design system), NOT raw palette or hex. Scope MUST include every layer where user-facing tokens are rendered (pages / features / widgets / entities / shared/ui). Each hit is a finding.
2. **i18n / hardcoded-string scan** — no user-facing literal strings; everything via the project's i18n helper. Confirm **key parity** across every locale (every key in `<base-locale>` exists in every other locale — diff the key sets).
3. **a11y (axe-core)** — run on each captured route via Playwright; **0 serious / critical** violations is the bar.
4. **Boundary + build / type gates** — `lint` 0 errors; `tsc --noEmit` clean; `test` green. (Note if already run this sprint — don't rerun needlessly.)
5. **4-state coverage** — every data view must render empty / loading / error / success.

### Step 4 — The 3-Lens checklist (score each route)

**UX/UI lens — visual correctness:**
- [ ] Layout structure matches the intended design (regions, columns, ordering per spec).
- [ ] Spacing / density consistent with sibling routes; on the project's spacing scale.
- [ ] Typography — sizes / weights from the scale; hierarchy clear.
- [ ] Color via semantic tokens (Step 3.1 clean); accent / primary used, not a hardcoded color.
- [ ] All states present — empty / loading / error / hover / selected / focus.
- [ ] Responsive at 360 / 768 / 1024 / 1440 — no overflow, no broken wrap.
- [ ] Motion / transitions sane + honors `prefers-reduced-motion`.

**Technical lens — engineering correctness:**
- [ ] **Token discipline — ZERO raw palette / hex** (Step 3.1 returns nothing for this route).
- [ ] **i18n — no hardcoded strings; locale key parity** (Step 3.2).
- [ ] a11y — axe 0 serious / critical + keyboard nav + visible focus + landmarks + WCAG AA contrast (4.5:1).
- [ ] **Architectural boundary** — no upward / sideways imports (project's boundary rule).
- [ ] **AuthZ render** — protected routes guarded; never trusts the client for authz.
- [ ] **Idempotency** on write flows — the client mints a stable Idempotency-Key.
- [ ] **Visual-regression baseline exists** for the route (Playwright snapshot).
- [ ] No magic values (raw px / hex in className or style).

**Friendly lens — Nielsen heuristics + persona walkthrough:**
- [ ] First impression — does it look intentional + consistent with the rest of the app?
- [ ] Cross-route consistency — no jarring spacing / token shift when navigating between routes.
- [ ] Discoverability — primary actions findable; affordances clear.
- [ ] Comprehension — friendly, localized labels; no internal jargon / raw enum codes.
- [ ] Golden-path walkthrough — run the route's main task end-to-end; note friction.

### Step 5 — Score & thresholds

| Gate | Threshold | Failure → |
|---|---|---|
| UX/UI visual correctness | ≥ 90% (≥ 95% once a screenshot baseline gives diff < 5%) | FIX-NOW if < 90% |
| Token leakage (raw palette / hex) | 0 | FIX-NOW |
| i18n key parity + no hardcoded strings | 0 gaps | FIX-NOW |
| axe serious / critical | 0 | FIX-NOW |
| Boundary / tsc / lint | 0 errors | FIX-NOW |
| Friendly / polish | advisory | CONDITIONAL (P3 backlog) |

### Step 6 — Log findings (auto-append to backlog)

For each finding, append to `docs/spec/backlog.md` under the sprint's follow-up section:
- `{{TASK_ID_PREFIX}}-S<N>-FU-DR-<n> | <P1/P2/P3> | [<lens: UX/Technical/Friendly>] <title> | impl <file:line> | Fix: <precise fix>`.
- Token-leak / i18n-gap / parity<90% / axe-serious / boundary-violation → **P1**. Group by lens in the report.

### Step 7 — Verdict

- **PASS** — all gates met → bump pointer / promote.
- **CONDITIONAL** — gates met; only Friendly / polish findings → promote + file P3 backlog items.
- **FIX-NOW (blocks promote)** — any of: visual correctness < 90%, token leakage, i18n gap, axe serious / critical, boundary / tsc / lint error.

### Step 8 — Report

Write `docs/spec/reviews/sprint-S<N>-design-review.md`:
- Scorecard table (route × lens × score + overall).
- Per-route findings grouped by lens, with impl `file:line` + precise fix.
- Verdict + the backlog IDs filed. Screenshot paths (`_shots/sprint-S<N>/...`).

### Step 9 — Feedback loop

If a finding **class recurs**, in the report:
- Recommend promoting a project rule (e.g. "rule: UI uses semantic tokens only; raw palette / hex banned in pages / features / widgets").
- Recommend a `docs/setup/lesson-trigger-map.md` entry if one exists.
- **Do NOT edit those files** — only recommend; the orchestrator owns wiring them in.

## Anti-patterns this gate catches

- Raw palette / hex leakage instead of semantic tokens → breaks theming + consistency.
- Hardcoded user-facing strings (not via i18n helper) / missing locale key → wrong-language UI, build can't catch it.
- Green unit / type / lint but wrong / broken UI — the structural-snapshot blind spot.
- Structure-only / accessibility-tree-only verdict — blind to color, spacing, density, theme.
- Missing 4-state — no empty / loading / error handling; `null` list crashes instead of empty state.
- Boundary violation — feature importing feature, upward import; boundary-linter blind spot if not run.
- No visual-regression baseline — nothing pins the pixels against regression.

## Rules

- **Never claim a route passes without an actual Playwright screenshot capture.** Structure-only / curl / unit-test-only verdicts are forbidden — that is the exact failure this gate replaces.
- Run Step 3 automated checks BEFORE the manual lens review — they catch the mechanical bugs cheaply.
- **Token leakage, i18n gap, visual correctness < 90%, axe serious / critical, or boundary / tsc / lint error → FIX-NOW → blocks the submodule-pointer bump / promote.** No "ship and polish later" for these classes.
- Every finding lands in `docs/spec/backlog.md` with a precise fix + impl `file:line` — no vague "improve spacing".
- Feedback loop (Step 9) recommends rule / lesson edits but does not make them.
