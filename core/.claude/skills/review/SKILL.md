---
name: review
description: "/review — the unified review gate. Use when the user says '/review', '/review design', '/review security', '/review gates', '/review ultra', 'review the UI', 'check design fidelity', 'verify the redesign', 'security review', 'is this safe to merge', 'check for vulnerabilities', 'review the diff', 'review the agent's work', 'run the gates', 'do a thorough/deep review', 'audit the whole diff', 'ultracode review', or after any coding subagent reports DONE. Modes: (1) /review auto-selects the lens(es) from the diff — design (Phase 9 triggers), security (Phase 7 triggers), or quality; (2) /review design runs the 3-lens visual-fidelity gate; (3) /review security runs the diff-aware semantic security pass with false-positive filtering + slopsquatting check; (4) /review gates <TASK_ID> re-runs the full 6-gate post-delegation review; (5) /review ultra runs a Workflow-backed adversarial review across dimensions for a large diff — augments, never replaces, the 6-gate."
user_invocable: true
---

# /review — Unified Review Gate

**Announce:** open your reply with "Using /review [mode] …".

## Token budget

- **Diff-first always.** `git diff --stat` then targeted `git diff <files>` —
  never the whole repo. Screenshot routes lazily (only when you reach a route).
- Reviewer subagents get the diff + spec, not the whole repo. Capture smoke
  output verbatim; re-Read only the failing tail. Don't re-Read root CLAUDE.md.

## Mode dispatch

```
/review               → AUTO-SELECT (§1)
/review design        → 3-lens visual-fidelity gate (§2)
/review security      → semantic security pass (§3)
/review gates <ID>    → 6-gate post-delegation review (§4)
/review ultra [<base>]→ Workflow-backed adversarial review, large diffs (§5)
```

---

## §1 — AUTO-SELECT

Scope the diff, then fire the matching lens(es). State which triggered and why;
if none trigger, say so and stop — do NOT manufacture findings.

```bash
git diff --stat <integration-base>...HEAD
git diff <integration-base>...HEAD
```

- **Phase 9 → design lens (§2):** diff touches UI component / page / layout;
  design tokens / theme / CSS variables; i18n catalogs; responsive breakpoints;
  animations / motion; focus / hover / a11y-visible styling.
- **Phase 7 → security lens (§3):** auth / session / token; password / credential;
  crypto; SQL / query building; HTML rendering of untrusted input; file-path /
  archive extraction; shell / subprocess spawning; deserialization; secret files;
  new external endpoints; SSRF; XXE; prototype pollution; CORS / CSP / cookies;
  regex from user input (ReDoS); committed agent-config (`.claude/settings*.json`,
  `.mcp.json`, `.claude/hooks/*`, `ANTHROPIC_BASE_URL`); **any new dependency in
  a manifest.**
- **Neither → quality lens:** run the Gate 4b reviewers on the diff (see §4).

Canonical trigger definitions: [`../../rules/phase-matrix.md`](../../rules/phase-matrix.md).
Multiple triggers → run multiple lenses (design → security → quality).

---

## §2 — DESIGN lens (`/review design`)

3-lens visual-fidelity gate. **Verdict: PASS / CONDITIONAL / FIX-NOW.**

> Never claim a route passes without an actual Playwright screenshot.
> Structure-only / curl / unit-test-only verdicts are forbidden.

**Scope** — changed routes from the diff, or explicit `/review design /<route>`
or `/review design sprint-S<N>`.

1. **Map routes** — read the active board (`limit: 80`) + git diff; map each
   route to its design-doc spec section.
2. **Capture (Playwright MCP)** — per route: 1440px primary; responsive
   360/768/1024; theme matrix. Save to
   `docs/project/sprints/S<N>/review-shots/<route>-<theme>-<width>.png`.
3. **Automated checks (before the manual lens):** token-leak (semantic tokens
   only, no raw hex); i18n (no hardcoded strings + key parity); a11y (axe-core,
   0 serious/critical); boundary + build (lint 0, `tsc --noEmit` clean, tests
   green); 4-state coverage (empty/loading/error/success).
