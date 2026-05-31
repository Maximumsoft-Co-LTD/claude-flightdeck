# Research Index

Single-glance state of every research track. Update the row when a stage
advances. `Sources` = count of notes in `sources/` tagged with the track.
`Synthesis` / `Apply` = best status reached.

> Legend — Synthesis: `—` none · `draft` · `✅ low/med/high` (confidence).
> Apply: `—` none · `proposed` · `shipped`.

> Inbox seeded 2026-05-30/31 in **7 research rounds**: **336 source links** +
> **43 build-from GitHub artifacts** = **379 verified links** (all reachable;
> rounds 2-7 enforced quality ≥4, primary/recognized sources only).
> Rounds 5-6 were **saturation/broaden passes** (0 saturated, twice). Round 7
> was an **artifact-harvest** pass — real skills/agents/rules/hooks/commands on
> GitHub + marketplaces to seed OUR skills (see _inbox.md "Artifacts to build
> from"). `Inbox` counts #track-tagged source links; `Sources` = processed notes.

| Track | Inbox | Sources | Synthesis | Apply | Last update |
|---|---:|---:|:---:|:---:|---|
| `claude-code-core` | 88 | 2 | ✅ high | proposed | 2026-05-30 |
| `adjacent-tools` | 23 | 0 | — | — | 2026-05-30 |
| `sdlc-with-ai` | 104 | 0 | — | — | 2026-05-30 |
| `legacy-modernization` | 23 | 0 | — | — | 2026-05-30 |
| `complex-systems` | 41 | 0 | — | — | 2026-05-30 |
| `software-tech` | 62 | 0 | — | — | 2026-05-30 |

**Round 2 sub-topics (net-new):** CC hooks · MCP building & security ·
subagents/Agent Teams · Aider/Cline/Amp/Continue techniques · AGENTS.md standard
(+ empirical evidence) · AI code review · TDD/test-gen (test-theater, mutation,
property-based, TDFlow) · evals & benchmarks (Terminal-Bench 2.0, Multi-SWE-bench,
SWE-Lancer) · characterization/approval testing · code retrieval/RAG (grep vs
embeddings) · agent security (OWASP MCP Top 10, lethal trifecta, sandboxing) ·
architecture for agents (vertical slice, screaming, modular monolith).

**Round 3 sub-topics (net-new, deeper):** cost/token economics (Claude Code costs,
prompt caching, compaction) · model selection & routing (effort param, Haiku 4.5,
RouteLLM) · agent memory systems · planning & extended thinking (think tool,
AlphaCodium, Plan Mode) · CI/CD headless mode · cloud/async agents (Claude Code on
the web, GitHub mission control) · spec-driven deep (Kiro, BMAD, EARS) · large-scale
refactoring/codemods (Google migrations, OpenRewrite, ast-grep) · prompt-injection
design patterns (CaMeL, AgentDojo, the 6-patterns paper) · agent reliability/variance
(nondeterminism, April postmortem) · measuring AI impact (METR RCT, DORA 2025) ·
self-improving agents (Dreaming, ReasoningBank, SWE-Exp).

**Round 4 sub-topics (net-new):** multi-repo / microservices coordination
(NL-summary bug localization, MicroRemed, PactFlow) · DB schema/data migrations
(Atlas, gh-ost, Squawk, online schema change) · debugging & incident response
(SRE agent, RCAEval, Honeycomb/Datadog) · documentation generation & doc-drift
(Mintlify, ADR-in-code, commit/comment inconsistency) · contract-first API design
(buf breaking, Spectral, design-first) · agent observability tooling (Langfuse,
OpenLLMetry, OTel GenAI agent spans) · prompt-engineering patterns (The Prompt
Report, Prompt Pattern Catalog) · LLM-as-judge grading (JudgeBench, rubric bias) ·
agent tool/function design · RAG over org knowledge (Contextual Retrieval, GraphRAG/
LazyGraphRAG, CodexGraph) · security SAST & supply-chain (Semgrep AI, package
hallucination/slopsquatting, Copilot Autofix) · frontend design-to-code (Figma MCP,
frontend-aesthetics prompt, Storybook visual tests).

**Round 5 — saturation/enrichment pass (the answer to "is there more?"):** re-ran
all 36 sub-topics asking only for net-new sources that fill a *missing angle*
beyond what we already had. Result: **+91 net-new, 0 saturated** — every topic
still had more. Highlights are the counterpoints & primary research the earlier
rounds lacked: "Don't Build Multi-Agents" (Cognition) + the MAST failure taxonomy
vs our pro-orchestration sources · "Dive into Claude Code" (harness reverse-engineer)
· Reflexion / Agentic Context Engineering · OWASP Top 10 for **Agentic** Apps ·
Google Big Sleep + DARPA AIxCC + Trail of Bits Buttercup (AI vuln-finding) ·
Airbnb & Google large-scale LLM migrations · Stripe online migrations + pgroll ·
Vercel v0 internals · METR Time Horizon + DORA AI Capabilities Model + Faros
whiplash report · CVE-2025-59536 (hooks RCE) + CSA CI/CD attack-surface note.
Takeaway: the research surface keeps growing faster than we can drain it — the
constraint now is **processing** (inbox → sources → synthesis → apply), not capture.

**Round 6 — broaden pass (2nd saturation check):** re-ran all 38 sub-topics asking
for sources that *widen* coverage (newest 2026, other vendors/ecosystems/languages,
contrarian views, deeper sub-specializations). Result: **+78 net-new, 0 saturated
again** — every topic still had wider material. Notable widening: a 650-trial
empirical study contradicting Anthropic's passive skill-description guidance ·
**OWASP Agentic Skills Top 10** (secure SKILL.md authoring after registry poisoning) ·
VS Code/Copilot Agent Skills (cross-vendor SKILL.md portability). Confirms the field
is not close to exhausted — two full passes, zero saturated topics. The hard pivot
remains **processing**, not more capture.

**Round 7 — artifact-harvest (build-from references):** 16 agents hunted GitHub +
marketplaces for real, reusable **skills/agents/rules/hooks/slash-commands** to seed
our own, tagged by `artifact_kind` + `adoptability` (lift-directly / adapt /
study-pattern / reference-only). Result: **+43 verified artifacts, 0 saturated**.
Live in `inbox/_inbox.md` → "Artifacts to build from (GitHub)". Highest-value:
- **lift-directly:** `anthropics/skills` (official SKILL.md spec + template + skill-creator
  scripts) · `nizos/tdd-guard` (TDD-enforcement hook) · `karanb192/claude-code-hooks`.
- **adapt:** `wshobson/agents` (155 skills / 191 agents — closest peer bundle) ·
  `VoltAgent/awesome-claude-code-subagents` (154 SDLC subagents) · `github/spec-kit` ·
  `anthropics/claude-code-security-review` · `hashicorp/agent-skills` · `ast-grep/agent-skill` ·
  `trailofbits/skills` · `qdhenry/Claude-Command-Suite` + `wshobson/commands`.
- **study-pattern:** `anthropics/claude-plugins-official` (marketplace/plugin.json shape) ·
  `PatrickJS/awesome-cursorrules` · `github/awesome-copilot` · `josix/awesome-claude-md`.
These are the concrete seeds for the next phase — building/improving our own skills.

## Shipped changes (the scoreboard)

What research has actually changed in the template. Each row links an
`apply/shipped/*.md` to the synthesis that drove it.

| Date | Change | Track | Synthesis | PR |
|---|---|---|---|---|
| _(none yet)_ | | | | |

## How to read this

- A track stuck at `Sources > 0, Synthesis —` for weeks → time to synthesize or archive.
- A track at `Synthesis ✅ high, Apply —` → ripe for `apply/proposed/`.
- The scoreboard is the real output of this whole workspace. Keep it growing.
