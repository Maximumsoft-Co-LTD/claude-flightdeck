---
topic: security-review-as-a-skill
track: claude-code-core
sources:
  - ../../sources/2026-06-01-anthropic-claude-code-security-review.md
  - ../../sources/2026-06-01-slopsquatting-package-hallucination.md
  - ../../sources/2026-05-31-cve-2025-59536-claude-config-rce.md
supporting:
  - https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/
  - https://semgrep.dev/blog/2025/building-an-appsec-ai-that-security-researchers-agree-with-96-of-the-time/
  - https://www.microsoft.com/en-us/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks
  - https://blog.google/security/mitigating-prompt-injection-attacks/
  - https://github.com/trailofbits/skills
  - https://github.com/lasso-security/claude-hooks
date: 2026-06-01
confidence: high
---

## Pattern observed
Phase 7 (Security review) is the **only review phase in our matrix with no
runnable procedure.** It lists ~16 triggers, then says "the orchestrator
decides; dispatch silent-failure-hunter + a security-focused senior-tech-lead."
Every other discipline (TDD, design-review, the 6 gates) has a concrete skill;
security does not. Meanwhile the field has converged on what an *effective* AI
security review looks like — and Anthropic ships the reference:

1. **Diff-aware** — review the changed hunks in context, not the whole repo
   (anthropics/claude-code-security-review; matches our gate philosophy).
2. **Semantic, not regex** — reason about whether a path is actually reachable
   and attacker-controlled, vs. pattern-matching strings. Explicitly positioned
   as "better than traditional SAST" with "lower false positives." Semgrep's own
   data agrees: LLM triage matched human researchers 96% of the time.
3. **False-positive filtering as a first-class step** — auto-exclude the
   low-signal classes (DoS, rate-limiting, generic input-validation w/o proven
   impact, open redirects). *A finding needs a proven source→sink→reachable
   path, not a smell.* This is the difference between a gate the team uses and
   one they learn to ignore.
4. A **stable vuln taxonomy** (injection, authn/z, data exposure, crypto, input
   validation, business logic, config, **supply chain**, code execution, XSS) +
   severity + remediation per finding.

Two dimensions are ones we already half-have or newly need:
- **Agent-config** is a security dimension we already documented
  ([[committed-agent-config-is-a-supply-chain-surface]] → `agent-config-security.md`)
  but only as a *trigger*; the review should run its checklist.
- **Slopsquatting** is the new AI-specific supply-chain vector: ~19.7% of
  LLM-suggested packages don't exist, attackers squat the hallucinated names, and
  *our own engineers add dependencies routinely.* An agent-suggested package you
  can't confirm exists is an install-time RCE waiting to happen.

## Why it matters for our SDLC
This is the **review (S5) / Phase-7** stage. The template's pitch is "safe by
default." We ship the agent-config RCE surface (already gated) but have no
*procedure* for the security review that's supposed to run on auth/crypto/SQL/
secrets/deserialization/etc. diffs — so in practice it's skipped or done ad-hoc.
Operationalizing it as `/security-review` (the same move we just made for
`/tdd` ← `test-discipline.md`) turns a passive trigger list into a repeatable,
low-noise pass that fires automatically on Phase-7 triggers and on demand.

## Proposed template change
- **Type:** new-skill + rule-update + doc cross-link
- **Target file(s):**
  - `core/.claude/skills/security-review/SKILL.md` — NEW. Diff-aware + semantic
    review across the 10-family taxonomy (only the dimensions the diff touches);
    **FP-filter as an explicit Step**; **supply-chain/slopsquatting** dimension
    (verify new deps exist + are intended + pinned); **agent-config** dimension
    (runs the `agent-config-security.md` checklist); severity+remediation output;
    PASS / FINDINGS / BLOCK verdict. Notes an **opt-in** prompt-injection
    PostToolUse hook (lasso-security/claude-hooks) — not shipped by default,
    same posture as the tdd-guard hook.
  - `core/.claude/rules/phase-matrix.md` — Phase-7 section: invoke
    `/security-review`; add **new dependency in a manifest** to the trigger list.
  - `core/docs/setup/agent-config-security.md` — note the Phase-7 review now runs
    via `/security-review` (agent-config = one dimension).
  - `core/docs/INDEX.md` — cheat-sheet row + counts.
- **Friction-or-quality:** **quality / risk** — gives the existing security gate
  a real procedure; the FP-filter keeps it from becoming noise; slopsquatting
  closes a live install-RCE gap. Fires only when a Phase-7 trigger is in the diff.

## Counter-evidence / risks
- **Noise is the failure mode** — a security gate that over-reports gets ignored.
  Mitigated by making FP-filtering a mandatory step (drop unproven/low-impact).
- Keep `core/` de-domain-specified — generic vuln classes + generic manifest
  filenames only, no stack opinions.
- Don't ship a mandatory injection hook — a committed hook is itself an RCE
  surface (agent-config-security.md); keep it opt-in, default = rule + gate.
- Proportionality: one skill + a trigger line + cross-links, not a heavyweight
  security program.

## Status
- [x] Proposed (this note)
- [x] Shipped → [../../apply/shipped/security-review-skill.md](../../apply/shipped/security-review-skill.md)
