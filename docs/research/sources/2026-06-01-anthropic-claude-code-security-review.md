---
url: https://github.com/anthropics/claude-code-security-review
title: "claude-code-security-review — AI-powered security review GitHub Action + /security-review slash command"
type: repo
author: Anthropic
date_found: 2026-05-31
date_processed: 2026-06-01
topics: [claude-code-core, sdlc-with-ai]
quality: 5
status: distilled
---

## TL;DR
- Anthropic's **official** security-review tool. Claude Code ships a built-in
  `/security-review` slash command that runs "a comprehensive security review
  of all pending changes"; the same logic is also packaged as a GitHub Action.
- **Diff-aware:** for PRs it "only analyzes changed files" — reviews the diff
  in context, not the whole repo. (Matches our gate philosophy.)
- **Semantic, not regex:** "uses Claude's advanced reasoning … with deep
  semantic understanding," explicitly positioned as *better than traditional
  SAST* — "understands code semantics and intent, not just patterns," yielding
  "lower false positives."
- **False-positive filtering is a first-class, dedicated step** (`findings_filter.py`
  + a Claude API call). It "automatically excludes a variety of low-impact and
  false-positive-prone findings to focus on high-impact vulnerabilities" and is
  tunable per project.
- Each finding ships with a **severity rating + remediation guidance**.

## Key takeaways
- The vuln taxonomy it scans (10 families): **Injection** (SQL/command/LDAP/
  XPath/NoSQL/XXE); **AuthN/AuthZ** (broken auth, privilege escalation, IDOR,
  session flaws); **Data exposure** (hardcoded secrets, sensitive logging, PII);
  **Crypto** (weak algos, key mgmt, insecure RNG); **Input validation**;
  **Business logic** (race / TOCTOU); **Config** (insecure defaults, headers,
  permissive CORS); **Supply chain** ("vulnerable dependencies, typosquatting
  risks"); **Code execution** (deserialization / pickle / eval); **XSS**.
- The **auto-excluded** low-signal classes (the FP filter): DoS, rate-limiting,
  memory/CPU exhaustion, "generic input validation without proven impact," open
  redirects. → the principle: *a finding needs a proven reachable impact, not a
  pattern match.*
- The slash command is customizable — copy `.claude/commands/security-review.md`
  into the project and add org-specific directions.

## Quotes / evidence
> "Diff-Aware Scanning: For PRs, only analyzes changed files."
> "Goes beyond pattern matching to understand code semantics and intent, not
> just patterns."
> "automatically excludes a variety of low-impact and false-positive-prone
> findings to focus on high-impact vulnerabilities."

## Relevance to our template
- **Could affect:** we have **no dedicated `/security-review` skill**. Phase 7
  (Security review) exists in `phase-matrix.md` only as a *trigger list* + a
  vague "dispatch silent-failure-hunter + senior-tech-lead" instruction — no
  runnable procedure. This is the seed to operationalize it.
- **Lift:** the diff-aware + semantic + **FP-filter-as-a-step** design, the
  10-family taxonomy, severity+remediation output.
- **Connects to:** [[security-review-as-a-skill]] (synthesis);
  [[committed-agent-config-is-a-supply-chain-surface]] (agent-config is one
  dimension); the slopsquatting source for the supply-chain dimension.
- **Open questions:** ship a hook too, or keep it a skill + review-gate? (Synth:
  skill now; prompt-injection hook stays opt-in like the tdd-guard hook.)
