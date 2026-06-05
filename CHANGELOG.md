# Changelog — AI-Workflows template

> Versioned changes to the **template itself** (the `core/` + `presets/` +
> `install.sh` you copy into a target project). Target-project changes do
> NOT belong here — those live in each project's own changelog (often
> produced by `/changelog`).
>
> Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) +
> semver. Each release should list **Added / Changed / Fixed / Removed**
> sub-sections as relevant.

## Unreleased

> **Lean Workflow Redesign (in progress)** — consolidating 22 skills → 6 verbs
> (`/idea /work /review /ship /retro /status`) + 3 niche (`/onboard /recover
> /document`), a hybrid sprint-folder state model under `docs/project/`, and a
> single naming cheat-sheet. Goal: far fewer commands to learn, a cleaner folder
> structure, and reference-on-demand detail — with design-first + the 6-gate
> rigor unchanged. Research-grounded (spec-kit / Kiro / BMAD command-surface
> studies; Anthropic + Cognition + MAST fan-out studies — see
> `docs/research/`).

### Removed

- **`doctor.sh` post-install health-check script**
  (`core/.claude/skills/onboard/scripts/doctor.sh`) and all references (onboard
  Stage 0, README quick-start, `docs/setup/plugin-dependencies.md`, the usage
  site). Plugin verification now points to the direct `jq` one-liner in
  `plugin-dependencies.md`; topology detection (`detect-topology.sh`) still
  drives `/onboard` Stage 0.
  - **Why / how it's better:** the script was broken and redundant; removing it
    shrinks the onboarding surface, and the repo validator
    (`scripts/validate-skills.sh`) already covers structural integrity.

### Changed

- **State folder `docs/spec/` → `docs/project/`** (rename + all ~69 inbound
  cross-references rewritten in lock-step), and the ideas-staging path
  `discovery/` → `ideas/`. `install.sh` / `install.ps1` / the upgrade classifier
  are updated in a later step (legacy `docs/spec/**` globs retained so existing
  installs are never clobbered).
  - **Why / how it's better:** "project" reads correctly to a new engineer and
    avoids the false "immutable spec" implication; one rename collapses the
    scattered references behind a single obvious path.

- **Hybrid sprint-folder state model** — the five scattered state surfaces
  collapse into a self-contained per-sprint folder:
  - `STATUS.md` + `STATUS-archive.md` + `FOLLOWUPS.md` are **eliminated**.
  - `docs/project/sprints/S<N>/tasks.md` is now **the board** — active-state
    glance (header) + task rows with `[ ]/[x]/[~]/[B]` state + live mini-retros,
    all in one file (replaces the STATUS glance + the old sprint table + the
    `retros/sprint-S<N>-tasks.md` mini-retro file).
  - `docs/project/sprints/S<N>/retro.md` is the sprint-close narrative (replaces
    `STATUS-archive.md` closing prose + the old `retros/sprint-S<N>.md`).
  - Follow-ups become a `## Follow-ups` section of `backlog.md` (`F####` IDs).
  - Per-task design docs move under the sprint: `sprints/S<N>/designs/D<NNN>-…`.
  - New scaffolds `docs/project/_templates/{tasks.md.tmpl, retro.md.tmpl}`, a
    folder map `docs/project/README.md`, and an id cheat-sheet
    `docs/project/NAMING.md`. `ideas/` (was `discovery/`) + `audit/` retained.
  - Rule **A008** restated: each sprint board is self-contained; at close, move
    the board's Glance prose into that sprint's `retro.md` (no cross-sprint
    STATUS to maintain). All non-skill references rewritten; skills updated next.
  - **Why / how it's better:** one board per sprint = no cross-file sync, a
    single source of truth, and a folder you can read top-to-bottom.

- **Skills consolidated 22 → 6 verbs + 4 niche** (user-invocable command surface
  cut by ~60%). Each old skill becomes a mode/flag of a verb:
  - **`/idea`** ← discover + promote · **`/work`** ← next-task + assign +
    dispatch-parallel + post-delegation-gate + tdd + design-first (now
    **auto-fans-out**: it runs the 4-layer Conflict Radar itself and dispatches a
    disjoint frontier in parallel, or auto-serializes — no separate parallel
    command) · **`/review`** ← design-review + security-review + the 6-gate
    (`/review gates`) · **`/ship`** ← deploy + deploy-preflight + changelog ·
    **`/retro`** ← retro + ratify-rules + archive · **`/status`** ← progress +
    audit-query.
  - **Niche kept:** `/onboard`, `/recover`, `/document`, `/flightdeck-feedback`.
  - `/tdd` and `/post-delegation-gate` are no longer commands — the TDD recipe
    moves to `docs/playbooks/tdd.md` and the 6-gate is the existing
    `post-delegation-review.md` playbook, both invoked inside `/work` (and
    re-runnable via `/review gates`). `/index-refresh` is removed (the board is
    self-contained; slim-index auto-refresh is dropped this pass).
  - All cross-references + skill links rewritten; the repo validator
    (`scripts/validate-skills.sh`) is green.
  - **Why / how it's better:** ~9 commands to learn instead of 22; one obvious
    verb per intent; the auto-fanout puts the parallel/serial decision (and the
    safety gate) inside `/work` instead of on the user. Grounded in spec-kit /
    Kiro command-surface research + Anthropic/Cognition fan-out research (see
    `docs/research/`).
  - **Note:** `/flightdeck-feedback` was kept standalone rather than folded into
    `/onboard` (onboard is already over the 250-line budget — folding would
    worsen a known issue; splitting onboard is a separate deferred pass).

### Added

- **Usage & workflow site (`site/`) + GitHub Pages** — a dependency-free
  static site that visually explains the template and its workflow, published
  via Pages.
  - `site/generate.py` (zero third-party deps, any `python3`) renders six
    pages with a Tesla-inspired minimal theme (`site/assets/style.css` +
    `deck.js`: scroll-reveal, count-up gauges, animated flight-path, frosted
    nav). Curated copy lives in `site/content/*.html.part`.
  - **Data-driven pages are generated from the repo's own sources of truth**
    so they can't drift: `changelog.html` ← `CHANGELOG.md`; `research.html` ←
    `docs/research/INDEX.md`; `agents.html` / `skills.html` ← the core (+
    preset) agent & skill frontmatter; live stat counters computed at build.
  - `.github/workflows/pages.yml` runs the generator on every push to `main`
    touching `site/**`, `CHANGELOG.md`, `docs/research/INDEX.md`, or the core
    agents/skills, then deploys `site/dist/` to Pages. (One-time repo setting:
    Pages → Source: GitHub Actions.) `site/dist/` is gitignored (built in CI).
  - Visual polish pass: an SVG favicon (no more `favicon.ico` 404);
    **animated use-case flows** — each mission profile's steps cascade in over
    a drawing timeline spine so the reader *watches* the sequence; a
    **Before → After** section ("vibes-first" vs the disciplined flow); ambient
    hero motion + a scroll cue; and a **deep-link / refresh reveal pre-pass**
    (deck.js) so any element already in or above the viewport reveals
    immediately and never sticks hidden, plus `scroll-margin-top` so `#anchor`
    jumps clear the fixed nav.
  - **Why / how it's better:** onboarding to the workflow was prose-only and
    slow; this is a scannable visual explainer (hero, use-case "mission
    profiles" — including the legacy-characterization and cost-routing
    upgrades — the S1–S7 pipeline, the 6-gate runway, agents/skills roster).
    Because the data pages derive from repo sources and rebuild on push, the
    public site stays truthful for free. The Pages workflow is minimal,
    secret-free, read-only-`contents` CI — reviewed as the executable config
    it is (per `agent-config-security.md`). Lives only in the template repo —
    `install.sh` never ships `site/`.

