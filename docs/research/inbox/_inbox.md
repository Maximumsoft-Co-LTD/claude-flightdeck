# Inbox

> Drop links & ideas here, one line each. Format:
> `- [YYYY-MM-DD] <url|idea:...> — note · q<1-5>  #track`
> See [README.md](README.md). Don't read now — triage weekly.

## Unprocessed

<!-- newest at top. Seeded 2026-05-30 via the research-seed workflow:
     37 candidates fanned out across 6 tracks, all verified reachable.
     `q` = source-quality estimate from the discovery agent (confirm on read).
     Canonical URLs used where the live page redirected. -->

### claude-code-core
- [2026-05-30] https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills — how to author Agent Skills: progressive disclosure, eval-driven iteration, trigger/description tuning · q5  #claude-code-core ✅ processed → sources/2026-05-30-anthropic-agent-skills-authoring.md
- [2026-05-30] https://code.claude.com/docs/en/best-practices — canonical Claude Code best-practices (explore→plan→code→commit, verifiable checks, adversarial review subagent) · q5  #claude-code-core #sdlc-with-ai
- [2026-05-30] https://claude.com/blog/building-agents-with-the-claude-agent-sdk — the agent harness behind Claude Code: gather-context → act → verify loop, subagent context isolation · q5  #claude-code-core
- [2026-05-30] https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview — official Agent Skills reference + SKILL.md frontmatter spec · q5  #claude-code-core
- [2026-05-30] https://www.anthropic.com/engineering/code-execution-with-mcp — expose MCP servers as code APIs; progressive tool disclosure to cut token/tool sprawl · q5  #claude-code-core
- [2026-05-30] https://github.com/obra/superpowers — community SDLC-as-skills plugin (TDD, debugging, plan/verify) — direct comparison point for our gates · q4  #claude-code-core
- [2026-05-30] https://github.com/hesreallyhim/awesome-claude-code — curated index of CC skills/hooks/commands/orchestrators — best feed to refresh this inbox · q4  #claude-code-core

<!-- round 2 (2026-05-30): hooks · MCP building -->
- [2026-05-30] https://code.claude.com/docs/en/hooks — official hooks reference: lifecycle events, 5 handler types, exit-2=deny semantics · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/hooks-guide — hooks getting-started: settings.json shape, "system enforcement over model compliance" · q5  #claude-code-core
- [2026-05-30] https://github.com/disler/claude-code-hooks-multi-agent-observability — wire all hook events → event stream for multi-agent observability · q4  #claude-code-core
- [2026-05-30] https://github.com/disler/claude-code-hooks-mastery — reference impls of every lifecycle hook (Stop, SubagentStop, per-event logging) · q4  #claude-code-core
- [2026-05-30] https://modelcontextprotocol.io/specification/draft/basic/security_best_practices — official MCP security: confused-deputy, token passthrough, SSRF, scope minimization (MUST/SHOULD) · q5  #claude-code-core
- [2026-05-30] https://developer.microsoft.com/blog/protecting-against-indirect-injection-attacks-mcp — MS: tool-poisoning & indirect prompt injection in MCP, AI Prompt Shields · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2602.14878 — "MCP Tool Descriptions Are Smelly": 97% have smells; 6-component description rubric · q5  #claude-code-core
- [2026-05-30] https://www.atlassian.com/blog/development/mcp-compression-preventing-tool-bloat-in-ai-agents — mcp-compressor proxy cuts tool-desc overhead 70-97% · q4  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/sub-agents — official custom-subagent spec: frontmatter, /agents, tool allowlists, description-driven delegation · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/agent-teams — Agent Teams: shared task list, file-locking, peer messaging, plan-approval gates · q5  #claude-code-core
- [2026-05-30] https://addyosmani.com/blog/code-agent-orchestra/ — multi-agent coding: parallelism, specialization, worktree isolation, subagents vs teams · q4  #claude-code-core
- [2026-05-30] https://www.oreilly.com/radar/conductors-to-orchestrators-the-future-of-agentic-coding/ — conductor (sync, 1 agent) vs orchestrator (async, many, PR-producing) framework · q4  #claude-code-core

<!-- round 3 (2026-05-30): model routing · memory · planning · cloud/async · self-improvement -->
- [2026-05-30] https://platform.claude.com/docs/en/build-with-claude/effort — `effort` param (low/med/high/xhigh/max) trades intelligence vs cost/latency within one model · q5  #claude-code-core
- [2026-05-30] https://www.anthropic.com/news/claude-haiku-4-5 — Haiku 4.5: near-frontier coding at ~1/3 cost, 2x+ speed — endorsed for cheap subagents · q5  #claude-code-core
- [2026-05-30] https://www.augmentcode.com/guides/ai-model-routing-guide — routing playbook: Opus=planning, Sonnet=implementation, Haiku=navigation · q4  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2406.18665 — RouteLLM: learned routing of hard→strong, easy→cheap model from preference data · q5  #claude-code-core
- [2026-05-30] https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools — memory tool + compaction + tool-clearing cookbook (long-running agent) · q5  #claude-code-core
- [2026-05-30] https://platform.claude.com/docs/en/build-with-claude/extended-thinking — extended thinking: budgets, summarized vs full, interleaved thinking · q5  #claude-code-core
- [2026-05-30] https://www.anthropic.com/engineering/claude-think-tool — the "think" tool: a dedicated mid-task reflection step distinct from extended thinking · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2401.08500 — AlphaCodium: flow engineering (spec reflection → tests → iterate) beats single-prompt · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/common-workflows — official Plan Mode + structured workflows (read-only investigate-then-propose) · q5  #claude-code-core
- [2026-05-30] https://claude.com/blog/claude-code-on-the-web — Claude Code on the web: isolated cloud VM sandboxes, async tasks · q5  #claude-code-core
- [2026-05-30] https://cursor.com/blog/cloud-agent-lessons — Cursor cloud agents: env reconstruction is the dominant quality factor · q5  #claude-code-core
- [2026-05-30] https://github.blog/ai-and-ml/github-copilot/how-to-orchestrate-agents-using-mission-control/ — GitHub Agent HQ mission control: parallel async agents · q5  #claude-code-core
- [2026-05-30] https://elite-ai-assisted-coding.dev/p/working-with-asynchronous-coding-agents — async-agent delegation playbook (Eleanor Berger / Ruler) · q4  #claude-code-core
- [2026-05-30] https://claude.com/blog/new-in-claude-managed-agents — "Dreaming": scheduled between-session self-review of transcripts + memory · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2509.25140 — ReasoningBank: self-evolving reasoning memory distilled from success AND failure · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2507.23361 — SWE-Exp: experience bank of actionable lessons from prior coding-agent trajectories · q5  #claude-code-core
- [2026-05-30] https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents — harnesses for long-running agents: durable memory/state, init.sh, progress log, frequent commits · q5  #claude-code-core #sdlc-with-ai

<!-- round 4 (2026-05-30): agent tool/function design -->
- [2026-05-30] https://developers.openai.com/api/docs/guides/function-calling — OpenAI function-calling: clear names/param descriptions, error design, when to use tools · q5  #claude-code-core

