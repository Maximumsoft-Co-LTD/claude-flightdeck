---
name: security-review
description: "Run a semantic, diff-aware security review of pending changes — and verify any newly-added dependency is real (slopsquatting / package-hallucination). Use when the user says '/security-review', 'security review', 'is this safe to merge', 'check for vulnerabilities', 'review for security'; when Phase 7 of the phase matrix fires (a diff touches auth / session / token / crypto / SQL or query-building / untrusted HTML / file-path or archive / shell or subprocess / deserialization / SSRF / XXE / CORS-CSP-cookies / ReDoS / secret-bearing files / a new external endpoint / committed agent-config); or when a new package is added to a dependency manifest. Filters false positives so it stays signal, not noise."
user_invocable: true
---

# /security-review — Phase-7 Security Review (diff-aware · semantic · low-noise)

> **Announce on start:** open your reply with "Using /security-review to run a semantic security pass on the pending diff."

Operationalizes **Phase 7 (Security review)** of [`phase-matrix.md`](../../rules/phase-matrix.md). Reviews the **pending diff** (not the whole repo), **semantically** (reason about real exploitability — not regex/pattern matching), and **filters false positives** so the gate stays usable.

## Why this exists (the lesson, baked in)

- Phase 7 existed only as a *trigger list* + a vague "dispatch silent-failure-hunter + senior-tech-lead." Every other discipline (TDD, design-review, the 6 gates) has a runnable procedure; security didn't. This makes it concrete and repeatable.
- **Noise is the failure mode of an AI security review.** Flag low-impact / unexploitable issues and the team learns to ignore the gate. So **false-positive filtering is a first-class step** (per Anthropic's own claude-code-security-review, which auto-excludes DoS / rate-limiting / generic-validation / open-redirect classes). A finding needs a *proven source → sink → reachable path*, not a smell.
- **Semantic, not pattern.** Regex SAST flags strings; this reasons about whether the path is actually reachable and attacker-controlled. (Anthropic positions this as "better than traditional SAST, lower false positives"; Semgrep's LLM triage matched human researchers 96% of the time.)
- **The newest, AI-specific class — slopsquatting.** ~19.7% of LLM-recommended packages don't exist (USENIX Security 2025); attackers register those hallucinated names. A coding agent that adds a dependency is exactly the actor at risk — so a dependency-diff check is a dimension here.

## Token budget (MANDATORY)

- **Diff-first.** `git diff` the branch / pending changes; review the changed hunks + just enough surrounding context to judge reachability. Never read the whole repo.
- Dispatch deep dimension work to reviewers (`pr-review-toolkit:silent-failure-hunter`, `senior-tech-lead`) with **the diff + the specific dimension**, not the repo.
- **Ships no scripts.** The optional prompt-injection hook (Step 4) is opt-in and NOT shipped by default — a committed hook is itself an execution surface.

## When it fires

- **On demand:** `/security-review` (or `/security-review <path>` to scope one area).
- **Automatically (Phase 7):** when the diff touches any trigger in [`phase-matrix.md`](../../rules/phase-matrix.md) — auth/session/token, crypto, SQL/query-building, untrusted HTML, file-path/archive, shell/subprocess, deserialization, SSRF, XXE, prototype pollution, CORS/CSP/cookies, ReDoS, secret-bearing files, new external endpoint, **committed agent-config**, or **a new dependency in a manifest**.

## Step 0 — Scope the diff

```bash
git diff --stat <integration-base>...HEAD     # what changed
git diff <integration-base>...HEAD            # read the hunks
```

List changed files; map each to the trigger(s) it hits. **If nothing hits a trigger AND no dependency changed → report "no security-relevant surface in this diff" and stop.** Do not manufacture findings to look thorough.

## Step 1 — Semantic review (only the dimensions the diff actually touches)

Reason about exploitability per family — for each, find the **source** (attacker-controlled input), the **sink** (dangerous operation), and whether a path connects them:

- **Injection** (SQL / command / LDAP / XPath / NoSQL / XXE) — is untrusted input concatenated into an interpreter, or parameterized?
- **AuthN / AuthZ** — broken auth, privilege escalation, IDOR, session: does the change trust the client, skip an ownership/scope check, or widen access?
- **Data exposure** — hardcoded secrets, secrets/PII in new log lines, information disclosure. Grep the diff for secrets.
- **Crypto** — weak algorithm, bad key management, insecure RNG (e.g. non-CSPRNG for tokens).
- **Input validation** — missing/incorrect sanitization at a trust boundary (only when it has a proven impact — see Step 2).
- **Business logic** — race conditions, TOCTOU.
- **Config** — insecure defaults, missing security headers, permissive CORS, cookie flags.
- **Code execution** — deserialization / pickle / `eval` of untrusted input.
- **XSS** — reflected / stored / DOM-based.
- **Supply chain (slopsquatting / package hallucination)** — for **every new dependency** in a manifest diff (`package.json`, `go.mod`, `requirements.txt`, `Cargo.toml`, `pyproject.toml`, `Gemfile`, …): verify the package **(a) actually exists** on the official registry, **(b) is the intended one** (not a typo or hallucinated near-name of a popular library), **(c) is version/hash-pinned**, **(d) isn't a brand-new low-provenance squat.** *An agent-suggested package you cannot confirm exists is a STOP, not a finding to soften.*
- **Agent-config** — if the diff touches `.claude/settings*.json` / `.mcp.json` / `.claude/hooks/*` or introduces `ANTHROPIC_BASE_URL` / `enableAllProjectMcpServers`: run the reviewer checklist in [`agent-config-security.md`](../../../docs/setup/agent-config-security.md) (it's an RCE surface on every teammate's machine).

For deeper passes, dispatch in a single message: `pr-review-toolkit:silent-failure-hunter` (error-swallow / exfil paths) + `senior-tech-lead` (security-focused boundary read), each with the diff.

## Step 2 — Filter false positives (FIRST-CLASS — this is what keeps the gate usable)

Before reporting, **drop the low-signal classes** (the exact filter Anthropic's claude-code-security-review applies):

- Denial-of-Service / rate-limiting / memory-CPU exhaustion — *unless the change IS the security control.*
- Generic input-validation with **no proven exploit path**.
- Open redirects.
- Theoretical issues with no attacker-controlled, reachable path.

> A finding survives **only** if you can name the **source**, the **sink**, and the **path** between them. No reachable path → at most an informational note, never a blocking finding. (If you confirmed a dependency doesn't exist / is squatted, that is *not* filtered — it's a real, high-severity finding.)

## Step 3 — Report (severity + remediation per finding)

For each surviving finding: **severity** (Critical / High / Medium / Low), `file:line`, the **source → sink path**, *why* it is exploitable, and a **concrete fix**. End with a verdict:

- **PASS** — no surviving findings.
- **FINDINGS (n)** — Medium/Low only → fix or record an explicit deferral in the task's design doc / STATUS row.
- **BLOCK** — any **Critical/High** in the diff, or a **confirmed hallucinated/squatted dependency** (install-time RCE). Fix → re-run this skill.

## Step 4 — Optional: prompt-injection defense hook (OPT-IN · NOT shipped)

Our subagents fetch web pages, docs, and tool output — **indirect prompt injection** is a real risk for any agent that ingests untrusted content. Teams wanting mechanical defense can add a PostToolUse scanning hook (e.g. [`lasso-security/claude-hooks`](https://github.com/lasso-security/claude-hooks)) to their own `.claude/hooks/`. The template does **not** ship this by default, by design:

- A committed hook is itself a code-execution surface — review it per [`agent-config-security.md`](../../../docs/setup/agent-config-security.md) before adopting.
- Default posture is **rule + review-gate**, not a mandatory runtime layer. Defense-in-depth references: Microsoft & Google layered injection defenses, the OWASP Top 10 for Agentic Applications.

## What to NEVER do

- ❌ Report a "finding" with no reachable, attacker-controlled path — that's the noise that gets the gate ignored.
- ❌ Review the whole repo when only a diff changed (Step 0 scopes it).
- ❌ Add or approve a dependency you can't confirm exists on the official registry (slopsquatting → install-time RCE).
- ❌ Treat a committed hook / `.mcp.json` / `settings*.json` change as ordinary config — it's executable (run the agent-config checklist).
- ❌ Pass a diff that still carries an unremediated Critical/High.

## Related

- [`../../rules/phase-matrix.md`](../../rules/phase-matrix.md) — the Phase-7 trigger list this fires on (canonical).
- [`../../../docs/setup/agent-config-security.md`](../../../docs/setup/agent-config-security.md) — the agent-config dimension + its reviewer checklist.
- [`../../../docs/playbooks/post-delegation-review.md`](../../../docs/playbooks/post-delegation-review.md) — the 6-gate review; this runs as Phase 7 alongside it (UI → also `/design-review`).
- [`../../../docs/setup/secret-handling.md`](../../../docs/setup/secret-handling.md) — the `secret-redact` hook + `ANTHROPIC_BASE_URL` exfil.
- `superpowers:systematic-debugging` — to confirm an exploit path before reporting it.
