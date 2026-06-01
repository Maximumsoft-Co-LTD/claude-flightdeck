---
url: https://arxiv.org/abs/2406.10279
title: "Package hallucination / slopsquatting — LLM-recommended packages that don't exist, and the squatting attack on them"
type: paper
author: Spracklen et al. (USENIX Security 2025); + Snyk slopsquatting mitigation guide
date_found: 2026-05-30
date_processed: 2026-06-01
topics: [software-tech, sdlc-with-ai]
quality: 5
status: distilled
---

## TL;DR
- **~19.7% of packages recommended by LLMs do not exist** (large-scale study,
  USENIX Security 2025, arXiv 2406.10279). Code-gen models routinely invent
  plausible-but-fake dependency names.
- **Slopsquatting** (Snyk): attackers harvest these hallucinated names and
  **register them** on public registries (npm/PyPI/…) with malicious payloads.
  When a developer (or a coding agent) trusts the LLM's suggestion and installs
  it, the malicious package runs — supply-chain RCE at install time.
- The hallucinations are **repeatable** (the same fake name recurs across
  prompts), which makes the squat reliable to pre-position. This is a *new*,
  AI-specific supply-chain vector distinct from classic typosquatting.

## Key takeaways
- The actor most exposed is exactly a **coding agent that adds dependencies**:
  it suggests an import → adds it to the manifest → installs it, often without a
  human verifying the package is real.
- Defenses (Snyk + general): (1) **verify every newly-added dependency actually
  exists** on the official registry and is the *intended* package — not a typo
  or hallucinated near-name of a popular lib; (2) **pin versions** (lockfiles,
  hashes); (3) cross-check against a known-good allowlist / the project's
  existing deps; (4) be suspicious of brand-new, low-download packages a model
  "recommended"; (5) prefer well-known, high-provenance packages.
- This is **the supply-chain dimension** of a security review on any diff that
  touches a dependency manifest (`package.json`, `go.mod`, `requirements.txt`,
  `Cargo.toml`, `pyproject.toml`, `Gemfile`, …).

## Quotes / evidence
> "~19.7% of recommended packages were hallucinations" — Spracklen et al.,
> USENIX Security 2025.
> Slopsquatting = "registering AI-hallucinated package names" so the install of
> a trusted-looking suggestion delivers attacker code (Snyk).

## Relevance to our template
- **Could affect:** our engineers (`backend-engineer` / `frontend-engineer`) add
  dependencies as a matter of course; nothing in the control plane verifies a
  newly-added package is real before it lands. A hallucinated name that an
  attacker has squatted = RCE on install.
- **Lift:** a **supply-chain (slopsquatting) dimension** in the `/security-review`
  skill + a `new dependency in a manifest` entry in the Phase-7 trigger list:
  *an agent-suggested package you can't confirm exists is a STOP.*
- **Connects to:** [[security-review-as-a-skill]] (synthesis); the official
  claude-code-security-review note (its taxonomy already lists "typosquatting
  risks" under Supply chain).
- **Open questions:** mechanical check (query the registry) vs review-gate
  judgment? Synth: review-gate first (verify-it-exists is a human/agent step);
  a registry-lookup script can come later if noise warrants.