<!-- round 5 (2026-05-30) saturation/enrichment: +26 net-new complementary -->
- [2026-05-30] https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills — Official Anthropic announcement (Mar 3 2026) for the upgraded skill-creator: write evals over test prompts, run a benchm… · q5  #claude-code-core
- [2026-05-30] https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md — Anthropic's canonical meta-skill source: documents the full lifecycle — capture intent, three-tier progressive disclosur… · q5  #claude-code-core
- [2026-05-30] https://towardsdatascience.com/how-to-build-a-production-ready-claude-code-skill/ — Hajime Takeda walks through shipping a real e-commerce review skill end-to-end: design from 2-3 concrete use cases befor… · q4  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2604.14228 — Peer-reviewed reverse-engineering of Claude Code v2.1.88's TypeScript source (~512K LOC) that maps the agent harness as… · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/agent-sdk/agent-loop — Primary spec for the Agent SDK's embeddable loop: the 5-step turn cycle (receive prompt, evaluate, execute tools, repeat… · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/agent-sdk/hooks — Official Anthropic spec for hooks as programmatic callback functions in the Python/TypeScript Agent SDK (options.hooks),… · q5  #claude-code-core
- [2026-05-30] https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/ — Check Point Research's primary disclosure showing hooks in repo-committed .claude/settings.json execute arbitrary shell… · q5  #claude-code-core
- [2026-05-30] https://www.endorlabs.com/learn/when-the-guardrails-slip-the-case-for-hook-based-governance-across-agent-platforms — Endor Labs (security vendor) argues hooks should be the platform-agnostic enforcement layer for agent CLIs, mapping thre… · q4  #claude-code-core
- [2026-05-30] https://www.microsoft.com/en-us/research/blog/tool-space-interference-in-the-mcp-era-designing-for-agent-compatibility-at-scale/ — Microsoft Research (Fourney, Payne, Murad, Amershi) surveys 1,470 live MCP servers and quantifies how co-present tools d… · q5  #claude-code-core
- [2026-05-30] https://cognition.ai/blog/dont-build-multi-agents — Cognition (makers of Devin) argues against parallel multi-agent architectures: independent subagents fragment context an… · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2503.13657 — Peer-reviewed (NeurIPS 2025) empirical study of 1600+ annotated execution traces across 7 multi-agent frameworks. Introd… · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/model-config — Primary spec for how Claude Code itself routes models: the opusplan alias (Opus in plan mode, auto-switch to Sonnet for… · q5  #claude-code-core
- [2026-05-30] https://www.anthropic.com/engineering/multi-agent-research-system — Anthropic's first-party writeup of the orchestrator-worker pattern: an Opus lead agent plans and spawns parallel Sonnet… · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/memory — Official Claude Code memory reference: CLAUDE.md scopes/load-order, .claude/rules path-scoped rules, and auto-memory (v2… · q5  #claude-code-core
- [2026-05-30] https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool — Primary spec for the client-side memory tool: beta header context-management-2025-06-27, the /memories file directory CR… · q5  #claude-code-core
- [2026-05-30] https://www.letta.com/blog/memory-blocks — Letta (MemGPT maintainers) explains memory blocks as persisted, agent-editable in-context units (Human/Persona origin),… · q4  #claude-code-core
- [2026-05-30] https://lucumr.pocoo.org/2025/12/17/what-is-plan-mode/ — Armin Ronacher (Flask/Jinja/Sentry) reverse-engineers Claude Code's plan mode and finds it is implemented via prompt inj… · q4  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2303.11366 — Shinn et al. introduce Reflexion: agents verbally reflect on task-feedback signals and store the reflections in an episo… · q5  #claude-code-core
- [2026-05-30] https://code.claude.com/docs/en/workflows — Official Anthropic spec for Dynamic Workflows (research preview, v2.1.154+): Claude writes a JavaScript orchestration sc… · q5  #claude-code-core
- [2026-05-30] https://developers.openai.com/codex/cloud — Official OpenAI docs for Codex Cloud: tasks run in the background and in parallel, each in its own isolated cloud sandbo… · q5  #claude-code-core
- [2026-05-30] https://blog.pragmaticengineer.com/new-trend-programming-by-kicking-off-parallel-ai-agents/ — Gergely Orosz (Oct 30, 2025) synthesizes the emerging practice of running multiple async coding agents at once across Cl… · q4  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2510.04618 — Stanford-affiliated team (ICLR 2026) frames self-improvement as treating the context as an evolving 'playbook' refined b… · q5  #claude-code-core
- [2026-05-30] https://aclanthology.org/2025.acl-long.413/ — ACL 2025 Main (Long Papers; authors from Google + academia) introduces RMM, splitting memory upkeep into prospective ref… · q5  #claude-code-core
- [2026-05-30] https://modelcontextprotocol.io/specification/2025-11-25/server/tools — The canonical primary spec for agent tool contracts: inputSchema/outputSchema (JSON Schema 2020-12 default), structuredC… · q5  #claude-code-core
- [2026-05-30] https://github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows/ — GitHub-internal production case study (May 2026) on tool design as a token-efficiency problem. Introduces an 'Effective… · q5  #claude-code-core
- [2026-05-30] https://proceedings.mlr.press/v267/patil25a.html — Peer-reviewed (ICML 2025) primary benchmark for evaluating/testing function-calling. Introduces an Abstract Syntax Tree… · q5  #claude-code-core
<!-- round 6 (2026-05-30) broaden: +25 net-new wider -->
- [2026-05-30] https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1 — An empirical 650-trial study (18 queries x 3 skills x 3 reps across 4 environment conditions, verified via cclogviewer s… · q4  #claude-code-core
- [2026-05-30] https://owasp.org/www-project-agentic-skills-top-10/skill-development-guide — OWASP's secure-authoring guide for SKILL.md skills (Incubator project, updated March 2026, spanning OpenClaw/Claude/Curs… · q5  #claude-code-core
- [2026-05-30] https://code.visualstudio.com/docs/copilot/customization/agent-skills — Official VS Code documentation (dated 28 May 2026) for authoring Agent Skills consumed by GitHub Copilot. Documents the… · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2603.05344 — First-party technical report by the OpenDev team documenting how THEY built a terminal-native coding agent from scratch:… · q5  #claude-code-core
- [2026-05-30] https://claude-code-from-source.com/ — An 18-chapter book reconstructed from the leaked npm source maps (1,906 TS files), tracing the query.ts ~1,700-line asyn… · q4  #claude-code-core
- [2026-05-30] https://generalanalysis.com/guides/claude-code-enterprise-security-deployment — An eight-phase operational playbook (May 22, 2026) positioning hooks as one policy-enforcement control layer: hooks must… · q4  #claude-code-core
- [2026-05-30] https://generalanalysis.com/guides/claude-code-control-observability-opentelemetry — Deep technical guide (May 22, 2026) arguing 'hooks are control code, so they need their own observability' — emits hook… · q4  #claude-code-core
- [2026-05-30] https://github.blog/ai-and-ml/generative-ai/measuring-what-matters-how-offline-evaluation-of-github-mcp-server-works/ — GitHub engineer Ksenia Bobrova details GitHub's offline eval pipeline for the GitHub MCP Server: tool selection treated… · q5  #claude-code-core
- [2026-05-30] https://www.philschmid.de/mcp-best-practices — Philipp Schmid (Google DeepMind, ex-Hugging Face) argues most MCP failures are server-design failures, not protocol flaw… · q5  #claude-code-core
- [2026-05-30] https://github.com/anthropics/claude-code/issues/25818 — Official anthropics/claude-code issue (opened Feb 14 2026, Opus 4.6) documenting two concrete orchestrator failure modes… · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2510.00202 — First open leaderboard for rigorously benchmarking LLM routers: 8,400 queries across 9 domains / 44 categories at multip… · q5  #claude-code-core
- [2026-05-30] https://genai.owasp.org/2026/05/13/memory-is-a-feature-it-is-also-an-attack-surface/ — Official OWASP GenAI Security Project post (May 2026, by Cisco's Idan Habler, an ASI06 lead) arguing that agent persiste… · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2605.15338 — CISPA/ELLIS/MPI research paper (May 2026) introducing sleeper memory poisoning: adversaries plant fabricated memories th… · q5  #claude-code-core
- [2026-05-30] https://developers.openai.com/codex/memories — Official OpenAI Codex docs for its cross-session Memories feature: Codex asynchronously converts eligible prior threads… · q5  #claude-code-core
- [2026-05-30] https://nearform.com/digital-community/why-plan-mode-is-not-enough-better-outcomes-with-spec-driven-development/ — Luca Lanziani (Head of DevOps & Platform Engineering, Nearform; Mar 18 2026) argues Claude Code plan mode is fine for a… · q4  #claude-code-core
- [2026-05-30] https://arxiv.org/abs/2509.03581 — Paglieri, Cupiał, Cook et al. (v3 Feb 17 2026). Shows that always-planning is expensive AND degrades long-horizon perfor… · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/pdf/2602.07187 — Wang, Cao, Lin, Chen (Feb 2026). Introduces 'prospective reflection' — agents anticipate likely obstacles and failure mo… · q5  #claude-code-core
- [2026-05-30] https://platform.claude.com/docs/en/managed-agents/overview — Official Anthropic doc (beta header managed-agents-2026-04-01) for a managed agent harness purpose-built for long-runnin… · q5  #claude-code-core
- [2026-05-30] https://github.blog/news-insights/company-news/pick-your-agent-use-claude-and-codex-on-agent-hq/ — Official GitHub announcement (Feb 4 2026, by CPO Mario Rodriguez) of Agent HQ: a control plane that runs coding agents f… · q5  #claude-code-core
- [2026-05-30] https://burakdede.com/blog/the-pull-request-is-dead-surviving-the-ai-code-avalanche/ — Burak Dede (engineering leader at Wayfair, 15+ yrs distributed systems) argues async/background agents generate PRs far… · q4  #claude-code-core
- [2026-05-30] https://arxiv.org/html/2604.08224v1 — April 2026 survey (arXiv:2604.08224) arguing agent progress now comes from external infrastructure, not model scaling. F… · q4  #claude-code-core
- [2026-05-30] https://openreview.net/forum?id=4KhDd0Ozqe — ICML 2025 position-track (peer-reviewed) paper arguing that most 'self-improving' agents rely on fixed, human-designed l… · q5  #claude-code-core
- [2026-05-30] https://owasp.org/www-community/attacks/MCP_Tool_Poisoning — OWASP community attack page treating the MCP tool description, parameter schema, and structured metadata as an injection… · q5  #claude-code-core
- [2026-05-30] https://arxiv.org/html/2602.14878v1 — Empirical study of 856 MCP tools finds 97.1% contain at least one description 'smell' and 56% lack a clear purpose state… · q5  #claude-code-core
- [2026-05-30] https://dev.to/aws-heroes/mcp-tool-design-why-your-ai-agent-is-failing-and-how-to-fix-it-40fc — AWS Hero (Mar 2026) gives code-level patterns: typed structs auto-generating JSON Schema with inline constraint annotati… · q4  #claude-code-core
### adjacent-tools
- [2026-05-30] https://openai.com/index/unrolling-the-codex-agent-loop/ — Codex CLI agent loop dissected (loop termination, quadratic-JSON context cost) · q5  #adjacent-tools
- [2026-05-30] https://developers.openai.com/codex/guides/agents-md — AGENTS.md hierarchical/override-aware instruction loading (root→dir precedence) · q5  #adjacent-tools
- [2026-05-30] https://cursor.com/docs/rules — Cursor rule activation modes: Always / Auto-attached (glob) / Agent-requested / Manual · q5  #adjacent-tools
- [2026-05-30] https://aider.chat/docs/repomap.html — Aider repo-map: graph-ranked symbol signatures within a token budget (--map-tokens) · q5  #adjacent-tools
- [2026-05-30] https://cline.bot/blog/plan-smarter-code-faster-clines-plan-act-is-the-paradigm-for-agentic-coding — Cline Plan/Act split + structured Memory Bank file set · q4  #adjacent-tools
- [2026-05-30] https://sourcegraph.com/blog/agentic-coding — Agentic Coding in 2026 for big code: the "80% problem", deterministic symbol search, CI gating · q4  #adjacent-tools

<!-- round 2 (2026-05-30): deeper tool techniques · AGENTS.md standard -->
- [2026-05-30] https://aider.chat/docs/more/edit-formats.html — Aider's 5 edit formats & model-aware diff application (udiff vs lazy elision) · q5  #adjacent-tools
- [2026-05-30] https://docs.cline.bot/features/memory-bank — Cline Memory Bank: named markdown files agent reads on resume (activeContext = hot file) · q5  #adjacent-tools
- [2026-05-30] https://github.com/sourcegraph/amp-examples-and-guides/blob/main/guides/context-management/Context%20Engineering%20-%20Amp.md — Amp: subagents for context multiplication, thread forking, compaction, AGENT.md scopes · q5  #adjacent-tools
- [2026-05-30] https://docs.continue.dev/customize/deep-dives/rules — Continue rule routing: glob/regex scope, alwaysApply tiers, deterministic ordering · q5  #adjacent-tools
- [2026-05-30] https://agents.md/ — the open AGENTS.md standard: nesting/precedence, tool support matrix · q5  #adjacent-tools
- [2026-05-30] https://arxiv.org/abs/2601.20404 — empirical: AGENTS.md cuts runtime ~28.6% & output tokens ~16.6% (124 PRs) · q5  #adjacent-tools
- [2026-05-30] https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals — passive context (AGENTS.md) beat active retrieval (skills) 100% vs 79% · q5  #adjacent-tools
- [2026-05-30] https://blog.modelcontextprotocol.io/posts/2025-12-09-mcp-joins-agentic-ai-foundation/ — MCP + AGENTS.md now under Linux Foundation (Agentic AI Foundation) · q5  #adjacent-tools

<!-- round 5 (2026-05-30) saturation/enrichment: +6 net-new complementary -->
- [2026-05-30] https://ampcode.com/manual — Sourcegraph's canonical maintainer manual for Amp: documents subagents (independent context windows), the 'oracle' secon… · q5  #adjacent-tools
- [2026-05-30] https://aider.chat/2023/10/22/repomap.html — Maintainer engineering post explaining how Aider builds the repo map: tree-sitter ASTs extract definitions/references ac… · q5  #adjacent-tools
- [2026-05-30] https://cline.bot/blog/how-to-think-about-context-engineering-in-cline — Official Cline post (Nick Baumann, Aug 2025) on curating tokens across long conversations: Focus Chain reinjects a task… · q5  #adjacent-tools
- [2026-05-30] https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/ — GitHub PM Director Matt Nigh (Nov 2025) analyzes 2,500+ repos to extract what separates effective AGENTS.md files from d… · q5  #adjacent-tools
- [2026-05-30] https://arxiv.org/abs/2602.11988 — Gloaguen, Mündler, Müller, Raychev & Vechev (ETH Zurich / LogicStar.ai, Feb 2026) run two complementary evals — SWE-benc… · q5  #adjacent-tools
- [2026-05-30] https://developer.nvidia.com/blog/mitigating-indirect-agents-md-injection-attacks-in-agentic-environments/ — NVIDIA AI Red Team (Daniel Teixeira, Apr 2026) demonstrates a supply-chain attack where a compromised dependency writes… · q5  #adjacent-tools
<!-- round 6 (2026-05-30) broaden: +3 net-new wider -->
- [2026-05-30] https://ampcode.com/news/oracle — Official Amp page describing the Oracle: a read-only subagent (powered by a frontier reasoning model, slower/pricier tha… · q5  #adjacent-tools
- [2026-05-30] https://arxiv.org/abs/2512.14012 — Peer-style empirical study (13 field observations + 99 surveys of experienced devs) finding that professionals deliberat… · q5  #adjacent-tools
- [2026-05-30] https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation — Official Linux Foundation announcement that AGENTS.md (contributed by OpenAI) now sits under the new Agentic AI Foundati… · q5  #adjacent-tools
### sdlc-with-ai
- [2026-05-30] https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents — context as a finite budget: compaction, note-taking, subagent isolation, JIT retrieval · q5  #sdlc-with-ai #complex-systems ✅ processed → sources/2026-05-30-anthropic-context-engineering.md
- [2026-05-30] https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/ — GitHub Spec Kit: Specify → Plan → Tasks → Implement · q5  #sdlc-with-ai
- [2026-05-30] https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices — SDD as antidote to vibe-coding: Given/When/Then specs, spec-drift guardrails · q4  #sdlc-with-ai
- [2026-05-30] https://claude.com/blog/how-anthropic-teams-use-claude-code — production patterns: specialized subagents, CLAUDE.md as discoverability layer, parallelism · q5  #sdlc-with-ai
- [2026-05-30] https://openai.com/index/introducing-swe-bench-verified/ — human-validated coding-agent eval methodology (verifiable patch + passing tests) · q4  #sdlc-with-ai

<!-- round 2 (2026-05-30): AI code review · TDD/test-gen · evals & benchmarks -->
- [2026-05-30] https://devblogs.microsoft.com/engineering-at-microsoft/enhancing-code-quality-at-scale-with-ai-powered-code-reviews/ — MS AI reviewer on >90% of 600K+ PRs/mo, 10-20% faster · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2508.18771 — "Does AI Code Review Lead to Code Changes?": concise, hunk-level, manual-trigger comments drive real fixes · q5  #sdlc-with-ai
- [2026-05-30] https://openai.com/index/codex-security-now-in-research-preview/ — Codex Security: identify/validate/remediate, 84% noise reduction (validate-before-surfacing) · q5  #sdlc-with-ai
- [2026-05-30] https://www.greptile.com/blog/ai-code-review — 2.2M PRs: ~48% of catches are logic errors; keep gen & review agents separate · q4  #sdlc-with-ai
- [2026-05-30] https://engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/ — Meta ACH: LLM mutation testing, fault-targeted tests (73% accepted) · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2506.18315 — Property-Generated Solver: property-based feedback beats example-TDD +13.4% pass@1 · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2510.23761 — TDFlow: agentic TDD sub-agents, 88.8% SWE-Bench Lite, minimizes test-hacking · q5  #sdlc-with-ai
- [2026-05-30] https://ben3d.ca/blog/the-rise-of-test-theater — "test theater": AI tests validate current behavior (incl bugs) not intent · q4  #sdlc-with-ai
- [2026-05-30] https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents — first-party eval recipe: 20-50 real-failure tasks, grade output not path, evals-as-CI · q5  #sdlc-with-ai
- [2026-05-30] https://www.tbench.ai/news/announcement-2-0 — Terminal-Bench 2.0 + Harbor harness for CLI-agent evals · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2504.02605 — Multi-SWE-bench: multilingual (Java/TS/Go/Rust/C/C++) issue-resolving benchmark · q5  #sdlc-with-ai
- [2026-05-30] https://openai.com/index/swe-lancer/ — SWE-Lancer: $1M real Upwork tasks, end-to-end-test grading + managerial dimension · q5  #sdlc-with-ai

<!-- round 3 (2026-05-30): cost/economics · CI/CD headless · spec-driven deep · reliability · measuring impact -->
- [2026-05-30] https://code.claude.com/docs/en/costs — official cost playbook: /usage, spend limits, ~7x agent-team multiplier, token-reduction levers · q5  #sdlc-with-ai
- [2026-05-30] https://platform.claude.com/docs/en/build-with-claude/prompt-caching — caching pricing: writes 1.25x/2x, reads 0.1x; min cacheable lengths; break-even math · q5  #sdlc-with-ai
- [2026-05-30] https://platform.claude.com/cookbook/tool-use-automatic-context-compaction — compaction economics: −58.6% tokens measured + threshold guidance · q5  #sdlc-with-ai
- [2026-05-30] https://developers.openai.com/api/docs/guides/prompt-caching — OpenAI caching (50% off, exact-prefix match) — cross-provider "stable prefix" rule · q5  #sdlc-with-ai
- [2026-05-30] https://code.claude.com/docs/en/headless — headless mode: `claude -p`, `--output-format json`, `--json-schema` for CI · q5  #sdlc-with-ai
- [2026-05-30] https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html — Böckeler: Kiro vs spec-kit vs Tessl; spec-first/anchored/centric taxonomy · q5  #sdlc-with-ai
- [2026-05-30] https://kiro.dev/docs/specs/ — AWS Kiro spec engine: requirements.md / design.md / tasks.md triad · q5  #sdlc-with-ai
- [2026-05-30] https://github.com/bmad-code-org/BMAD-METHOD — BMAD method (48k★): persona agents, PRD→architecture→sharded stories · q5  #sdlc-with-ai
- [2026-05-30] https://alistairmavin.com/ears/ — EARS requirements syntax: 6-pattern grammar for unambiguous specs · q5  #sdlc-with-ai
- [2026-05-30] https://thinkingmachines.ai/blog/defeating-nondeterminism-in-llm-inference/ — non-reproducibility root cause = batch-invariance, not float math · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2602.07150 — "On Randomness in Agentic Evals": pass@1 swings 2.2-6.0 pts across identical runs · q5  #sdlc-with-ai
- [2026-05-30] https://www.anthropic.com/engineering/april-23-postmortem — "Claude Code got dumber" postmortem: 3 overlapping bugs (effort flip, cache flaw) · q5  #sdlc-with-ai
- [2026-05-30] https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/ — METR RCT: experienced OSS devs 19% SLOWER with AI (despite feeling faster) · q5  #sdlc-with-ai
- [2026-05-30] https://dora.dev/dora-report-2025/ — DORA 2025: AI amplifies throughput but degrades delivery stability · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2510.24265 — "Fast and Spurious": perceived GenAI speedups largely spurious (SPACE framework) · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2510.10165 — AI raises tech-debt/maintenance burden; gains skew to juniors, cost core devs · q5  #sdlc-with-ai

<!-- round 4 (2026-05-30): debugging/incident · docs generation · prompt patterns · LLM-as-judge -->
- [2026-05-30] https://platform.claude.com/cookbook/managed-agents-sre-incident-responder — SRE incident agent: PagerDuty alert → root cause → merged fix PR · q5  #sdlc-with-ai
- [2026-05-30] https://www.honeycomb.io/blog/agent-timeline-flight-recorder-for-your-ai-agents — Agent Timeline: stitch LLM/tool/handoff/retry spans for agent debugging · q4  #sdlc-with-ai
- [2026-05-30] https://www.datadoghq.com/blog/building-bits-ai-sre/ — Datadog Bits AI SRE: hypothesis → validate vs telemetry → subagents · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2412.17015 — RCAEval: root-cause-analysis benchmark for microservices (735 real cases) · q5  #sdlc-with-ai
- [2026-05-30] https://shinglyu.com/blog/2026/03/01/ai-adr-code-review.html — ADRs in-repo + AI reviewers enforce architecture compliance · q4  #sdlc-with-ai
- [2026-05-30] https://www.mintlify.com/blog/docs-as-ai-interface — docs as the primary AI interface (llms.txt, docs-as-context) · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2512.19883 — structured code diffs to flag comment/code inconsistency (JIT, CodeT5+) · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2511.19875 — CodeFuse-CommitEval: benchmark for commit-message↔code inconsistency · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2406.06608 — The Prompt Report: systematic survey (1500+ papers, 33-term vocab) · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2510.16809 — "When Many-Shot Prompting Fails": code-translation many-shot paradox · q5  #sdlc-with-ai
- [2026-05-30] https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-2_prompting_guide — GPT-5.2 prompting guide: reasoning-effort, crisp tool descriptions · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2302.11382 — Prompt Pattern Catalog (White et al.): Persona/Template/Cognitive-Verifier patterns · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2410.12784 — JudgeBench: benchmark for LLM-based judges (ICLR 2025) · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2602.02219 — position bias in rubric-based LLM-as-judge + mitigation · q5  #sdlc-with-ai
- [2026-05-30] https://developers.openai.com/cookbook/examples/reinforcement_fine_tuning — model graders for RFT + a reward-hacking case study · q5  #sdlc-with-ai
- [2026-05-30] https://www.langchain.com/articles/llm-as-a-judge — calibrating a judge with human corrections (calibration loop) · q4  #sdlc-with-ai

<!-- round 5 (2026-05-30) saturation/enrichment: +26 net-new complementary -->
- [2026-05-30] https://arxiv.org/abs/2604.03196 — Peer-reviewed MSR 2026 study of 13 real code-review agents across 3,109 PRs (AIDev dataset). CRA-only reviews merge at 4… · q5  #sdlc-with-ai
- [2026-05-30] https://docs.github.com/en/copilot/concepts/agents/code-review — Official GitHub primary spec for Copilot code review: how it analyzes diffs from multiple angles, what it excludes (depe… · q5  #sdlc-with-ai
- [2026-05-30] https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report — Analysis of 470 GitHub PRs (320 AI-co-authored, 150 human-only) with disclosed methodology and limitations. AI-authored… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2603.17973 — AIWare 2026 tool paper (Braberman et al.). Builds a static source-to-test dependency map shipped as a lightweight agent… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2603.13724 — MSR '26 empirical study (Yoshimoto et al.) on the AIDev dataset, 2,232 test-touching commits. AI agents authored ~16.4%… · q5  #sdlc-with-ai
- [2026-05-30] https://github.blog/ai-and-ml/generative-ai/how-we-evaluate-models-for-github-copilot/ — GitHub's own engineers describe their three-layer eval pipeline for shipping models into Copilot: 4,000+ offline tests o… · q5  #sdlc-with-ai
- [2026-05-30] https://metr.org/blog/2026-1-29-time-horizon-1-1/ — METR's updated (Jan 2026) measurement of the 'task-completion time horizon' — the human-expert task duration an agent co… · q5  #sdlc-with-ai
- [2026-05-30] https://martinfowler.com/articles/structured-prompt-driven/ — Wei Zhang and Jessie Jie Xia (Thoughtworks internal IT), published on Fowler's site Apr 2026, define SPDD: prompts as ve… · q5  #sdlc-with-ai
- [2026-05-30] https://aws.amazon.com/blogs/industries/from-spec-to-production-a-three-week-drug-discovery-agent-using-kiro/ — AWS first-party case study: three solution architects shipped a production drug-discovery target-ID agent in 3 weeks usi… · q5  #sdlc-with-ai
- [2026-05-30] https://blog.scottlogic.com/2025/11/26/putting-spec-kit-through-its-paces-radical-idea-or-reinvented-waterfall.html — Colin Eberhardt (Scott Logic CTO), 26 Nov 2025, runs GitHub Spec Kit head-to-head against prompt-and-iterate on the same… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2604.22750 — First systematic study of token consumption across 8 frontier LLMs on SWE-bench Verified. Agentic coding tasks burn ~100… · q5  #sdlc-with-ai
- [2026-05-30] https://developers.googleblog.com/en/gemini-2-5-models-now-support-implicit-caching/ — Google's official announcement (Logan Kilpatrick, May 2025) of implicit (automatic) prompt caching for Gemini 2.5: 75% t… · q5  #sdlc-with-ai
- [2026-05-30] https://www.finops.org/wg/genai-finops-how-token-pricing-really-works/ — FinOps Foundation working-group doc (updated May 2026, CC BY 4.0) on why advertised per-token price is misleading: outpu… · q5  #sdlc-with-ai
- [2026-05-30] https://code.claude.com/docs/en/github-actions — Primary spec for running Claude Code as an agent in GitHub Actions via anthropics/claude-code-action@v1: auto mode-detec… · q5  #sdlc-with-ai
- [2026-05-30] https://labs.cloudsecurityalliance.org/research/csa-research-note-ai-coding-tool-rce-cicd-attack-surface-202/ — Cloud Security Alliance research note (Apr 30 2026) documenting 30+ vulnerabilities across Gemini CLI, Cursor, Windsurf,… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2510.11977 — Princeton-led (Kapoor, Stroebl, Narayanan et al.) standardized harness that orchestrates parallel agent evals across hun… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2602.16666 — Rabanser, Kapoor, Narayanan et al. argue that compressing agent behavior into one success metric hides operational flaws… · q5  #sdlc-with-ai
- [2026-05-30] https://cloud.google.com/blog/products/ai-machine-learning/introducing-doras-inaugural-ai-capabilities-model — Google/DORA's new framework names seven technical and cultural capabilities (clear AI stance, healthy data ecosystems, A… · q5  #sdlc-with-ai
- [2026-05-30] https://www.faros.ai/blog/ai-acceleration-whiplash-takeaways — Faros AI analyzed two years of production telemetry from 22,000 developers across 4,000+ teams, comparing each org's low… · q4  #sdlc-with-ai
- [2026-05-30] https://cloud.google.com/blog/topics/developers-practitioners/how-google-sres-use-gemini-cli-to-solve-real-world-outages — Official Google Cloud post (Jan 23, 2026) detailing how Google SRE teams use an agentic CLI (Gemini 3 + internal ProdAge… · q5  #sdlc-with-ai
- [2026-05-30] https://www.anthropic.com/engineering/a-postmortem-of-three-recent-issues — Official Anthropic engineering postmortem (Sep 17, 2025) dissecting three overlapping production bugs that degraded Clau… · q5  #sdlc-with-ai
- [2026-05-30] https://ieeexplore.ieee.org/document/11029963/ — Peer-reviewed ICSE 2025 paper introducing C4RLLaMA, a CodeLLaMA fine-tune that not only DETECTS code-comment inconsisten… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2504.13656 — Della Porta, Lambiase & Palomba (Apr 2025) test whether structured prompt patterns change generated-code quality across… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2506.01604 — DiCuffa, AlOmar et al. (Jun 2025) analyze seven prompt patterns on the DevGPT dataset specifically for reducing develope… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2601.03444 — Li et al. (Jan 2026) compare human and LLM raters across three grading scales over six benchmarks (objective, subjective… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2604.16790 — Zhao, Esmaeili & Fard (Apr 2026) audit LLM judges across three SE tasks — code generation, code repair, and test generat… · q5  #sdlc-with-ai
<!-- round 6 (2026-05-30) broaden: +27 net-new wider -->
- [2026-05-30] https://addyo.substack.com/p/code-review-in-the-age-of-ai — Addy Osmani (Google Chrome eng lead, author) argues AI shifted the bottleneck from writing to verification: AI reviewers… · q4  #sdlc-with-ai
- [2026-05-30] https://research.google/pubs/ai-assisted-assessment-of-coding-practices-in-industrial-code-review/ — Google's deployed LLM-backed reviewer AutoCommenter, used by tens of thousands of developers daily across C++, Java, Pyt… · q5  #sdlc-with-ai
- [2026-05-30] https://red.anthropic.com/2026/property-based-testing/ — Anthropic's Frontier Red Team built a Claude agent that infers code invariants from docs/annotations and uses Hypothesis… · q5  #sdlc-with-ai
- [2026-05-30] https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/ — OpenAI publicly stops reporting SWE-bench Verified scores: a 27.6% audit found 59.4% of problems have flawed tests that… · q5  #sdlc-with-ai
- [2026-05-30] https://scale.com/blog/swe-bench-pro — Scale AI's contamination-resistant successor benchmark: 1,865 long-horizon tasks across 41 real Python/Go/TS/JS repos, a… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2601.14691 — Peer-reviewed Jan 2026 preprint showing LLM/VLM judges are highly manipulable: rewriting an agent's chain-of-thought whi… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2602.00180 — Deepak Babu Piskala (submitted Jan 30, 2026, AIWare 2026 track) gives the first systematic academic treatment of SDD: de… · q5  #sdlc-with-ai
- [2026-05-30] https://www.infoq.com/articles/enterprise-spec-driven-development/ — Hari Krishnan (reviewed by Thomas Betts, InfoQ, Feb 2026) argues SDD's real value is cross-functional collaboration, not… · q4  #sdlc-with-ai
- [2026-05-30] https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry/ — Tessl's product launch (Sep 2025) for the Spec Registry — a versioned 'NPM for specs' with 10,000+ usage specs for OSS l… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2604.07494 — April 2026 arXiv paper (Madeyski) that routes SWE tasks to the cheapest model tier whose output still passes the same ve… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2601.06007 — January 2026 arXiv study across OpenAI, Anthropic, and Google over 500+ agent sessions (DeepResearch Bench) finding that… · q5  #sdlc-with-ai
- [2026-05-30] https://www.finops.org/wg/cost-estimation-of-ai-workloads/ — Official FinOps Foundation working-group paper (updated Sept 2025) providing a vendor-neutral, token-based unit-economic… · q5  #sdlc-with-ai
- [2026-05-30] https://developers.openai.com/codex/github-action — Official OpenAI docs for openai/codex-action@v1: runs `codex exec` headlessly in CI from inline or file prompts, capture… · q5  #sdlc-with-ai
- [2026-05-30] https://www.infoq.com/news/2026/01/gitlab-18-8-duo-agent-platform/ — Covers the Jan 2026 GA of GitLab's Duo Agent Platform: customizable multi-step 'flows' that run issue-to-MR, CI/CD migra… · q4  #sdlc-with-ai
- [2026-05-30] https://www.stepsecurity.io/blog/when-ai-meets-ci-cd-coding-agents-in-github-actions-pose-hidden-security-risks — CI/CD-security vendor breaks down the specific attack surface when coding agents (Copilot, Claude Code) run inside Actio… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2512.22387 — Empirical study across Claude Code, OpenAI Codex, and Gemini over 300 projects (Python/JS/Java) finds only 68.3% execute… · q5  #sdlc-with-ai
- [2026-05-30] https://metr.org/blog/2026-02-24-uplift-update/ — METR — authors of the widely-cited July 2025 RCT that found AI slowed experienced devs 19% — publicly revise their own c… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2603.28592 — Liu, Widyasari, Zhao, Irsan, Chen & Lo (arXiv, Mar 2026) analyze 302.6k verified AI-authored commits across 6,299 GitHub… · q5  #sdlc-with-ai
- [2026-05-30] https://research.google/pubs/how-google-sres-use-gemini-cli-to-solve-real-world-outages/ — Official Google Research piece (Carlesso & Medrano Llamas, 2026) walking a full simulated outage with Gemini 3 CLI as a… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2601.22208 — FORGE 2026 peer-reviewed study (Riddell et al., Univ. of Waterloo group) running 48,000 simulated failure scenarios (~22… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2601.20171 — Empirical study of 1,997 documentation PRs (AIDev dataset) finding AI agents now submit substantially more doc PRs than… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/pdf/2406.14836 — Proposes 'document testing': an LLM generates executable tests from a doc comment, and test pass/fail becomes a signal o… · q5  #sdlc-with-ai
- [2026-05-30] https://github.com/grokify/traffic2openapi — Actively maintained (v0.4.0, May 2026) Go tool that captures HTTP traffic from HAR, Playwright, and proxy sources, norma… · q4  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2601.13118 — Midolo, Giagnorio, Zampetti, Tufano, Bavota, Di Penta (Jan 2026). Uses an iterative, test-driven refinement loop to disc… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2503.02400 — Chen, Wang, Sun, Liu, Zhang, Liu. Treats prompts as first-class software artifacts and maps the full SE lifecycle onto t… · q5  #sdlc-with-ai
- [2026-05-30] https://arxiv.org/abs/2508.03678 — Zi, Menon, Guha (Aug 2025). Introduces PartialOrderEval, a controlled minimal-to-maximal prompt-detail progression over… · q5  #sdlc-with-ai
- [2026-05-30] https://developers.openai.com/api/docs/guides/graders — Official OpenAI reference for the grader types used in evals and reinforcement fine-tuning: String Check, Text Similarit… · q5  #sdlc-with-ai
### legacy-modernization
- [2026-05-30] https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start — making a large/legacy codebase "legible" via layered CLAUDE.md, skills, hooks, LSP · q5  #legacy-modernization #complex-systems
- [2026-05-30] https://www.isaqb.org/blog/ai-agents-dont-modernize-legacy-code-on-their-own/ — guardrails before autonomy: seams, characterization tests, fitness functions · q4  #legacy-modernization
- [2026-05-30] https://sourcegraph.com/blog/legacy-code-modernization — 7 Rs, golden-file tests, strangler fig, shrink metrics as exit criteria · q4  #legacy-modernization
- [2026-05-30] https://arxiv.org/abs/2510.04852 — FreshBrew: Java-migration benchmark, 3 gates (compile / tests pass / coverage held) vs reward hacking · q4  #legacy-modernization
- [2026-05-30] https://arxiv.org/abs/2510.05441 — UnitTenX: multi-agent characterization-test generation guarded by formal verification · q4  #legacy-modernization
- [2026-05-30] https://arxiv.org/abs/2504.11335 — Code Reborn: COBOL→Java LLM modernization case study (intent extraction → re-express) · q3  #legacy-modernization

<!-- round 2 (2026-05-30): characterization / safety-net testing -->
- [2026-05-30] https://understandlegacycode.com/blog/can-ai-refactor-legacy-code/ — lock behavior with characterization tests BEFORE AI refactor (silent drift is the risk) · q4  #legacy-modernization
- [2026-05-30] https://understandlegacycode.com/blog/characterization-tests-or-approval-tests/ — disambiguates regression vs characterization vs approval/golden-master tests · q4  #legacy-modernization
- [2026-05-30] https://approvaltests.com/ — ApprovalTests: polyglot golden-master/approval testing libs (Llewellyn Falco) · q5  #legacy-modernization
- [2026-05-30] https://martinfowler.com/bliki/SelfTestingCode.html — Fowler: self-testing code, the single-command safety net refactoring needs · q5  #legacy-modernization

<!-- round 3 (2026-05-30): large-scale refactoring / codemods -->
- [2026-05-30] https://research.google/blog/accelerating-code-migrations-with-ai/ — Google: deterministic targeting (Kythe/Code Search) + fine-tuned Gemini edit gen · q5  #legacy-modernization
- [2026-05-30] https://abseil.io/resources/swe-book/html/ch22.html — SWE at Google Ch.22 Large-Scale Changes: Rosie shards mega-changes into atomic commits · q5  #legacy-modernization
- [2026-05-30] https://docs.openrewrite.org/ — OpenRewrite: Lossless Semantic Tree, deterministic format-preserving mass refactoring · q5  #legacy-modernization
- [2026-05-30] https://ast-grep.github.io/guide/rewrite-code.html — ast-grep: structural search-and-replace by AST (tree-sitter patterns) · q5  #legacy-modernization

<!-- round 5 (2026-05-30) saturation/enrichment: +5 net-new complementary -->
- [2026-05-30] https://techleadjournal.dev/episodes/195/ — Michael Feathers — author of Working Effectively with Legacy Code and originator of the 'legacy code = code without test… · q5  #legacy-modernization
- [2026-05-30] https://arxiv.org/abs/2411.04444 — Liu et al. (Nov 2024) measure LLM refactoring quality: 13/176 ChatGPT and 9/137 Gemini solutions were 'unsafe' — they ch… · q5  #legacy-modernization
- [2026-05-30] https://medium.com/airbnb-engineering/accelerating-large-scale-test-migration-with-llms-9565c208023b — Airbnb migrated ~3,500 React test files from Enzyme to RTL in 6 weeks (vs. an estimated 1.5 years manual) at a 97% autom… · q5  #legacy-modernization
- [2026-05-30] https://arxiv.org/abs/2504.09691 — Empirical Google paper (Ziftci et al.) on 39 distinct migrations by 3 developers over 12 months: 595 changes / 93,574 ed… · q5  #legacy-modernization
- [2026-05-30] https://github.blog/ai-and-ml/github-copilot/a-step-by-step-guide-to-modernizing-java-projects-with-github-copilot-agent-mode/ — Primary GitHub engineering walkthrough (GA Sept 2025) of the Copilot app-modernization agent: a six-stage assess -> plan… · q5  #legacy-modernization
<!-- round 6 (2026-05-30) broaden: +4 net-new wider -->
- [2026-05-30] https://aws.amazon.com/blogs/migration-and-modernization/accelerating-mainframe-modernization-testing-with-aws-transform/ — AWS describes its functional-equivalence testing model for agentic mainframe (COBOL/CICS/DB2/VSAM) modernization: AI-gen… · q5  #legacy-modernization
- [2026-05-30] https://davidadamojr.com/ai-generated-tests-are-lying-to-you/ — Practitioner argues AI-generated tests are self-fulfilling: deriving tests from existing code freezes current behavior (… · q4  #legacy-modernization
- [2026-05-30] https://arxiv.org/abs/2511.04824 — Empirical analysis of 15,451 AI-agent refactoring instances across 12,256 PRs in real open-source Java (AIDev dataset).… · q5  #legacy-modernization
- [2026-05-30] https://www.theregister.com/2026/04/15/gartner_mainframe_exit_analysis/ — Reports Gartner's Apr-2026 prediction that >70% of mainframe-exit projects started in 2026 will fail to deliver intended… · q4  #legacy-modernization
### complex-systems
- [2026-05-30] https://code.claude.com/docs/en/large-codebases — official monorepo/large-codebase setup: claudeMdExcludes, worktree sparsePaths, per-dir skills · q5  #complex-systems
- [2026-05-30] https://www.anthropic.com/engineering/built-multi-agent-research-system — orchestrator-worker pattern, token economics (~15x), subagents as context filters · q5  #complex-systems
- [2026-05-30] https://github.com/zilliztech/claude-context — semantic code-search MCP (BM25 + vector, Merkle incremental index) for million-line repos · q4  #complex-systems
- [2026-05-30] https://medium.com/devops-ai/the-virtual-monorepo-pattern-how-i-gave-claude-code-full-system-context-across-35-repos-43b310c97db8 — "virtual monorepo" pattern for cross-repo context over 35 repos · q3  #complex-systems
- [2026-05-30] https://blog.sshh.io/p/how-i-use-every-claude-code-feature — senior practitioner using every CC feature at scale (reality-check our assumptions) · q4  #complex-systems

<!-- round 2 (2026-05-30): code retrieval / indexing at scale -->
- [2026-05-30] https://cursor.com/blog/semsearch — Cursor: custom code-embeddings beat grep-only +12.5% on 1000+ file repos · q5  #complex-systems
- [2026-05-30] https://cline.bot/blog/why-cline-doesnt-index-your-codebase-and-why-thats-a-good-thing — counterpoint: chunking tears logic, indexes decay, embeddings = attack surface · q4  #complex-systems
- [2026-05-30] https://jxnl.co/writing/2025/09/11/why-grep-beat-embeddings-in-our-swe-bench-agent-lessons-from-augment/ — grep + agent persistence beat embeddings on SWE-bench; index as optional tool · q4  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2510.20609 — Practical Code RAG: BM25 wins code-to-code (~10x faster), dense only for NL-to-code · q5  #complex-systems

<!-- round 4 (2026-05-30): multi-repo/microservices · DB migrations · RAG over org knowledge -->
- [2026-05-30] https://arxiv.org/abs/2512.05908 — NL summarization for multi-repo bug localization (46 repos, 1.1M LOC, Pass@10 0.82) · q5  #complex-systems
- [2026-05-30] https://docs.pact.io/ai_tools/pactflow-skill — PactFlow AI skill: consumer-driven contract testing + can-i-deploy gates · q5  #complex-systems #software-tech
- [2026-05-30] https://arxiv.org/abs/2511.01166 — MicroRemed: microservice remediation benchmark (Ansible playbooks from diagnosis) · q5  #complex-systems
- [2026-05-30] https://atlasgo.io/blog/2025/08/19/teach-ai-agents-schema-management — constrain agents to schema-as-code + lint/dry-run/policy gates · q5  #complex-systems
- [2026-05-30] https://planetscale.com/blog/state-of-online-schema-migrations-in-mysql — Shlomi Noach: online schema-change survey (gh-ost author) · q5  #complex-systems
- [2026-05-30] https://github.blog/news-insights/company-news/gh-ost-github-s-online-migration-tool-for-mysql/ — gh-ost: triggerless binlog-based online MySQL migration · q5  #complex-systems
- [2026-05-30] https://github.com/sbdchd/squawk — Squawk: linter that flags unsafe Postgres DDL before it runs · q5  #complex-systems
- [2026-05-30] https://www.anthropic.com/news/contextual-retrieval — Contextual Retrieval: prepend chunk-level context (Contextual Embeddings + BM25) + rerank · q5  #complex-systems
- [2026-05-30] https://www.microsoft.com/en-us/research/blog/graphrag-unlocking-llm-discovery-on-narrative-private-data/ — GraphRAG: LLM knowledge graph + community summaries for global queries · q5  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2408.03910 — CodexGraph: repo symbol/relation graph via graph DB (NAACL 2025) · q5  #complex-systems
- [2026-05-30] https://www.microsoft.com/en-us/research/blog/lazygraphrag-setting-a-new-standard-for-quality-and-cost/ — LazyGraphRAG: GraphRAG-quality global search at vector-RAG cost · q5  #complex-systems

<!-- round 5 (2026-05-30) saturation/enrichment: +12 net-new complementary -->
- [2026-05-30] https://arxiv.org/abs/2506.15655 — Peer-reviewed (ACL Findings EMNLP 2025) method that chunks code along AST boundaries via a recursive split-then-merge ov… · q5  #complex-systems
- [2026-05-30] https://sourcegraph.com/blog/towards-infinite-context-for-code — Sourcegraph/Beyang Liu (Nov 2024) production evaluation of 1M-token long-context models for codebase QA. Finds long cont… · q5  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2602.20478 — Vasilopoulos (Feb 2026) reports building a 108k-line distributed C# system with heavy agent use, structured around a thr… · q5  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2603.27524 — MSR 2026 peer-reviewed study of 7,191 agentic PRs vs 1,402 human PRs (AIDev dataset, AST-based breaking-change detection… · q5  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2601.15195 — Large-scale empirical study of 33,596 agentic PRs across 5 agents (Codex 21,799; Copilot 4,970; Devin 4,827; Cursor 1,54… · q5  #complex-systems
- [2026-05-30] https://www.signadot.com/ai-smart-tests — Production vendor approach to cross-service change validation: ephemeral Kubernetes sandboxes deploy only the changed se… · q4  #complex-systems
- [2026-05-30] https://xata.io/blog/pgroll-internals — Maintainer (Andrew Farries, Xata) deep dive on pgroll's zero-downtime Postgres migration engine: per-version named schem… · q5  #complex-systems
- [2026-05-30] https://stripe.com/blog/online-migrations — Primary Stripe engineering case study (Jacqueline Xu) on migrating hundreds of millions of Subscriptions objects with ze… · q5  #complex-systems
- [2026-05-30] https://github.com/ayarotsky/diesel-guard — Rust migration linter that flags downtime-causing schema changes (non-CONCURRENTLY index creation, blocking ALTERs, unsa… · q4  #complex-systems
- [2026-05-30] https://github.blog/news-insights/product-news/copilot-new-embedding-model-vs-code/ — Official GitHub/Microsoft CoreAI engineering post (Sept 2025) on the new Copilot code-retrieval embedding model: 37.6% r… · q5  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2601.08773 — Empirical comparison (Jan 2026) of three retrieval pipelines on Java codebases (Shopizer, ThingsBoard, OpenMRS): vector-… · q4  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2509.25257 — Agentic repo-level retrieval (Sept 2025) that builds a repository knowledge graph down to variable-level cross-file depe… · q4  #complex-systems
<!-- round 6 (2026-05-30) broaden: +7 net-new wider -->
- [2026-05-30] https://www.amazon.science/publications/keyword-search-is-all-you-need-achieving-rag-level-performance-without-vector-databases-using-agentic-tool-use — AWS/Amazon Science (Feb 2026) systematic comparison finding tool-augmented agentic keyword search attains >90% of full R… · q5  #complex-systems
- [2026-05-30] https://nx.dev/blog/nx-ai-agent-skills — Official Nx post (Juri Strumpflohner, Feb 2026) on configuring agents for large Nx monorepos via portable 'agent skills'… · q5  #complex-systems
- [2026-05-30] https://nx.dev/blog/the-missing-multiplier-for-ai-agent-productivity — Nx (monorepo build-tool vendor) argues polyrepos blind agents to cross-project context and prevent atomic cross-service… · q4  #complex-systems
- [2026-05-30] https://atlasgo.io/guides/ai-tools/agent-skills — Official Atlas docs for an open Agent Skill that teaches Claude Code, Cursor, and OpenAI Codex the full migration lifecy… · q5  #complex-systems
- [2026-05-30] https://www.bytebase.com/blog/schema-as-code-to-schema-as-context/ — Argues schema-as-code (table/column versioning) is insufficient for AI agents: the real risk is an agent writing a 'corr… · q4  #complex-systems
- [2026-05-30] https://www.euronews.com/next/2026/04/28/an-ai-agent-deleted-a-companys-entire-database-in-9-seconds-then-wrote-an-apology — April 2026 postmortem: Cursor running Claude Opus 4.6 autonomously deleted PocketOS's production database AND all backup… · q4  #complex-systems
- [2026-05-30] https://arxiv.org/abs/2603.27277 — March 2026 cs.SE arXiv paper presenting a persistent tree-sitter knowledge graph (66 languages) exposed to LLMs via the… · q5  #complex-systems
### software-tech
- [2026-05-30] https://www.anthropic.com/engineering/writing-tools-for-agents — 5 principles for agent-friendly tools/APIs (consolidate workflows, namespacing, token efficiency) · q5  #software-tech
- [2026-05-30] https://notes.muthu.co/2025/11/the-architecture-is-the-prompt-guiding-ai-with-hexagonal-design/ — "the architecture is the prompt": hexagonal boundaries constrain AI better than long prompts · q4  #software-tech
- [2026-05-30] https://opentelemetry.io/blog/2025/ai-agent-observability/ — OTel GenAI semantic conventions: span-per-step agent observability · q5  #software-tech
- [2026-05-30] https://nitingavhane.medium.com/ai-coding-agents-are-hitting-a-wall-and-the-wall-is-your-architecture-a57ec11d20ce — layered monoliths → agent blast-radius; feature isolation keeps agents safe · q3  #software-tech
- [2026-05-30] https://addyosmani.com/blog/ai-coding-workflow/ — Addy Osmani's 2026 LLM coding workflow: spec-first, chunking, tests as feedback, commit save-points · q4  #software-tech
- [2026-05-30] https://techbytes.app/posts/agent-first-api-design-pattern-autonomous-llm-consumers/ — agent-first API properties: explicit capabilities, resumable state, idempotent mutations, executable errors · q3  #software-tech
<!-- round 2 (2026-05-30): agent security · architecture for agents -->
- [2026-05-30] https://www.anthropic.com/engineering/claude-code-sandboxing — OS-level filesystem+network isolation contains prompt injection; −84% prompts · q5  #software-tech
- [2026-05-30] https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ — "lethal trifecta": private data + untrusted content + exfil channel = vulnerable · q5  #software-tech
- [2026-05-30] https://owasp.org/www-project-mcp-top-10/ — OWASP MCP Top 10: token mismanagement, scope creep, shadow servers, supply chain · q5  #software-tech
- [2026-05-30] https://blog.gitguardian.com/yes-github-copilot-can-leak-secrets/ — AI completion reproduces real hard-coded secrets from training data · q4  #software-tech
- [2026-05-30] https://dev.to/somedood/coding-agents-as-a-first-class-consideration-in-project-structures-2a6b — vertical-slice modules so agents read one slice (LLMs degrade past ~40% context) · q4  #software-tech
- [2026-05-30] https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html — Uncle Bob: top-level structure should shout business use cases, not frameworks · q5  #software-tech
- [2026-05-30] https://www.jimmybogard.com/vertical-slice-architecture/ — VSA: "minimize coupling between slices, maximize within a slice" · q4  #software-tech
- [2026-05-30] https://www.milanjovanovic.tech/blog/what-is-a-modular-monolith — modular monolith: enforced boundaries + data isolation limit agent blast-radius · q4  #software-tech
<!-- round 3 (2026-05-30): prompt-injection design patterns -->
- [2026-05-30] https://arxiv.org/abs/2506.08837 — "Design Patterns for Securing LLM Agents": 6 patterns (action-selector, plan-then-execute, dual-LLM, …) · q5  #software-tech
- [2026-05-30] https://arxiv.org/abs/2503.18813 — Google DeepMind CaMeL: extract control/data flow into a capability-tracked program · q5  #software-tech
- [2026-05-30] https://blog.google/security/mitigating-prompt-injection-attacks/ — Google layered defense in Gemini: injection classifiers, security thought reinforcement · q5  #software-tech
- [2026-05-30] https://github.com/ReversecLabs/design-patterns-for-securing-llm-agents-code-samples — runnable Chainlit impls of all 6 securing-agent patterns · q4  #software-tech
- [2026-05-30] https://arxiv.org/abs/2406.13352 — AgentDojo: benchmark (97 tasks, 629 security cases) for injection attacks/defenses · q5  #software-tech
<!-- round 4 (2026-05-30): contract-first API · agent observability · security SAST/supply-chain · frontend design-to-code -->
- [2026-05-30] https://buf.build/docs/breaking/ — `buf breaking`: diff proto schema vs prior version, gate wire/JSON incompatibility · q5  #software-tech
- [2026-05-30] https://github.com/stoplightio/spectral — Spectral: OpenAPI/AsyncAPI/Arazzo linter with custom style-guide rulesets · q5  #software-tech
- [2026-05-30] https://blog.stoplight.io/api-design-first-vs-code-first — design-first vs code-first workflow (contract → mocks/docs → consumers) · q4  #software-tech
- [2026-05-30] https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/ — OTel GenAI agent span semantic conventions (create_agent/invoke_agent/invoke_workflow) · q5  #software-tech
- [2026-05-30] https://www.datadoghq.com/blog/llm-observability-at-datadog-security/ — build eval datasets from anonymized prod LLM spans + red-team · q4  #software-tech
- [2026-05-30] https://github.com/traceloop/openllmetry — OpenLLMetry: OTel-based auto-instrumentation for 10+ LLM providers/frameworks · q5  #software-tech
- [2026-05-30] https://langfuse.com/docs/observability/overview — Langfuse: trace/observation data model for the full LLM request lifecycle · q5  #software-tech
- [2026-05-30] https://semgrep.dev/blog/2025/building-an-appsec-ai-that-security-researchers-agree-with-96-of-the-time/ — Semgrep Assistant: LLM SAST triage matching researchers 96% · q5  #software-tech
- [2026-05-30] https://arxiv.org/abs/2406.10279 — package hallucinations: ~19.7% of LLM-recommended packages don't exist (USENIX Sec 2025) · q5  #software-tech
- [2026-05-30] https://snyk.io/articles/slopsquatting-mitigation-strategies/ — slopsquatting: registering AI-hallucinated package names + 7 defenses · q4  #software-tech
- [2026-05-30] https://github.blog/news-insights/product-news/secure-code-more-than-three-times-faster-with-copilot-autofix/ — Copilot Autofix: AI remediation applied 3x faster than manual · q5  #software-tech
- [2026-05-30] https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics — reusable frontend-aesthetics prompt + design-dimension techniques · q5  #software-tech
- [2026-05-30] https://www.figma.com/blog/introducing-figma-mcp-server/ — Figma Dev Mode MCP server: structured design context → AI coding tools · q5  #software-tech
- [2026-05-30] https://storybook.js.org/docs/writing-tests/visual-testing — Storybook visual testing: each story → pixel-snapshot diff vs baseline · q5  #software-tech

<!-- round 5 (2026-05-30) saturation/enrichment: +16 net-new complementary -->
- [2026-05-30] https://arxiv.org/abs/2604.04990 — Academic study (Konrad, Adam, Terrenzi, Ayvaz; arXiv, Apr 2026) introducing "vibe architecting" — architecture shaped by… · q5  #software-tech
- [2026-05-30] https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/ — OWASP GenAI Security Project's December 2025 release — the first peer-reviewed Top 10 framework targeting autonomous age… · q5  #software-tech
- [2026-05-30] https://www.microsoft.com/en-us/msrc/blog/2025/07/how-microsoft-defends-against-indirect-prompt-injection-attacks — Andrew Paverd / MSRC, July 2025. Lays out Microsoft's three-layer defense-in-depth: Prevention (hardened system prompts… · q5  #software-tech
- [2026-05-30] https://www.elastic.co/security-labs/mcp-tools-attack-defense-recommendations — Elastic Security Labs, Sept 2025. Empirical study of MCP attack surface — traditional code flaws (43% of tested servers… · q4  #software-tech
- [2026-05-30] https://arxiv.org/abs/2510.19274 — Oct 2025 research paper (Chauhan et al.) describing an LLM multi-agent pipeline that first generates an OpenAPI spec fro… · q5  #software-tech
- [2026-05-30] https://github.com/oasdiff/oasdiff — Apache-2.0 OpenAPI diff tool (1M+ downloads) that classifies 450+ categories of breaking changes across the whole spec (… · q5  #software-tech
- [2026-05-30] https://google.aip.dev/180 — Google's canonical API Improvement Proposal defining backwards compatibility across source/wire/semantic dimensions, wit… · q5  #software-tech
- [2026-05-30] https://code.claude.com/docs/en/monitoring-usage — Official Anthropic docs for enabling OTel in Claude Code: env-var config, the metrics/logs/events/traces signals it emit… · q5  #software-tech
- [2026-05-30] https://opentelemetry.io/blog/2026/genai-observability/ — May 2026 OTel blog walking through the span hierarchy of a single agent turn — top-level invoke_agent span containing ch… · q5  #software-tech
- [2026-05-30] https://www.langchain.com/articles/llm-monitoring-observability — Argues 200-OK/latency monitoring cannot detect wrong tool selection or reasoning loops; observability must be paired wit… · q4  #software-tech
- [2026-05-30] https://projectzero.google/2024/10/from-naptime-to-big-sleep.html — Google Project Zero + DeepMind's primary writeup of the Big Sleep LLM agent (Gemini 1.5 Pro) finding an exploitable stac… · q5  #software-tech
- [2026-05-30] https://www.darpa.mil/news/2025/aixcc-results — Official DARPA announcement of the AIxCC 2025 final results: autonomous AI cyber-reasoning systems found 18 real (non-sy… · q5  #software-tech
- [2026-05-30] https://blog.trailofbits.com/2025/08/08/buttercup-is-now-open-source/ — Trail of Bits open-sources Buttercup, its 2nd-place AIxCC cyber-reasoning system. Documents the concrete production arch… · q5  #software-tech
- [2026-05-30] https://vercel.com/blog/how-we-made-v0-an-effective-coding-agent — Vercel engineering deep-dive (Jan 2026, Max Leiter) on the three-part pipeline that makes v0's design-to-code reliable:… · q5  #software-tech
- [2026-05-30] https://www.figma.com/blog/design-systems-ai-mcp/ — Figma's Aug 2025 strategic post arguing the real unlock for AI design-to-code is a mature design system feeding the agen… · q5  #software-tech
- [2026-05-30] https://www.chromatic.com/docs/turbosnap/ — Official docs from the Storybook/Chromatic maintainers on TurboSnap: it uses Git history plus the Webpack/Vite dependenc… · q5  #software-tech
<!-- round 6 (2026-05-30) broaden: +12 net-new wider -->
- [2026-05-30] https://aws.amazon.com/blogs/architecture/architecting-for-agentic-ai-development-on-aws/ — Official AWS Architecture Blog (Mar 26, 2026) on restructuring codebases AND infra so AI agents can write/test/deploy au… · q5  #software-tech
- [2026-05-30] https://medium.com/@visrow/do-ai-coding-agents-reason-better-in-modular-monoliths-than-microservices-b2549e1c1ab3 — Vishal Mysore (May 14, 2026) frames the modular-monolith vs microservices question for AI agents as a falsifiable hypoth… · q4  #software-tech
- [2026-05-30] https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ — Official OWASP GenAI Security Project framework (published Dec 9, 2025; 100+ peer reviewers) defining the top agentic-AI… · q5  #software-tech
- [2026-05-30] https://www.theregister.com/security/2026/05/20/even-claude-agrees-hole-in-its-sandbox-was-real-and-dangerous/5243662 — The Register (May 2026) reports two now-patched bypass bugs in Claude Code's network sandbox — including a SOCKS5 hostna… · q4  #software-tech
- [2026-05-30] https://zircote.com/blog/2026/04/most-data-contract-tools-dont-enforce-contracts/ — Contrarian Apr-2026 critique (Robert Allen) arguing teams conflate DECLARING a contract (a doc sitting in a catalog with… · q4  #software-tech
- [2026-05-30] https://code.claude.com/docs/en/agent-sdk/observability — Official Anthropic doc for exporting OTel traces/metrics/logs from the Claude Code CLI: the concrete span hierarchy (cla… · q5  #software-tech
- [2026-05-30] https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/azure-ai-foundry-advancing-opentelemetry-and-delivering-unified-multi-agent-obse/4456039 — Official Microsoft Azure AI Foundry post announcing new OpenTelemetry semantic conventions for MULTI-agent systems, co-d… · q5  #software-tech
- [2026-05-30] https://arxiv.org/html/2601.02941v1 — New (Jan 2026) arXiv benchmark from Rival Labs evaluating LLM agents at classifying SAST findings as true/false positive… · q5  #software-tech
- [2026-05-30] https://github.blog/security/ai-supported-vulnerability-triage-with-the-github-security-lab-taskflow-agent/ — Official GitHub Security Lab post (Jan 20, 2026) describing Taskflow, an open-source agentic framework that decomposes C… · q5  #software-tech
- [2026-05-30] https://socket.dev/blog/curl-shuts-down-bug-bounty-program-after-flood-of-ai-slop-reports — Original reporting from supply-chain security vendor Socket on curl ending its HackerOne bug bounty (Feb 1, 2026) after… · q4  #software-tech
- [2026-05-30] https://webaim.org/projects/million/ — WebAIM's annual scan (published March 30, 2026) shows the first reversal in 7 years of accessibility progress: 95.9% of… · q5  #software-tech
- [2026-05-30] https://engineering.monday.com/how-we-use-ai-to-turn-figma-designs-into-production-code/ — monday.com engineering (Rivka Ungar, Feb 2, 2026) details a production LangGraph agentic pipeline: an 11-node workflow (… · q5  #software-tech

## Artifacts to build from (GitHub) — round 7 (2026-05-31)

> Reusable skills/agents/rules/hooks/commands harvested from GitHub + marketplaces,
> to seed/improve OUR skills. Format: `[kind · adoptability] url — what it is → seeds OUR <x>`.
> adoptability: lift-directly | adapt | study-pattern | reference-only. All q≥4, verified real.

### Skill / plugin collections
- [skill-collection · lift-directly · q5] https://github.com/anthropics/skills — Anthropic's canonical Agent Skills repo (~144k stars, actively maintained): SKILL.md examp… → Authoritative source for our SKILL.md header rules (name/description/Token budget). The /spec and /template directly validate and…
- [plugin · study-pattern · q5] https://github.com/anthropics/claude-plugins-official — Official curated Claude Code plugin directory (~29k stars, 441 commits). Shows the canonic… → Our install.sh currently renders core/preset files directly; this is the reference shape if we want our template to ship as an ins…
- [skill-collection · adapt · q5] https://github.com/wshobson/agents — Large, actively maintained (~36k stars, 437 commits) marketplace bundling 155 skills + 191… → Closest peer to our own bundle (skills+agents+rules in one template). Mine its code-review/testing/deploy/docs skills to enrich de…
- [subagent-collection · adapt · q5] https://github.com/VoltAgent/awesome-claude-code-subagents — Curated 154+ subagent collection (~21k stars, 476 commits) across Core Dev, Language Speci… → Direct seed/benchmark for our agent roster: architect-reviewer maps to senior-tech-lead, documentation-engineer/technical-writer t…

### Subagent collections
- [subagent-collection · study-pattern · q4] https://github.com/vijaythecoder/awesome-claude-agents — 24-agent orchestrated dev team. Notable trio: Tech Lead Orchestrator (analyzes projects, c… → Directly parallels our orchestrator + senior-tech-lead + onboarding-engineer. The Project Analyst + Team Configurator pattern (aut…

### Rules / CLAUDE.md collections
- [rules-claudemd · study-pattern · q4] https://github.com/josix/awesome-claude-md — Curated collection of exemplary real-world CLAUDE.md files mined from public GitHub projec… → The single best source for mining CLAUDE.md/memory-file patterns. Directly seeds improvements to our brain-hot.md, code-style.md,…
- [rules-claudemd · adapt · q5] https://github.com/github/awesome-copilot — Official GitHub repo (34.2k stars, 1,782 commits) with an instructions/ folder of coding-s… → Gold standard for 'rules auto-attached by file pattern.' The instructions/ files seed framework/language-specific content for our…
- [rules-claudemd · study-pattern · q5] https://github.com/PatrickJS/awesome-cursorrules — Large, widely-adopted collection (39.8k stars) of 100+ .mdc/.cursorrules project rule file… → Cross-tool reference for framework/language-specific rule content we can adapt into presets/ rule files, and the description+globs…

### Hooks collections
- [hook · lift-directly · q4] https://github.com/karanb192/claude-code-hooks — 410-star 'copy, paste, customize' collection of discrete, self-contained hooks: block-dang… → Smaller and more lift-directly than the mastery repo — each hook is a single droppable file. protect-secrets + block-dangerous-com…

### Slash-command collections
- [slash-command · adapt · q5] https://github.com/qdhenry/Claude-Command-Suite — 1.3k-star, actively maintained (v5.0.0, Mar 2026) toolkit of namespaced slash commands: /d… → Near-1:1 prompt-scaffold analogues for OUR deploy, changelog, retro, next-task/sprint, onboard, document, design-review and dispat…
- [slash-command · adapt · q5] https://github.com/wshobson/commands — 2.5k-star collection (starred by Simon Willison, Dan Guido) split into multi-agent workflo… → git-workflow command seeds OUR git-workflow rule (branching/PR-template prose); full-review + multi-agent-review seed OUR design-r…

### Testing / TDD skills
- [hook · adapt · q5] https://github.com/nizos/tdd-guard — Hook-based TDD enforcer (2.2k stars, 78 releases, active). Intercepts Claude Code Write/Ed… → Fills a hard gap: our template has NO TDD-enforcement mechanism and no testing hook. Could seed a new `tdd-enforce` hook plus a `t…
- [subagent-collection · adapt · q5] https://playwright.dev/docs/test-agents — Official Microsoft/Playwright agents installed via `npx playwright init-agents --loop=clau… → Seeds a net-new e2e-testing skill or a `e2e-test-engineer` subagent — our agent roster (backend/frontend/onboarding/orchestrator/t…
- [skill-collection · adapt · q4] https://github.com/affaan-m/everything-claude-code — Large, very active harness-optimization repo (1,997 commits, 170+ contributors, v2.0.0-rc… → Concrete, lift-able test patterns for a new core `test` skill — esp. the RED/GREEN/REFACTOR checkpoint-commit discipline (pairs wi…
- [rules-claudemd · study-pattern · q4] https://github.com/citypaul/.dotfiles/blob/main/claude/.claude/CLAUDE.md — Well-regarded practitioner dotfiles (665 stars). CLAUDE.md states TDD is non-negotiable: e… → Seeds a net-new `tdd` / `test-style` rule alongside our code-style and programming-fundamentals rules. The behavior-over-implement…

### Code-review skills
- [slash-command · adapt · q5] https://github.com/anthropics/claude-code-security-review — Official Anthropic repo (4.9k stars, actively maintained): ships a /security-review slash… → We have NO dedicated security-review gate. Lift security-review.md as a new slash command/skill and fold its vuln taxonomy + false…
- [skill · adapt · q5] https://github.com/anthropics/knowledge-work-plugins/blob/main/engineering/skills/code-review/SKILL.md — Official Anthropic engineering plugin skill. Trigger/symptom-based description ('review th… → Direct upgrade for post-delegation-gate and design-review: the four-dimension checklist and the CSO-style description are exactly…
- [subagent · study-pattern · q4] https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/04-quality-security/code-reviewer.md — Full code-reviewer subagent system prompt in a 20.9k-star curated collection. Structured c… → We have engineer agents (backend/frontend) and senior-tech-lead but no dedicated reviewer subagent. Study this for architecture/SO…

### Planning / spec-driven skills
- [slash-command · adapt · q5] https://github.com/github/spec-kit — Official GitHub SDD toolkit (107k stars, v0.8.18 May 2026, 153 releases). Ships a Claude C… → Directly seeds our `discover` skill and `design-doc-writer` agent. The clarify (ambiguity resolution), analyze (cross-artifact con…
- [skill-collection · adapt · q4] https://github.com/dceoy/speckit-agent-skills — 91-star focused reimplementation of Spec-Kit purely as portable agent skills (SKILL.md w/… → speckit-baseline (reverse-engineer a spec from an existing codebase) is a genuine gap — our `onboard` does codebase orientation bu…
- [plugin · adapt · q4] https://github.com/giuseppe-trisciuoglio/developer-kit — 261-star modular Claude Code plugin marketplace (v3.0.0 May 2026, 51 releases). developer-… → /specs:change-spec fills a gap — we have no delta/iteration spec-update flow (re-specifying when requirements shift mid-build); /s…

### Debugging / incident skills
- [subagent · adapt · q5] https://github.com/anthropics/claude-cookbooks/blob/main/managed_agents/sre_incident_responder.ipynb — Official Anthropic cookbook: an on-call agent that takes a PagerDuty-style alert, reads lo… → Seeds a net-new incident/root-cause debugging agent for our agent roster (we have no debugger/incident-responder) and directly imp…
- [subagent · adapt · q5] https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/04-quality-security/debugger.md — Subagent spec from a 20.9k-star, actively maintained (476 commits) collection of 154+ Clau… → Fills our gap of having no dedicated debugging agent — adoptable frontmatter (model routing, scoped tools Read/Grep/Bash) and a ro…
- [subagent · study-pattern · q5] https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/04-quality-security/error-detective.md — Companion agent in the same 20.9k-star repo focused on analyzing complex error patterns, c… → Pattern source for the distributed/log-correlation half of a debugging skill — relevant to enriching our `recover` skill and any f…

### Security skills / hooks
- [skill-collection · adapt · q5] https://github.com/trailofbits/skills — Trail of Bits' Claude Code skill marketplace (5.5k stars). 30+ audit plugins incl. static-… → Top-tier security-firm patterns to seed a SAST + dependency-audit + threat-model skill family. `differential-review` is a near-per…
- [hook · adapt · q4] https://github.com/lasso-security/claude-hooks — Recognized AppSec vendor (Lasso). PostToolUse hook that scans tool output, web fetches, an… → Fills a true gap: our template ships zero security hooks and no prompt-injection defense, yet our subagents routinely fetch web/do…
- [skill-collection · study-pattern · q4] https://github.com/AgentSecOps/SecOpsAgentKit — Active toolkit (155 stars) of 25+ SKILL.md-structured security skills: SAST (Semgrep/Bandi… → Reference for security-skill packaging at scale. Its standardized SKILL.md frontmatter + validate_skill.py linter informs how we'd…

### Documentation skills
- [skill-collection · adapt · q5] https://github.com/wshobson/agents/tree/main/plugins/documentation-generation — A composable plugin inside a 36.2k-star, actively maintained multi-harness marketplace (15… → ADR skill seeds our `document` skill and `design-doc-writer` agent — we have no dedicated ADR/decision-record format yet; lift its…
- [skill · study-pattern · q5] https://github.com/ComposioHQ/awesome-claude-skills/blob/master/changelog-generator/SKILL.md — Single SKILL.md in a 62.6k-star curated collection. Generates user-facing (not developer-f… → Complements our `changelog` skill (likely commit/keep-a-changelog oriented) with the customer-facing release-notes angle we lack:…

### Refactor / migration skills
- [plugin · adapt · q5] https://github.com/wshobson/agents/tree/main/plugins/framework-migration — In a 36.1k-star, actively-maintained (pushed 2026-05-29) plugin marketplace: a framework-m… → Fills a real gap: we have NO refactor/migration agent or skill. The legacy-modernizer agent seeds a new migration/modernization su…
- [skill · adapt · q5] https://github.com/ast-grep/agent-skill — Official ast-grep org (709 stars). Claude Code plugin/skill teaching Claude to write ast-g… → Provides the codemod engine + human-approval-before-apply pattern for a net-new structural-refactor skill (sibling to our document…
- [reference · reference-only · q5] https://github.com/codemod/codemod — 1k-star, actively maintained Rust CLI (pushed 2026-05-26) to scaffold, share, test and run… → Reference for the tooling layer our `migrate` skill would orchestrate — its YAML multi-step + approval-gate + CI model is a patter…

### Frontend / design-to-code skills
- [skill · adapt · q4] https://github.com/jezweb/claude-skills/tree/main/plugins/frontend/skills/design-loop — A SKILL.md that runs an iterative 'baton-passing' frontend build loop: generate HTML/Tailw… → Seeds our design-review skill and frontend-engineer agent with a concrete generate->screenshot->compare->iterate verification loop…
- [skill · study-pattern · q4] https://github.com/jezweb/claude-skills/tree/main/plugins/frontend/skills/design-review — A dedicated design-review SKILL in the same well-maintained recipe-style repo, focused on… → Direct namesake of our own design-review skill — useful as a comparison point to harden our review checklist and trigger/symptom-b…
- [subagent · adapt · q5] https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/04-quality-security/ui-ux-tester.md — Subagent (in a 20.9k-star, 154+ agent, actively maintained collection) for exhaustive docu… → Seeds our design-review skill and frontend-engineer agent: its structured defect-report schema and 'frustrated end-user' exhaustiv…

### DevOps / infra skills
- [skill-collection · adapt · q5] https://github.com/hashicorp/agent-skills — Official HashiCorp repo (MPL-2.0, ~642 stars) of Claude Code plugins/skills for Terraform… → Authoritative IaC source to seed an IaC/terraform skill for our k8s-helm preset (which currently has no Terraform/IaC skill) and t…
- [skill · adapt · q5] https://github.com/antonbabenko/terraform-skill — ~1.4k-star skill from a top Terraform module author. Enforces a strict four-pillar framewo… → The ordered, blocking lifecycle gate is a near-direct analog of our deploy-preflight skill — lift the gate-sequence-as-checklist p…
- [subagent-collection · adapt · q5] https://github.com/VoltAgent/awesome-claude-code-subagents/tree/main/categories/03-infrastructure — ~20.9k-star, actively maintained collection of 100+ complete subagent definitions. The 03-… → deployment-engineer's rollback-trigger + health-validation + progressive-delivery content directly hardens our deploy agent and th…

### Meta — skill-creator / validators
- [meta-tool · lift-directly · q5] https://github.com/anthropics/skills/tree/main/skills/skill-creator/scripts — Official Anthropic skill-creator ships a full Python harness: quick_validate.py (frontmatt… → We have 20 skills (archive, dispatch-parallel, retro, etc.) but NO tooling to test/grade/optimize them. quick_validate.py can beco…
- [meta-tool · adapt · q4] https://github.com/agent-ecosystem/skill-validator — Standalone Go CLI (150 stars, 25 forks, MIT, v1.5.6 Apr 2026, 21 releases — actively maint… → A drop-in CI lint gate for our skills/ tree that goes beyond schema: it would catch broken links and bloated reference files in ou…
- [reference · study-pattern · q4] https://github.com/metaskills/skill-builder/blob/main/converting-sub-agents-to-skills.md — 109 stars. Concrete migration guide: 4 transformation areas (description WHAT→WHEN, name n… → Directly serves our CLAUDE.md rule that skill descriptions must be trigger/symptom-based (CSO), not workflow summaries. The checkl…
- [plugin · study-pattern · q4] https://github.com/ivan-magda/claude-code-plugin-template — GitHub template repo (55 stars, MIT, v1.3.0 Dec 2025, actively maintained). Ships a plugin… → Our template currently distributes via install.sh (sed placeholder render). This shows the alternative/complementary path: packagi…

### Should-exist gaps
- [skill-collection · study-pattern · q4] https://github.com/utkusen/sast-skills — 648-star skill collection (by AppSec practitioner utkusen) turning an LLM coding agent int… → The two-phase recon→verify-before-reporting pattern and the fan-out of N specialist subagents is a direct upgrade template for our…

## Processed → sources/

<!-- moved lines: `- [date] url — note → sources/<file>` -->

- [2026-05-30] https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills → sources/2026-05-30-anthropic-agent-skills-authoring.md
- [2026-05-30] https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents → sources/2026-05-30-anthropic-context-engineering.md

## Archived

<!-- `- [date] url — note → archived: <reason>` -->