4. **3-lens checklist per route** — *UX/UI* (layout, spacing, type scale,
   semantic color, all states, responsive, reduced-motion); *Technical* (zero
   raw palette, i18n parity, axe + keyboard + WCAG AA, clean boundaries, authZ
   render guard, idempotency on writes, visual-regression baseline); *Friendly*
   (first impression, cross-route consistency, discoverability, comprehension,
   golden-path).
5. **Thresholds:** UX correctness ≥90% (≥95% if screenshot-diff <5%) else
   FIX-NOW; token leak 0 / i18n gaps 0 / axe serious 0 / boundary-tsc-lint 0 →
   FIX-NOW; Friendly → advisory CONDITIONAL (P3 backlog).
6. **Log findings** to `docs/project/backlog.md` `## Follow-ups`:
   `{{TASK_ID_PREFIX}}-S<N>-FU-DR-<n> | <P1/P2/P3> | [<lens>] <title> | <file:line> | Fix: <…>`.
7. **Verdict + write** the summary to
   `docs/project/sprints/S<N>/review-design-<slug>.md`.
8. **Feedback loop** — recurring finding class → recommend a project rule (don't
   edit rule files; the orchestrator owns wiring).

---

## §3 — SECURITY lens (`/review security`)

Diff-aware semantic pass. **Verdict: PASS / FINDINGS / BLOCK.**

> **Noise is the failure mode.** False-positive filtering is first-class — a
> finding requires a proven source → sink → reachable path. No path → at most
> informational, never blocking.

**Step 0 — Scope.** Same diff commands as §1. If nothing hits a Phase 7 trigger
AND no dependency changed → "no security-relevant surface in this diff" and stop.

**Step 1 — Semantic review (only the dimensions the diff touches):** injection
(SQL/command/LDAP/XPath/NoSQL/XXE) · authN/authZ (IDOR, privilege escalation,
session) · data exposure (secrets, PII in new logs) · crypto (weak algo, non-CSPRNG
tokens) · input validation at a trust boundary with a proven path · business
logic (race / TOCTOU) · config (insecure defaults, headers, CORS, cookie flags) ·
code execution (deserialization / eval) · XSS. Plus:
- **Supply chain (slopsquatting).** Every new manifest dependency: verify it
  **(a)** exists on the official registry, **(b)** is the intended package (not a
  typo / hallucinated near-name), **(c)** is version/hash-pinned, **(d)** is not a
  brand-new low-provenance squat. Can't confirm it exists → **BLOCK.**
- **Agent-config.** Diff touches `.claude/settings*.json` / `.mcp.json` /
  `.claude/hooks/*` or adds `ANTHROPIC_BASE_URL` → run the checklist in
  [`../../../docs/setup/agent-config-security.md`](../../../docs/setup/agent-config-security.md).

For deeper passes, dispatch in one message: `pr-review-toolkit:silent-failure-hunter`
+ a security-focused `senior-tech-lead`, each with the diff.

**Step 2 — Filter false positives (mandatory before reporting).** Drop: DoS /
rate-limiting / resource exhaustion (unless the change IS the control); generic
input-validation with no proven path; open redirects; theoretical issues with no
attacker-controlled reachable path. A finding survives only if you can name the
**source**, the **sink**, and the **path**.

**Step 3 — Report** per surviving finding: severity, `file:line`, source→sink
path, why exploitable, concrete fix. Verdict: **PASS** (none) · **FINDINGS (n)**
(Medium/Low → fix or record explicit deferral in the design doc) · **BLOCK** (any
Critical/High, or a confirmed hallucinated/squatted dependency).

Related: [`../../rules/phase-matrix.md`](../../rules/phase-matrix.md) Phase-7 ·
[`../../../docs/playbooks/post-delegation-review.md`](../../../docs/playbooks/post-delegation-review.md).

---

## §4 — GATES (`/review gates <TASK_ID>`)