- **`/tdd` skill — test discipline as a slash command** — new
  `core/.claude/skills/tdd/SKILL.md` operationalizes the already-shipped
  `core/docs/setup/test-discipline.md` as an auto-loading, user-invocable
  skill. Trigger-based (CSO) description; a **Step 0** that classifies the
  change site (greenfield → red-green-refactor; **untested legacy →
  characterization-first, never a blocked commit**); a test-theater
  self-check; and a meta-check / handoff to Gate 4b. Wired as an entry point
  from `programming-fundamentals.md` (TDD pre-flight), `agent-pre-task-ritual.md`
  (Step 4 skill activation), `phase-matrix.md` (A001 tie-in), and the
  `core/docs/INDEX.md` skills cheat-sheet (counts reconciled: 21 skills / 18
  cheat-sheet rows); the doc back-links to it.
  - **Why / how it's better:** the discipline previously shipped only as a
    *doc* that relied on an agent remembering to read it. A skill with sharp
    triggers auto-loads at the moment a test is about to be written — so the
    legacy-safe mode-switch actually fires instead of being forgotten. No
    placeholders → no `.tmpl`, no installer change; ships on fresh install +
    `install.sh upgrade`. Research-traced to the **same synthesis** as the
    test-theater guard
    (`synthesis/sdlc-with-ai/test-theater-and-legacy-safe-tdd.md`) →
    `apply/shipped/test-theater-guard.md` (artifact #6) → INDEX scoreboard.

- **`/security-review` skill — Phase-7 security review as a slash command** —
  new `core/.claude/skills/security-review/SKILL.md` operationalizes Phase 7
  (Security review), which previously existed only as a trigger list in
  `phase-matrix.md` with no runnable procedure. It is **diff-aware** (reviews
  the pending diff, not the whole repo), **semantic** (reasons about a real
  source→sink→reachable path, not regex/pattern SAST), and makes
  **false-positive filtering a first-class step** (drops DoS / rate-limit /
  generic-validation / open-redirect / no-reachable-path) so the gate stays
  signal, not noise. Covers the 10-family vuln taxonomy; folds in a
  **supply-chain / slopsquatting dimension** (verify every newly-added manifest
  dependency actually exists + is the intended package — ~19.7% of LLM-suggested
  packages don't exist, and attackers squat the hallucinated names → install-time
  RCE); reuses the existing `agent-config-security.md` checklist as one
  dimension; and notes an **opt-in** prompt-injection PostToolUse hook
  (lasso-security/claude-hooks), NOT shipped by default (same posture as the
  tdd-guard hook). `phase-matrix.md` Phase-7 now invokes `/security-review` and
  gained a "new dependency in a manifest" trigger; `agent-config-security.md`
  points at it; INDEX counts reconciled (22 skills / 19 cheat-sheet rows).
  - **Why / how it's better:** Phase 7 was the only review phase with no
    procedure — in practice ad-hoc or skipped. This gives it a concrete,
    low-noise, diff-aware pass (same move as `/tdd` ← `test-discipline.md`) and
    closes a live install-RCE gap (slopsquatting) that our dependency-adding
    engineers are exposed to. No placeholders → no installer change; ships on
    fresh install + `install.sh upgrade`. Research-traced: sources
    (`anthropic-claude-code-security-review`, `slopsquatting-package-hallucination`,
    `cve-2025-59536`) → `synthesis/claude-code-core/security-review-as-a-skill.md`
    → `apply/shipped/security-review-skill.md` → INDEX scoreboard.

- **Skill/agent source validator (`scripts/validate-skills.sh`) + `validate`
  CI** — a dependency-free, **repo-only** gate (lives at the template root; never
  copied into a consumer project) that validates the template's OWN control-plane
  sources: every `core/.claude/skills/*/SKILL.md` has `name` + `description` +
  `## Token budget` with a `name` matching its directory, and a link sweep across
  `core/` catches rotted relative cross-links. It is **`.tmpl`-aware** (a link to
  `x.md` is satisfied by `x.md.tmpl`) and **metavar-aware** (skips `{{PH}}` /
  `<META>` path patterns), and flags a broken link only when its basename exists
  *elsewhere* in `core/` (a genuinely mis-pathed doc) — illustrative example paths
  are skipped + counted, not failed, so the gate stays high-signal. Oversized
  SKILL.md and non-CSO descriptions are warnings (never fail CI).
  `.github/workflows/validate.yml` runs it on PR/push to `main`; the maintainer
  `CLAUDE.md` "Verification cadence" runs it as step 0.
  - **Caught immediately:** a real mis-pathed link
    (`assign/references/repo-to-agent-mapping.md` → `docs/setup/conform-to-codebase.md`
    used `../../../` where `../../../../` was needed) — now fixed; and flagged
    `onboard`'s SKILL.md (343 lines) as a progressive-disclosure candidate.
  - **Why / how it's better:** the shipped `ai-workflow-validation.yml` validates
    an *installed* project's rendered `.claude/`, but nothing validated the
    template's own `core/` sources — so the hand-authored skills (including the
    new `/tdd` + `/security-review`, which carry many `../../../` links) had no
    mechanical check. This closes that gap and makes the four skill-authoring
    rules enforceable. Repo-only by design: no consumer-facing change, no
    `install.sh` change. Not research-driven (internal QA tooling) — rationale
    lives in the script header + the maintainer `CLAUDE.md`, no research-loop entry.

