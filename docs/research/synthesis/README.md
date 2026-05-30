# synthesis/ 🔵 Synthesize

Where individual reads become a **pattern**. A synthesis note answers:
"across everything I've read on X, what's actually true and what should we
do about it?" — not "here's a summary of three articles."

## When to write one

[Gate 2](../METHODOLOGY.md#gate-2--process--synthesize-sources--synthesis):
- **≥3 independent `sources/` notes** point the same way, **or**
- **1 primary source** (quality 5) is authoritative on its own.

## How

1. Pick the right taxonomy folder:
   - `claude-code-core/`
   - `adjacent-tools/`
   - `sdlc-with-ai/`
   - `legacy-modernization/`
   - `complex-systems/`
   - `software-tech/`
2. Copy [`_template.md`](_template.md) to `<topic>/<slug>.md`.
3. List the `sources:` you're drawing from (paths into `sources/`).
4. State the **pattern**, then the **proposed template change** with a
   target file. Set a `confidence:` — be honest.
5. Record **counter-evidence** — what would make this wrong.

## The output that matters

Every synthesis should end pointing somewhere: either a concrete
`apply/proposed/` candidate (it named a file → [Gate 3](../METHODOLOGY.md#gate-3--synthesize--apply-synthesis--proposed-change)),
or an explicit "not actionable yet, need X." A synthesis with no next step
is a summary — push it until it has one or park it.

## Confidence levels

- `low` — plausible, thin evidence, watch for more
- `medium` — solid pattern, some unknowns
- `high` — well-supported, ready to act → candidate for `apply/`
