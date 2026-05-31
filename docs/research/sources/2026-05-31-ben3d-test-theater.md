---
url: https://ben3d.ca/blog/the-rise-of-test-theater
title: "The rise of test theater"
type: blog
author: ben3d.ca
date_found: 2026-05-30
date_processed: 2026-05-31
topics: [sdlc-with-ai]
quality: 4
status: distilled
---

## TL;DR
- **AI-generated tests tend to validate *current* behavior (bugs included),
  not *intended* behavior** — they pass, look thorough, and assert little.
- Common shapes: asserting the mock was called, snapshot-everything,
  tautologies, happy-path-only. The suite is green theater.

## Key takeaways
- The failure isn't "too few tests" — it's tests that don't *constrain*
  behavior. Coverage % goes up while real protection stays flat.
- The fix is intent: a test must fail for a nameable reason, and it must have
  been red before the code existed (or, for a fix, red on the pre-fix code).

## Relevance to our template
- **Could affect:** our TDD pre-flight + Gate 4b. A001 demands a failing test
  first but we never defined *what makes the test worth writing*. Add a
  test-theater anti-pattern list to `programming-fundamentals.md` and a
  test-theater rejection step to Gate 4b (`pr-test-analyzer`).