- **Agent-config security gate** — committed `.claude/` config is now
  treated as a code-execution surface across the control plane.
  - New `core/docs/setup/agent-config-security.md`: the trust model
    (committed `.claude/settings*.json` / `.mcp.json` / `.claude/hooks/*`
    run on every teammate's machine), the three CVE-2025-59536 /
    CVE-2026-21852 vectors (hook RCE, MCP auto-enable bypass,
    `ANTHROPIC_BASE_URL` exfiltration), the rule, and a Phase-7 reviewer
    checklist.
  - `core/.claude/rules/phase-matrix.md`: Phase 7 (Security review) now
    triggers on any diff to `.claude/settings*.json`, `.mcp.json`,
    `.claude/hooks/*`, or introducing `ANTHROPIC_BASE_URL` /
    `enableAllProjectMcpServers`.
  - `core/docs/setup/permission-profiles.md` + `secret-handling.md`:
    cross-linked + anti-pattern for the env-redirect exfil vector.
  - **Why / how it's better:** the template ships exactly the surface the
    CVEs target (hook block + hook scripts + `.mcp.json`) but had no
    review trigger for it. This fires the *existing* security gate when
    those files change — pure risk reduction, zero friction on normal
    work. Research-traced: `docs/research/` source →
    `synthesis/claude-code-core/committed-agent-config-is-a-supply-chain-surface.md`
    → `apply/shipped/`. Upgraders get it via `install.sh upgrade`
    (`template_owned` files).

- **"Document every change" rule** (`CLAUDE.md` rule 7) — every change
  must record what / why / how-it's-better in CHANGELOG + the doc itself
  + (if research-driven) the `docs/research/` apply loop.

- **Skill-authoring discipline shipped to `core/`** — new
  `core/docs/setup/skill-authoring.md` (reaches every installed project)
  codifying how to write a `SKILL.md`: required header (`name` /
  `description` / `## Token budget`), trigger/symptom-based (CSO)
  descriptions, **split-when-unwieldy** (progressive disclosure into
  `references/`), **execute-vs-read** script intent, and the rationale
  ("context is a finite, degrading resource — deliver the smallest set of
  high-signal tokens"). Linked from `core/docs/INDEX.md` (also backfilled
  the `agent-config-security` row). `CONTRIBUTING.md` "Improving a skill"
  + `CLAUDE.md` rule 4 add the two rules tersely and point to the canonical
  core doc.
  - **Why / how it's better:** the template *enforced* a Token-budget
    section but never wrote down *why* or the two implicit authoring rules;
    they lived only in maintainers' heads. Shipping them in `core/` gives
    project skill authors a citable standard, so skills stay high-signal
    and trigger correctly. Research-traced: the first two processed sources
    (Anthropic Agent-Skills authoring + Context engineering) →
    `synthesis/claude-code-core/context-discipline-as-design-constraint.md`
    → `apply/shipped/`.

- **"When NOT to parallelize" gate** — `core/.claude/rules/sub-agent-workflow.md`
  gains **§1.0 "When NOT to use multi-agent"** before the §1 decision tree,
  and `core/docs/playbooks/parallel-conflict-prevention.md` gains a **Step 0
  "is multi-agent even the right call?"**. Both state the ~15× token cost
  (Anthropic) and the context-fragmentation failure mode (Cognition "Don't
  Build Multi-Agents" + the MAST 14-failure-mode taxonomy), with the rule:
  default to one well-briefed agent; parallelize only when work is provably
  disjoint AND read-heavy/independent; compress long single tasks, don't
  split them.
  - **Why / how it's better:** the control plane was strong on *how* to
    parallelize safely but had no gate for *whether* to — so fan-outs could
    silently cost 15× and produce fragile, hard-to-reconcile output. This
    makes the dispatch decision conscious and evidence-backed without
    reversing the existing "default to inline / serialize" stance.
    Research-traced: `sources/2026-05-31-cognition-dont-build-multi-agents.md`
    → `synthesis/claude-code-core/when-not-to-parallelize.md` → `apply/shipped/`.

- **AGENTS.md cross-tool interop** — new `core/AGENTS.md`, a thin pointer
  to `CLAUDE.md` for agents that follow the open AGENTS.md standard
  (Codex, Cursor, GitHub Copilot, Gemini CLI, Aider, Amp, …). Restates the
  stable non-negotiables (design-first / test-first / review-gated /
  conform / agent-config-is-executable) and routes to `CLAUDE.md` for the
  full rule set.
  - `core/.flightdeck-upgrade.json`: `AGENTS.md` classified
    `seed_then_user_extends` (upgrade flags NEEDS-MERGE, never clobbers a
    user-extended copy).
  - `install.sh`: `AGENTS.md` added to the re-install backup loop
    (preserved like `CLAUDE.md`).
  - `core/CLAUDE.md.tmpl` + `README.md`: note that `CLAUDE.md` is the
    single source of truth and `AGENTS.md` is a pointer; added to the
    "What you get" tree.
  - **Why / how it's better:** `CLAUDE.md` is read only by Claude Code, so
    the template's rules were invisible to any other agent a teammate used
    on the same repo. AGENTS.md is the Linux-Foundation cross-tool standard
    (~21 tools, 60k+ repos; empirical ~28% runtime / ~16% token reduction).
    Now the discipline follows the *repo*, not the *tool* — with one source
    of truth (pointer design, no rule duplication / drift). Research-traced:
    `sources/2026-05-31-agents-md-open-standard.md` →
    `synthesis/adjacent-tools/agents-md-cross-tool-interop-via-pointer.md`
    → `apply/shipped/`.

- **Test-theater guard + legacy-safe TDD** — A001 mandated TDD but never
  defined test *quality* or handled untested legacy code.
  - New `core/docs/setup/test-discipline.md`: the principle (a test encodes
    INTENT, not current output), the **test-theater** anti-pattern table
    (asserting the mock, tautology, snapshot-everything, no-red-phase,
    behavior-as-intent, happy-path-only), the greenfield bar (property /
    invariant testing, mutation as meta-check), the **legacy-safe
    characterization path** (pin current behavior first — one test around the
    change site, never a blocked commit; approval/golden-master; seams;
    fitness functions), and an **opt-in** enforcement hook (`nizos/tdd-guard`)
    that is explicitly *not* shipped on by default, with a legacy caveat.
  - `core/.claude/rules/programming-fundamentals.md`: TDD pre-flight sharpened
    (intent-not-output, named theater anti-patterns, the legacy
    characterization branch).
  - `core/docs/playbooks/post-delegation-review.md`: Gate 4b gains a
    test-theater rejection step (when tests touched) + checklist note.
  - `core/.claude/rules/phase-matrix.md`: A001 note — untested legacy
    (`refactor`/`fix`) → "test first" = a characterization test.
  - `core/docs/INDEX.md`: `test-discipline` setup-doc row.
  - **Why / how it's better:** catches the dominant AI test failure mode
    (green-but-meaningless tests) *and* removes the biggest objection to
    adopting the template on a real legacy codebase — "no tests, the guard
    will block/break us." It won't: the discipline switches to
    characterization mode, stays advisory (rule + review-gate, never a hard
    write-blocker), and the only enforcement hook is opt-in. `brain-hot.md`
    (A001) intentionally untouched — this reinforces it. Research-traced:
    `sources/2026-05-31-ben3d-test-theater.md` +
    `…-understandlegacycode-characterization-tests.md` +
    `…-property-generated-solver.md` →
    `synthesis/sdlc-with-ai/test-theater-and-legacy-safe-tdd.md` →
    `apply/shipped/`.

### Changed

- **Cost-aware model routing — engineers default to Sonnet.** The control
  plane's own `agent-delegation-best-practices.md` §3 said "Sonnet =
  implementation default", yet every coding agent's frontmatter was
  `model: opus` — so the highest-volume agents pre-paid for Opus on every
  feature.
  - `core/.claude/agents/backend-engineer.md` + `frontend-engineer.md`:
    `model: opus` → `model: sonnet`, with a body note on the default + the
    escalate-to-Opus path. `orchestrator`, `design-doc-writer`,
    `onboarding-engineer` intentionally **stay Opus** (planning / synthesis /
    foundational authoring); `senior-tech-lead` + `sprint-retro-author` stay
    Sonnet.
  - `core/.claude/rules/sub-agent-workflow.md`: new **§1.5 Cost-aware model
    routing** (always-loaded) — tier table (Opus/Sonnet/Haiku) with per-agent
    defaults, cost evidence (Haiku ≈ ~1/3 cost & 2×+ speed; Opus ≈ ~5×
    Sonnet; ties to the §1.0 ~15× multi-agent multiplier), an escalation rule
    (Sonnet → Opus after ≥2 failing-gate rounds), and per-dispatch overrides
    (`Agent` frontmatter, Workflow `opts.model` per stage, `effort`).
  - `core/docs/setup/agent-delegation-best-practices.md` §3: cross-linked to
    §1.5 + Haiku-navigation / `effort` / Workflow-`model` notes (kept in sync).
  - **Upgrade impact:** agent files are `template_owned`, so
    `install.sh upgrade --apply-safe` will switch an installed project's
    engineer default from `opus` to `sonnet`. Teams that want Opus engineers
    set `model: opus` in their own copy or dispatch with an explicit override.
  - **Why / how it's better:** implementation-with-a-design-doc is Sonnet's
    sweet spot and the 6-gate review is the quality net, so this is the single
    biggest avoidable cost removed with no quality regression for the common
    case — while reserving Opus where judgment density warrants it.
    Research-traced: `sources/2026-05-31-anthropic-haiku-4-5.md` +
    `…-anthropic-effort-param.md` + `…-augmentcode-model-routing.md` →
    `synthesis/claude-code-core/cost-aware-model-routing.md` → `apply/shipped/`.

## v0.11.1 — 2026-05-27

### Fixed

- **`design-doc-writer` could not write its own output.** The agent's
  tool whitelist in `core/.claude/agents/design-doc-writer.md` was
  missing `Write` / `Edit` / `MultiEdit` / `Bash`, so the agent failed
  to author the markdown file its output contract requires. Added the
  four tools. Downstream projects upgrading via `install.sh upgrade`
  pick this up automatically (the file is classified
  `template_owned`).

## v0.11.0 — 2026-05-24

The **"safe upgrade path"** release — classified per-file upgrade scan that
knows which files are owned by the template (safe to overwrite), which are
seeded then user-extended (needs merge), and which are user-owned (never
touch). Replaces the previous `--force` re-install upgrade flow, which was
all-or-nothing and routinely blasted away project-local rules and
customized `CLAUDE.md`.

### Added

- **`core/.flightdeck-upgrade.json`** — file classification manifest with
  3 classes (`user_owned`, `seed_then_user_extends`, `template_owned`) and
  glob-pattern matching. Loaded by the upgrade subcommand to categorize
  every file in the new template before deciding what to do with each.
  Ships in every install (template-owned), so future upgrades pick up
  classification refinements automatically.
- **`install.sh upgrade <target>`** — new subcommand. Default behavior is
  a dry-run scan that prints a 5-section report:
  - `SAFE OVERWRITE` — template-owned files that changed (e.g. agents,
    skills, playbooks, design templates)
  - `NEW` — template-owned files added since the install
  - `NEEDS MERGE` — seed-then-extends files that changed (CLAUDE.md,
    brain-hot.md, settings.json, etc.) — flagged for hand-merge, never
    auto-overwritten
  - `NEW seed` — seed-then-extends files the install never had
  - `SKIPPED` — user-owned files the upgrade refuses to touch (sprints,
    retros, designs, FOLLOWUPS, STATUS, agent memory)
  Plus migration notes auto-extracted from CHANGELOG between the installed
  version and the target version.
- **`install.sh upgrade <target> --apply-safe`** — actually applies the
  SAFE OVERWRITE + NEW files. Backs up overwritten files to
  `<target>/.ai-workflows/upgrade-backups/v<from>-to-v<to>-<ts>/<orig-path>`
  for one-command rollback, then updates the manifest with the new version
  + source_commit + an `upgrade_history[]` entry recording the upgrade.

### Changed

- **`install.sh diff <target>`** "upgrade path" hint — now points at the
  new upgrade subcommand instead of suggesting `--force`.
- **`install.sh`** — `sed_escape` helper relocated to the top so both
  install and upgrade can share it. `shopt -s globstar nullglob` enabled
  globally so the classification matcher's `**` patterns work.

### Known limitations

- **PowerShell installer (`install.ps1`)** does NOT yet support `upgrade` —
  it prints a clear redirect to run the bash installer under WSL. Native
  PowerShell port is planned for a later release.
- **Seed-then-extends merge is still manual** for now. The dry-run flags
  what needs merging and where the new template version lives; an LLM-driven
  `/flightdeck-upgrade` skill that proposes a 3-way merge per-file is
  planned for v0.12.

## v0.10.0 — 2026-05-24

The **"design-phase escalation channels"** release — gives the
`design-doc-writer` subagent (which cannot call `AskUserQuestion`) three
distinct, machine-readable channels to surface "I'm unsure" / "this is
risky" / "I don't know enough" to the user, and teaches the orchestrator
to bundle each tier into the right `AskUserQuestion` call **before**
gate approval. Closes the most expensive failure mode: design-doc-writer
silently guessing on something load-bearing, then the impl agent shipping
the wrong thing.

### Added

- **`DESIGN_TEMPLATE.md` `## 1.5 Cross-System Impact & Knowledge Gaps`**
  (new top-level section between §1 Overview and §2 Architecture):
  - **§1.5.1 Blast Radius** — table of `# | Downstream consumer | How
    affected | Risk grade (HIGH/MEDIUM/LOW) | Mitigation`, optional
    mermaid cross-system sketch. Forces the design author to name every
    downstream system / service / consumer / business process this change
    touches, so risks become decisions instead of incidents.
  - **§1.5.2 Knowledge Gaps** — table of `# | What I need to know | Why |
    Likely source | Impact if I guess wrong | Resolved?`. Distinct from
    Open Questions (which has a default to ratify); a knowledge gap means
    "I don't have enough information to even propose a defensible default".
    Any unresolved row forces `NEEDS_CONTEXT` return.
- **`DESIGN_TEMPLATE.md` `## 10. Open Questions / Risks`** — enriched
  schema from `# | Question / Risk | Decision | Resolved?` to `# |
  Question | Severity | Default picked | Why this default | Impact if
  wrong | Resolved?`, with `load-bearing / material / cosmetic` severity
  legend that maps 1:1 to the subagent's return status.

### Changed

- **`design-doc-writer` agent** — "What you do" gains explicit
  Cross-System Impact scan + Knowledge Gap declaration steps. New
  "Handling ambiguity" section codifies a 5-class severity matrix
  (knowledge gap / load-bearing / HIGH blast-radius / material /
  cosmetic) → return status (`NEEDS_CONTEXT` / `DONE_WITH_CONCERNS` /
  `DONE`), with explicit guidance that knowledge gaps must NOT be
  compressed into open questions by inventing a default.
- **`agent-pre-task-ritual.md` Step 6** — clarifies that the four return
  statuses are subagents' only channel to the user (no
  `AskUserQuestion` for them) and points design-phase agents at the
  severity matrix.
- **`/next-task` Step 8b (new)** + **`/assign` Step 6b (new)** —
  orchestrator reads §1.5.2 → §1.5.1 → §10 in that order before gate
  approval, bundles unresolved rows by severity into `AskUserQuestion`
  calls (knowledge gaps and load-bearing → BLOCK and prompt; HIGH
  blast-radius → per-consumer prompt; material → bundle with default +
  impact; cosmetic → single batch prompt). After answers, updates the
  doc in-place (`Resolved? → [x]`, fills the chosen answer, appends a
  Change Log row) and commits before dispatching impl. Knowledge gap
  resolution re-dispatches the design-doc-writer via `SendMessage` so
  it can complete the doc body with the new context.

## v0.9.1 — 2026-05-23

Small installer-UX fix: surface the **required plugin install** step in the
installer's own "Next steps" output. Previously the requirement lived only in
`README.md` and `docs/setup/plugin-dependencies.md`; adopters who ran
`install.sh` / `install.ps1` and went straight to Claude Code could miss it
until `/onboard` Stage 0 (or a 6-gate review) failed.

### Changed

- **`install.sh` + `install.ps1`** now print a yellow `REQUIRED — install these
  Claude Code plugins…` banner immediately after `install complete.`, listing
  `pr-review-toolkit` (required) and `superpowers` (strongly recommended), and
  pointing at `docs/setup/plugin-dependencies.md`.
- **"Next steps" panel** in both installers gains an explicit
  `/plugin` step (install the two plugins) and `/onboard` step (Stage 0
  verifies them) before `/next-task`, so the install-time order matches what
  the control plane actually expects.

## v0.9.0 — 2026-05-22

The **"closing the loops"** release — adds a post-install health check so an
adopter can confirm the control plane is wired, and an operator-gated
ratification step so recurring retro lessons actually become permanent rules.

### Added

- **`doctor.sh`** (`core/.claude/skills/onboard/scripts/doctor.sh`) — a
  read-only post-install health check. Verifies structure, that no template
  placeholders leaked through install, plugin readiness (`pr-review-toolkit`
  FAIL / `superpowers` WARN), whether `code-style.md` is still the install stub,
  that `brain-hot.md` carries the A001..A010 block, spec scaffolding, and a
  valid `settings.json`. Emits `PASS / WARN / FAIL` per check + a `READY`
  verdict; exits non-zero on any FAIL so CI/automation can gate on it.
  Shipped as a **script, not a slash-command** (to keep the skill count lean) —
  `/onboard` Stage 0 runs it, and adopters run
  `bash .claude/skills/onboard/scripts/doctor.sh` right after install.
- **`/ratify-rules`** (`core/.claude/skills/ratify-rules/`) — the
  operator-gated landing step that closes the lesson → rule loop. Harvests the
  `## Candidate A-rules` that `sprint-retro-author` drafts in retros, walks the
  operator through ratify / defer / drop on each, and appends approved ones to
  `brain-hot.md` (`A011+`, next free number) plus a `lesson-trigger-map.md` row.

### Changed

- **`/retro` Step 9** now routes recurring-lesson promotion through
  `/ratify-rules` instead of implying a hand-edit of `brain-hot.md`.
- **`sprint-retro-author`** "Promoting a new A-rule" gains an explicit step 5:
  the user runs `/ratify-rules` to land candidates (the agent proposes, never
  lands).
- **`brain-hot.md` `## Project-specific rules`** header now states rules arrive
  via the `/ratify-rules` loop, not by hand-editing from a retro.
- **`plugin-dependencies.md`** verify section now points to `doctor.sh` as the
  friendly way to confirm plugin readiness.
- **README** quick-start adds the `doctor.sh` verify step + `/ratify-rules`
  (land retro rules); **INDEX** skills table adds `/ratify-rules` (16 → 17 rows).
- **`/onboard` Stage 0** now runs `doctor.sh` as an install-integrity
  pre-check (FAIL blocks onboarding; WARNs are expected on a fresh install).

## v0.8.1 — 2026-05-22

The **"plugin prerequisites"** release — makes the two Claude Code plugins the
workflow depends on explicit, and checks for them at onboard time.

### Added

- **`core/docs/setup/plugin-dependencies.md`** — documents the required
  `pr-review-toolkit` (drives Gate 4b) and strongly-recommended `superpowers`
  (TDD / verification / debugging skills the A-rules invoke), how to install
  them (`/plugin` → `claude-plugins-official`), and what degrades if missing.
- **`detect-topology.sh`** now emits a `plugins` object
  (`{"superpowers":bool,"pr-review-toolkit":bool}`) by reading
  `~/.claude/plugins/installed_plugins.json` (honors `CLAUDE_CONFIG_DIR`).
- **`/onboard` Stage 0** reads it and **warns** when either plugin is missing
  — pr-review-toolkit as near-blocking (Gate 4b falls back to the built-in
  `feature-dev:code-reviewer`, degraded), superpowers as a recommendation
  (the inline A-rules still apply).

### Changed

- **`README.md`** prereqs + **`docs/INDEX.md`** setup table now list the
  plugin prerequisites.

## v0.8.0 — 2026-05-22

The **"learn the codebase"** release — the template no longer imposes an
architecture. Instead of shipping prescriptive backend/frontend engineers
(hexagonal, Feature-Sliced Design, Pinia), core now ships **architecture-
agnostic** engineers that read the project's own conventions and conform.

### ⚠️ BREAKING

- **Removed the `go-hex`, `nextjs-fsd`, and `vue-pinia` presets** (their
  engineer agents, `hex-boundaries.md` / `fsd-layers.md` / `vue-patterns.md`
  rules, `hex-check` / `playwright-install` skills, and docs). Projects that
  installed them keep their copies, but the template no longer ships or
  recommends them. **`k8s-helm` is unchanged** (it's infra; it imposes no
  code architecture). Teams that want an enforced architecture can author it
  as a **custom preset** — see `docs/adding-new-preset.md`.
- Dispatch now defaults to the new core engineers; any project automation
  that hard-coded `go-hexagonal-engineer` / `frontend-fsd-engineer` / etc.
  must point at `backend-engineer` / `frontend-engineer`.

### Added

- **`backend-engineer` + `frontend-engineer`** (core, architecture-agnostic).
  They read `.claude/rules/code-style.md`, sample 2-3 representative files,
  and implement **in the project's existing style** — improving quality (TDD
  + the 6 gates) *within* the pattern, never reshaping it. A structural
  change is raised as a design suggestion (`DONE_WITH_CONCERNS`), not imposed.
