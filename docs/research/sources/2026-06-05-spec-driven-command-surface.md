---
url: (deep-research synthesis — primary sources listed below)
type: research-study
date_found: 2026-06-05
date_processed: 2026-06-05
topics: [claude-code-core, sdlc-with-ai]
quality: 5
status: distilled
---

## TL;DR

Multi-source study (spec-kit · Kiro · BMAD · Tessl · Anthropic skills) on the
minimal-but-rigorous command surface for spec-driven AI workflows. Leaders
converge on **few core commands + optional validation**, a **spec→design→tasks
artifact spine**, **one self-contained numbered folder per unit** as single
source of truth, and **tiering rigor by task size**.

## Key takeaways (adversarially verified, 3-0 unless noted)

- **GitHub spec-kit** ships ~9 commands but the design-before-code spine is a
  **5-command core** (constitution → specify → plan → tasks → implement); the
  rest (clarify, analyze, checklist, …) are *optional guardrails*.
- **Single source of truth = one numbered self-contained folder per feature**
  (`specs/NNN-feature/` co-locating spec/plan/tasks + research/data-model/contracts).
- **AWS Kiro** = a 3-doc spine (`requirements.md → design.md → tasks.md`) under
  `.kiro/specs/<feature>/`, project-level steering kept separate. **EARS**
  notation ("WHEN … THE SYSTEM SHALL …") makes the requirements tier verifiable.
- **BMAD** (12+ personas / 34+ workflows) is the cautionary maximalist case — but
  its **Scale-Adaptive Level 0-4** confirms **tiering depth by task complexity**.
- Caveat (verified): spec-kit/Kiro enforce design-first by **ordering, not a hard
  lock** → a hard review-gate is a deliberate ADDITION, not something they do.
- Caveat: the Anthropic skill-budget / progressive-disclosure claims were
  *unverified* in this run (fetch gaps), not refuted — our existing
  `skill-authoring.md` already encodes them; treat as our own convention.

## Primary sources

- github.com/github/spec-kit · kiro.dev/docs/specs · github.com/bmad-code-org/BMAD-METHOD
- tessl.io/blog · martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (unverified this run)

## Relevance to our template

Direct driver for the lean-workflow redesign: collapse to a small verb set, keep
design-first + the 6-gate as our deliberate rigor, and tier the design-doc
templates by size. → [[lean-workflow-redesign]].
