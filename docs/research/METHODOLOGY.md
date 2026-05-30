# Methodology

How we decide what's worth keeping, when to move something forward, and how
research becomes a template change. Keep this honest — the value of the
library is the filtering, not the volume.

## Source quality score (1–5)

Assign on first read. Write it in the source note's `quality:` frontmatter.

| Score | Meaning | Examples |
|---|---|---|
| **5** | Primary source / original research | Anthropic docs & engineering blog, the actual repo's README, a maintainer's RFC, a published paper |
| **4** | Recognized practitioner / production case study | Named engineer with a track record, a real post-mortem, a conference talk with data |
| **3** | Quality opinion with evidence | A thoughtful blog post, a good talk, a well-argued thread |
| **2** | Anecdotal but interesting | A single tweet, an unverified claim, a "works for me" note |
| **1** | Noise | Listicles, SEO content, AI-spun filler — **archive, don't process** |

> Rule: anything scoring **1** never leaves the inbox. Mark it `archived`
> with a one-word reason and move on.

## The three gates

### Gate 1 — Capture → Process (inbox → sources)

A link earns a `sources/` note only if **all** are true:
- Quality ≥ 2
- You actually intend to read it closely (not "someday")
- It plausibly touches one of the 6 taxonomy tracks

Everything else stays in the inbox or gets archived. No guilt.

### Gate 2 — Process → Synthesize (sources → synthesis)

A topic earns a `synthesis/<topic>/*.md` note only when:
- **≥ 3 independent sources** point the same direction, **OR**
- **1 primary source** (quality 5, e.g. official Anthropic docs) is authoritative on its own

This prevents over-fitting to one loud blog post. Synthesis is where you
state the *pattern*, not just restate one article.

### Gate 3 — Synthesize → Apply (synthesis → proposed change)

A synthesis becomes an `apply/proposed/*.md` only when it passes the
**"friction or quality" test**:

> Does this change either **reduce friction** in our SDLC (fewer steps,
> fewer mistakes, faster) **or raise quality** (better designs, fewer
> escaped bugs)? And can you name the **exact file(s)** in `core/` or
> `presets/` it would touch?

If you can't name the file, it's not ready — it's still a synthesis.

## URL discipline

- **Never record a URL you haven't seen resolve.** Hallucinated links rot
  the library. When seeding from research, verify reachability first.
- Prefer canonical URLs (the docs page, not a third-party mirror).
- Capture the `date_found`; the web moves and dead links happen.

## Scope — the 6 tracks

Research that doesn't map to one of these is probably out of scope:

1. `claude-code-core` — Claude Code: skills, sub-agents, hooks, MCP, plugins, slash commands, CLAUDE.md craft, headless/SDK
2. `adjacent-tools` — Cursor, Aider, Cline, Codex CLI, Continue, Windsurf — borrowable patterns
3. `sdlc-with-ai` — spec-driven dev, TDD-with-AI, AI review, planning-first, prompt engineering for teams, evals
4. `legacy-modernization` — understanding & refactoring legacy code with agents
5. `complex-systems` — monorepos, distributed systems, context-at-scale, retrieval/indexing
6. `software-tech` — architecture & engineering patterns that make codebases agent-friendly

## Cadence (the rhythm that keeps this alive)

| When | Action | Output |
|---|---|---|
| Ad-hoc | Drop links | `inbox/_inbox.md` lines |
| Weekly (~30 min) | Triage inbox, write source notes | `sources/*.md` |
| Bi-weekly (~1 h) | Synthesize topics past Gate 2 | `synthesis/<topic>/*.md` |
| Monthly (~1 h) | Promote past Gate 3, open PR | `apply/proposed/*.md` → `apply/shipped/*.md` |

A track that goes quiet is fine. A track with raw sources but no synthesis
for months is a signal to either synthesize or archive.