- **`.claude/rules/code-style.md`** — a project-local "style contract" the
  engineers read. Ships as a stub; `/onboard` fills it from sampling real code.
- **`/onboard` Stage 3-D — code-style sampler** — a 4th mining agent that
  samples representative files per area+language and extracts naming, error
  handling, test structure, layout, and framework idioms →
  `code-style-signals.md` → `onboarding-engineer` writes `code-style.md`.
- **`detect-topology.sh`** now emits a `frameworks` array (next/vue/react) to
  steer the sampler, and only ever recommends the `k8s-helm` preset.

### Changed

- **Dispatch + boundary review rewired** to the generic engineers across
  `repo-to-agent-mapping.md`, `/next-task`, `/assign`, `orchestrator`,
  `sub-agent-workflow`, `CLAUDE.md.tmpl`, and the 6-gate playbook. Gate 3
  boundary review is now `senior-tech-lead` reading the project's own
  conventions (a custom preset may ship its own reviewer).
- **N1 reframed** from "architecture boundary (per preset)" to "the project's
  own boundary, captured in `code-style.md`".
- De-presetted every lingering hex/FSD/Pinia reference across rules, skills,
  playbooks, onboarding references, and docs (README, control-plane-architecture,
  windows-install, compliance-mapping, …).

### Note