Standalone re-run of the full 6-gate post-delegation review. **This same chain
runs automatically inside `/work`** after every coding agent returns — this is
the manual re-run. Canonical procedure:
[`../../../docs/playbooks/post-delegation-review.md`](../../../docs/playbooks/post-delegation-review.md).
Skipping a gate is not permitted.

1. **Inspect** — `git diff --stat` + `git diff <files>`; read the actual diff,
   don't trust the summary. Unauthorized files / scope creep → STOP.
2. **Build + Test** — `<build>` + `<test>` in every touched component; both exit 0.
3. **Boundary** — dispatch `senior-tech-lead` with the diff range + the boundary
   rule; pass = COMPLIANT.
4a. **Spec-compliance (before 4b)** — read code against the design-doc AC list
   (missing / over-built-YAGNI / misread); cross-check diff files vs the matrix.
   Fail → `SendMessage` the implementer the specific gap; don't start 4b.
4b. **Quality (after 4a, single message)** — `pr-review-toolkit:code-reviewer`,
   `:silent-failure-hunter`, `:type-design-analyzer` (+ `:pr-test-analyzer` if
   tests, `:comment-analyzer` if comments).
5. **Wiring** — composition root wired; migrations applied; observability emits;
   contracts updated if event/API shape touched.
6. **Smoke** — `<stack-up>` + `<smoke>`; frontend touched → E2E. Fail →
   `superpowers:systematic-debugging` → fix → re-run Gate 6.

```
=== Post-delegation review ===
Task: {{TASK_ID_PREFIX}}-S<N>.<NN> — <slug>
1 Inspect ✅/❌  2 Build+Test ✅/❌  3 Boundary ✅/❌
4a Spec ✅/❌    4b Quality ✅/❌    5 Wiring ✅/❌   6 Smoke ✅/❌
READY TO MERGE / BLOCKED (gate N failed).
```
UI changed and Gate 6 passed → also run §2 before promoting.

---

## §5 — ULTRA (`/review ultra [<base>]`)

Workflow-backed, adversarially-verified review for a **large / multi-file diff**
or a pre-merge audit. Runs the shipped `fd-review-changes` workflow — fan out one
read-only finder per dimension (bugs · security · types · tests · perf · boundary),
then refute each finding with 3 perspective-diverse skeptics; only findings a
majority **fails** to refute are reported.

> **Why this exists:** at-scale review earns parallel breadth + adversarial
> verification — fewer plausible-but-wrong findings survive. For a normal
> single-task diff, `/review gates` (§4) is cheaper and stays the default.

> **AUGMENTS, does NOT replace, the 6-gate.** The workflow returns a *findings
> list*, never a merge verdict. You (orchestrator) still re-run build/test (Gate 2,
> §4) and own the merge decision. Never let `/review ultra` stand in for §4.

1. **Scope the base** — the `<base>` arg, else the integration base (`<base>...HEAD`).
2. **Run the workflow** — `Workflow({ name: "fd-review-changes", args: { base } })`
   (pass `dimensions` to narrow). It dispatches the finders + verifiers off-context;
   contract + guardrails: [`../../workflows/README.md`](../../workflows/README.md).
3. **Report** the CONFIRMED findings (severity · file:line · evidence · fix). Log
   P1/P2/P3 to `docs/project/backlog.md` `## Follow-ups` and write the summary to
   `docs/project/sprints/S<N>/review-ultra-<slug>.md`.
4. **Close via §4** for the actual merge decision (re-run Gate 2 build/test).

**ultracode:** when ultracode is on, `/review` (§1) prefers ultra for a wide diff.

---

## What to NEVER do

- Report a finding with no reachable, attacker-controlled path (security).
- Claim a route passes without a real Playwright screenshot (design).
- Skip or reorder gates (gates mode).
- Add/approve a dependency you can't confirm exists on the official registry.
- Treat committed agent-config as ordinary config — it is executable.
- Run all lenses when auto-select found no triggers — say so and stop.
- Let `/review ultra` (§5) substitute for the 6-gate merge decision — it returns
  findings, never a merge verdict; always close via §4.
