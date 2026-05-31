---
url: https://understandlegacycode.com/blog/characterization-tests-or-approval-tests/
title: "Characterization tests or approval tests?"
type: blog
author: understandlegacycode.com (Nicolas Carlo)
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [legacy-modernization, sdlc-with-ai]
quality: 4
status: distilled
---

## TL;DR
- On legacy code you don't yet understand, **pin current behavior with a
  characterization test BEFORE changing anything** (Feathers). It locks
  *behavior*, not correctness — a safety net that makes change visible.
- Approval / golden-master testing is the mechanic when output is large:
  capture an approved snapshot, diff future runs against it.
- Companion piece: lock behavior with characterization tests before an AI
  refactor — silent behavioral drift is the #1 risk.

## Key takeaways
- Characterization ≠ regression ≠ intent test. Characterization captures "what
  it does now"; you label it as such and don't mistake it for a spec.
- This is the legacy-safe answer to "TDD needs tests we don't have": you write
  *one* test around the change site, you don't retrofit a whole suite.

## Relevance to our template
- **Could affect:** the legacy concern directly. The TDD guard must switch to
  characterization-first on untested code rather than demanding greenfield TDD
  (which would block work). Encode in `test-discipline.md` + the phase-matrix
  TDD row + the programming-fundamentals legacy branch.
- Supporting: isaqb "AI agents don't modernize legacy code on their own"
  (seams + characterization + fitness functions before autonomy); ApprovalTests
  (polyglot golden-master libs).