`examples/url-shortener-go-hex/` stays as a **frozen sample of a hexagonal
project** (a project *can* be hex — the template just doesn't ship a hex
preset). Re-publishing the removed presets as example community presets is a
possible future follow-up.

## v0.7.0 — 2026-05-22

The **"conform, don't impose"** release — fixes the failure mode where a
preset installed on a *language* signal (a `go.mod` → `go-hex`) made the
engineer agent impose its architecture (hexagonal / FSD / Pinia / Helm) on
a project that doesn't actually follow it, producing wrongly-shaped code.

### Added

- **`core/docs/setup/conform-to-codebase.md`** — the detect → conform → ask
  discipline. A preset's architecture is a **default, not a mandate**: read
  the project's real layout first, conform to it, and STOP-and-ask
  (`NEEDS_CONTEXT`) before introducing the preset's architecture into a
  project that doesn't use it.
- **`arch_fit` probe** in `detect-topology.sh` — for each recommended preset
  it now checks the architecture's signature dirs/tooling (go-hex:
  `internal/{domain,ports,usecase}` or `verify-isolation`; nextjs-fsd:
  `features`+`entities` or `eslint-plugin-boundaries`; vue-pinia: `pinia` +
  `stores/`; k8s-helm: `Chart.yaml`) and emits `"arch_fit": {"go-hex":
  "high|low", …}`.
- **`/onboard` Stage 0 warning** — when a recommended preset has
  `arch_fit: low`, the wizard warns the operator that installing it won't
  make the project hex/FSD and the engineer will conform-not-impose.

### Changed

- **`agent-pre-task-ritual.md`** — new Step 1.5 "Detect & conform to the
  project's ACTUAL conventions" (read representative files; preset
  architecture yields to the codebase's reality; ask on mismatch). All
  coding agents inherit it.
- **All 6 preset engineers** (`go-hexagonal-engineer`,
  `kafka-pipeline-engineer`, `observability-engineer`,
  `frontend-fsd-engineer`, `vue-engineer`, `k8s-engineer`) — reframed from
  "strict / non-negotiable architecture" to "this preset's **default**;
  confirm the project follows it (a Step 0.5 detection), conform to the
  real layout otherwise, and report `NEEDS_CONTEXT` before imposing".
  Boundary tooling (`verify-isolation`, `eslint-plugin-boundaries`) is now
  conditional on the project actually using it.
- **`hexagonal-reviewer`** — reports `NOT-APPLICABLE` instead of flagging
  "violations" against a service that isn't hexagonal.

### Why

Presets are recommended on language signals, which don't prove architecture
fit. The engineer agents previously treated the preset architecture as
absolute and imposed it. Now the codebase's observed reality wins, and
introducing a new architecture is an explicit, asked-for design decision
(A005) — not a side effect of a feature task.

## v0.6.0 — 2026-05-22

The **"discipline-enforcement"** release — adopts the techniques that make
the [superpowers](https://github.com/obra/superpowers) plugin's rules stick,
applied to flightdeck's own authored rules and gates. Flightdeck already
*invoked* superpowers skills at the right gates; this release hardens its own
rules with superpowers' enforcement *patterns*.

### Added

- **`core/docs/setup/discipline-red-flags.md`** — an "excuse → reality"
  rationalization table for each of A001-A005 (TDD, zero-bug, verify,
  6-gate, design-first), plus per-rule **Iron Law** and red-flag lists.
  Adapted from superpowers' `test-driven-development` /
  `verification-before-completion` / `systematic-debugging` skills.
- **Gate 4a — Spec-compliance** in the 6-gate review: verify the code
  implements every D-doc AC and **nothing extra** (read code, don't trust
  the report) BEFORE the parallel quality reviewers (now Gate 4b). Still
  "6 gates"; Gate 4 is now two-stage (4a → 4b). Mirrors superpowers'
  spec-then-quality two-stage review.
- **Structured return statuses** — dispatched agents now lead their reply
  with `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`, and
  `/next-task` + `/assign` carry an orchestrator handling table
  (re-dispatch on NEEDS_CONTEXT, assess/escalate on BLOCKED, etc.).
- **3-strikes debugging escalation** — `fix` tasks must root-cause first
  (`superpowers:systematic-debugging`); after 3 failed fix attempts on the
  same bug, STOP and question the architecture. Encoded in `phase-matrix`,
  `programming-fundamentals`, and the `fix` dispatch brief.
- **Announce-the-discipline convention** — the discipline skills
  (`/next-task`, `/assign`, `/post-delegation-gate`, `/dispatch-parallel`,
  `/design-review`) open by naming the discipline they're running.

### Changed

- **`brain-hot.md.tmpl`** — A001-A005 each gain a one-line **Iron Law**;
  A004 now describes the 4a/4b split; links the red-flags doc.
- **`post-delegation-review.md`** — Gate 4 split into 4a/4b; new
  "rationalizations for skipping a gate" table; fixed a stale `§N4` → `§N3`
  (the 6-gate review is N3, not N4).
- **CSO skill descriptions** — codified the rule (descriptions must be
  trigger/symptom-based, not workflow summaries) in `CONTRIBUTING.md` +
  the maintainer `CLAUDE.md`; tightened `/post-delegation-gate`'s
  description to auto-trigger when a coding subagent returns. (Audit found
  the other 18 descriptions already trigger-based.)
- Propagated the 4a/4b split + return-status protocol across
  `sub-agent-workflow.md`, `agent-pre-task-ritual.md`,
  `lesson-trigger-map.md`, `CLAUDE.md.tmpl`, `INDEX.md`, and the
  `dispatch-prompt-template`.

### Why

Superpowers is a discipline system: each rule pairs an **Iron Law** with a
**rationalization table** and **structured statuses**, and reviews in two
stages (spec then quality). Flightdeck's rules were declarative and so
softer against the exact shortcut-taking those patterns prevent. This
release closes that gap without bloating the auto-loaded `brain-hot.md`
(the heavy tables live in the linked red-flags doc).

## v0.5.0 — 2026-05-22

The **"file-based dispatch"** release — stops oversized inline prompts
from stalling subagents. Instead of pasting a long task spec into the
`Agent` `prompt` argument, the orchestrator writes a **brief file** and
dispatches with a short pointer prompt; the agent reads its brief first.
Modeled on the [superpowers](https://github.com/obra/superpowers)
plugin's plan/spec-file + prompt-template-file pattern.

### Added

- **`core/docs/setup/file-based-dispatch.md`** — the convention: why
  long inline prompts hang, the brief-file location/naming
  (`docs/designs/sprint-S<N>/_briefs/<TASK_ID>-<role>.md`), the short
  pointer-prompt shape, lifecycle/commit guidance, and a worked example.
- **Pre-task ritual Step 0** (`agent-pre-task-ritual.md`) — every agent
  now reads its brief file FIRST when the dispatch names one. Single
  shared edit ⇒ all 12 agents (5 core + 7 preset) become brief-aware.

### Changed

- **All 12 agent files** — each gains a "Step 0 — read your brief"
  pointer in its pre-task ritual (role-specific:
  `design`/`impl`/`review`/`retro`). The `orchestrator` also gains a
  "write a brief, dispatch a pointer" note for when it dispatches.
- **`/next-task`, `/assign`, `/dispatch-parallel`** — dispatch steps now
  write the spec to a brief file and dispatch a short pointer prompt
  instead of inlining the full spec.
- **`dispatch-prompt-template.md`** — reframed as the **brief-file
  content** plus a short pointer-prompt template (was: "paste this as
  the inline prompt").
- **`sub-agent-workflow.md`** §3 — file-based dispatch is now the
  documented default for non-trivial work; inline only for tiny
  (~≤30-line) tasks.

### Why

A multi-thousand-line `prompt` string can stall the dispatch before the
subagent starts. A short pointer + a re-readable, auditable brief file
is robust, keeps the orchestrator's context lean, and lines the audit
trail up with a concrete artifact.

## v0.4.1 — 2026-05-22

The **"self-containment"** release — makes every rule and lesson
reference resolve **in-repo**, so adopters who don't have the original
external "second brain" never hit a dangling pointer. Also reconciles a
two-scheme A-rule numbering collision inherited from the source repos.

### Fixed

- **Dangling lesson references (17)** — `L005, L008, L021, L022, L023,
  L026, L030, L033, L036, L040, L041, L042, L049, L058, L063, L102,
  L109` were cited in the design templates / workflow docs but defined
  nowhere in-repo. All now have a one-line definition in the
  `lesson-trigger-map.md` `L###` reference table.
- **A-rule numbering collision** — two conflicting schemes
  (`brain-hot.md`'s global A001-A010 vs. an older domain scheme where
  A013=LSP, A015=design-first, A016=mini-retro, A017=backlog-audit, and
  A001-A011 carried domain meanings). Canonicalized to **one** meaning:
  A001-A010 = the global always-apply rules; A011+ = project-local.
  Stale `A013/A015/A016/A017` references remapped to `A010/A005/A009/A008`
  across `workflow-master.md`, `getting-started-tour.md`,
  `zero-fix-task-template.md`, `compliance-mapping.md`, and both
  playbooks.
- **Dangling file reference** — `.claude/rules/project-local.md` (never
  shipped) was referenced by the two playbooks and several docs;
  re-pointed to `brain-hot.md` (A011+) + `lesson-trigger-map.md`.
- **6-gate cross-refs** — several docs cited `§N4` for the 6-gate review;
  corrected to `§N3` (N4 is parallel-conflict-prevention).

### Changed

- **`lesson-trigger-map.md`** — de-domain-specified: backend/frontend
  tables now use stack-neutral `N1`/`N2` + defined `L###` instead of
  colliding domain `A###`; removed hardcoded RBAC / Kafka / framework
  paths; dropped the "full lesson detail lives in your brain / MemPalace"
  framing (the table **is** the detail now).
- **`brain-hot.md.tmpl`** — `BRAIN_PATH` framed as explicitly optional;
  header states the template is fully self-contained without an external
  brain.
- **De-domain-specifying** — removed leftover source-repo names
  (`idip-platform`, `aggegator`, `claude-foundation`) and example task
  IDs (`IDIP-`, `AGG-`) from `core/` per the template's own ground rules.

## v0.4.0 — 2026-05-22

The **"feedback loop"** release — closes the distributed-template gap:
adopters can now send structured feedback back to the canonical repo
without any always-on phone-home. Pull-based, zero passive token cost.

### Added

- **GitHub issue forms** (`.github/ISSUE_TEMPLATE/`) — 5 structured
  YAML forms (bug / rule-feedback / preset-request / skill-feedback /
  onboarding-feedback) each with a template-version dropdown, plus a
  `config.yml` routing to Discussions + onboarding guide + CONTRIBUTING.
- **`/flightdeck-feedback` skill** (`core/.claude/skills/flightdeck-feedback/`)
  — opt-in, one-shot. Reads the install manifest for version context,
  asks the feedback type, drafts a structured issue body, **redacts
  secrets**, shows a **preview**, then opens the issue via `gh` (or
  prints a prefilled URL). Never sends automatically.
- **`CONTRIBUTING.md`** — 4 contribution paths (issue / discussion /
  in-Claude skill / PR), `core/` ground rules, local contributor setup.
- **`.github/PULL_REQUEST_TEMPLATE.md`** — VERSION-bump + CHANGELOG +
  de-domain-specify + token-budget checklist.
- **`core/docs/setup/feedback.md`** — ships into every project; how to
  send feedback upstream (prefilled URLs + skill + sanitized-retro
  sharing).

### Changed

- **`install.sh`** — Next-steps output now mentions `/flightdeck-feedback`.
- **`README.md`** — new "Feedback & contributing" section.

### Design note

Feedback is **pull, not push** — nothing phones home, every send shows
a preview first, and the only token cost is the one-shot
`/flightdeck-feedback` invocation (~5-10k, opt-in). No always-on
telemetry by design (privacy + token-cost).

## v0.3.0 — 2026-05-22

The **"adopter onboarding"** release — adds an 8-stage setup wizard
that takes a fresh install from `template files in place` to
`Claude Code understands this project`. Multi-repo aware: detects
sibling installs and offers soft inheritance of project-local
A-rules.

### Added

- **`/onboard` skill** (`core/.claude/skills/onboard/SKILL.md`,
  ~330 lines) — user-invocable 8-stage hybrid wizard. Auto-does
  mechanical work (topology detection, codebase scan, git history
  mining, document drafting); prompts the operator only for context
  Claude can't infer (team interview, A-rule ratification, sprint
  state). Subcommands: `refresh` / `scan` / `rules` / `retro`.
- **`onboarding-engineer` agent**
  (`core/.claude/agents/onboarding-engineer.md`) — doc-drafting
  specialist for Stage 4. Reads codebase scan + interview answers
  + git-mining signals; writes root + per-area `CLAUDE.md`, polished
  `codebase-orientation.md`, `team-conventions.md`, and **drafts**
  (never auto-applies) A011+ rule candidates for operator
  ratification.
- **3 helper scripts** under
  `core/.claude/skills/onboard/scripts/`:
  - `detect-topology.sh` — JSON output of repo type (single /
    monorepo / meta), languages, areas, sibling installs, preset
    recommendations
  - `mine-git-history.sh` — fix-class commit aggregation → JSONL
    of hotspot files / keyword frequency / revert hotspots
  - `extract-pr-comments.sh` — `gh`-based recent PR review-comment
    extractor for convention sniffing (fail-open if `gh` missing)
- **5 reference deep-dives** under
  `core/.claude/skills/onboard/references/`:
  `repo-topology-detection.md`, `interview-questions.md`,
  `pattern-mining-prompts.md`, `draft-templates.md`,
  `multi-repo-coordination.md`.
- **`docs/setup/onboarding-guide.md`** (~330 lines) — operator
  companion for `/onboard`. Walks the 8 stages with what-to-expect
  per stage, multi-repo decision tree, common stumbles, FAQ.
- **`docs/setup/sibling-repos.md.tmpl`** — lands when `/onboard`
  detects multi-repo inheritance; documents the soft-inheritance
  link + conflict-resolution protocol.
- **`docs/setup/retention-policy.md`** (extracted from
  `audit-trail.md`) — full retention policy across all artifact
  classes (audit logs, sprints, retros, design docs).

### Changed

- **Root `CLAUDE.md.tmpl`** — new dispatch-routing row for
  first-time setup ("→ `/onboard`").
- **`.claude/rules/brain-hot.md.tmpl`** — `## Where to look next`
  now leads with "First time? Run `/onboard`".
- **`README.md`** — new "After install — run `/onboard`" section
  promoting the wizard right after the install command.
- **`getting-started-tour.md`** — new **Step 0** at the top:
  "Run `/onboard` first."
- **`audit-trail.md`** — Retention section now points at
  `retention-policy.md` for the full policy (deduplication).

### Fixed

- (none — `v0.3.0` is purely additive)

## v0.2.0 — 2026-05-22

The "operational tier" release — adds drift control, audit trail, CI
enforcement, and a recovery path. Aligned with the 6-gate review +
A001-A010 hot rules.

### Added

- **`VERSION` file** at the template root (single line, semver). Read
  by `install.sh` and exposed as `$AIWF_VERSION`.
- **`install.sh --version` flag** — prints `AI-Workflows vX.Y.Z` and
  exits.
- **`install.sh diff <target>` subcommand** — reports drift between a
  target's `.ai-workflows/manifest.json` and the current template
  version. Lists per-file drift since the manifest's
  `source_commit`.
- **`$TARGET/.ai-workflows/manifest.json`** — written at install end.
  Captures version, ISO8601 install date, presets used, placeholder
  names (no secret values), and `source_commit` (template repo
  `git rev-parse --short HEAD`, empty for tarball installs).
- **`CHANGELOG.md`** — this file. Versioning + retro-friendly
  history of template-level changes.
- **Audit-trail hook**:
  `core/.claude/hooks/audit.sh` (PostToolUse on `Agent` +
  SubagentStop) — appends one JSONL line per agent dispatch /
  completion to `docs/spec/audit/YYYY-MM.jsonl`. Fail-open (never
  blocks dispatch). Schema documented in
  `docs/setup/audit-trail.md`.
- **`docs/setup/audit-trail.md`** — JSONL schema, retention policy
  defaults (12 months baseline, longer for SOC2), redaction guidance,
  jq query recipes ("dispatches by agent X", "gate failures last
  week"), SIEM ingestion notes.
- **PR-blocking 6-gate CI workflow**:
  `core/.github/workflows/post-delegation-gate.yml` — runs on
  `pull_request` to `main` + integration branches. Maps each of the 6
  gates to a job step (Inspect / Build+Test / Boundary / Quality /
  Wiring / Smoke). Quality step is a logged no-op (humans + reviewer
  agents do this in PR).
- **Cross-CI stubs** at `core/docs/setup/ci-stubs/`:
  `gitlab-ci.yml.example`, `Jenkinsfile.example`,
  `azure-pipelines.yml.example`, `.circleci/config.yml.example`.
- **`docs/setup/ci-integration.md`** — per-CI adaptation guide,
  secret / variable wiring, lint-hook-in-CI vs local notes.
- **`/recover` skill**:
  `core/.claude/skills/recover/SKILL.md` — safe recovery from
  partial-dispatch failures, orphan worktrees, mid-merge aborts,
  accidental main commits, lost branches. User-invocable.
- **`docs/playbooks/failure-recovery.md`** — 6-8 named scenarios with
  detailed walkthroughs, decision tree ("when to recover vs leave
  alone"), specific `/dispatch-parallel` partial-success guidance.

### Changed

- `install.sh` now records `manifest.json` at install end (visible
  drift surface for multi-project installs).
- `core/.claude/settings.*.tmpl` (all permission-profile variants —
  `restricted` / `standard` / `permissive`) gain a PostToolUse
  matcher on `Agent` and a SubagentStop matcher calling `audit.sh`
  alongside the existing `Write|Edit|MultiEdit` lint hook.
- `README.md` gains a **Versioning & upgrades** section pointing at
  `VERSION`, `manifest.json`, and `install.sh diff`.

### Notes

- Re-install with `--force` (after backup) remains the upgrade path
  until `install.sh upgrade` lands (out of scope for v0.2.x).
- Audit JSONL is **opt-in** via `.gitignore` — see
  `docs/setup/audit-trail.md` for whether your repo should track or
  ignore the audit folder.

## v0.1.0 — initial template lift

- Initial extraction from `idip-platform` + `aggegator` —
  de-domain-specified `core/` + four presets (`go-hex`, `nextjs-fsd`,
  `vue-pinia`, `k8s-helm`).
- 14 user-invocable skills (`/next-task`, `/promote`, `/discover`,
  `/assign`, `/progress`, `/archive`, `/retro`, `/document`,
  `/dispatch-parallel`, `/design-review`, `/post-delegation-gate`,
  `/deploy`, `/changelog`, `/index-refresh`).
- 4 core agents (`orchestrator`, `design-doc-writer`,
  `senior-tech-lead`, `sprint-retro-author`).
- 7 always-loaded rules (`brain-hot`, `agent-pre-task-ritual`,
  `lsp-first`, `sub-agent-workflow`, `phase-matrix`,
  `programming-fundamentals`, `git-workflow`).
- Lint dispatcher PostToolUse hook (`core/.claude/hooks/lint.sh`).
- AI workflow validation CI
  (`core/.github/workflows/ai-workflow-validation.yml`) — checks
  placeholder render + agent / skill frontmatter.

[unreleased]: ./
