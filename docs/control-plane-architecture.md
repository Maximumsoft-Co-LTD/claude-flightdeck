# The AI control-plane pattern

This template ships a layered system that turns Claude Code from a smart
autocomplete into a project-aware orchestrator with discipline. The
layering exists because of three forces that cost real work:

1. **Sub-agents don't inherit context.** A `Agent(subagent_type=...)`
   call starts with an empty mind. Without an explicit ritual that
   re-reads the rules, sub-agents forget half of what the main session
   knows.
2. **Self-summaries lie.** "Tests pass." Don't believe it. Read the
   diff. Run the test. The 6-gate post-delegation review is the
   antidote.
3. **Parallel work eats itself.** Two coders editing overlapping paths
   without isolation will collide silently and you'll find out at
   merge.

The control plane is the codified counter-measure to all three.

---

## The seven layers

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. ROOT CLAUDE.md                                                   │
│    The orchestrator's manual. Non-negotiables (N1-N7), dispatch     │
│    routing table, workflow stage table, sources-of-truth pointers.  │
│    Hard cap: 200 lines.                                             │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 2. .claude/rules/                                                   │
│    Auto-loaded on every session. The "always know this" rules.      │
│      brain-hot.md           — 10 always-apply rules (A001-A010)     │
│      agent-pre-task-ritual  — what every sub-agent does on startup  │
│      lsp-first.md           — semantic = LSP, text = grep           │
│      sub-agent-workflow.md  — when to delegate vs inline            │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 3. .claude/agents/                                                  │
│    Specialized roles, each with a focused scope + tool allowlist.   │
│    Core: orchestrator, design-doc-writer, senior-tech-lead,         │
│          sprint-retro-author                                        │
│    Preset: e.g. go-hexagonal-engineer, frontend-fsd-engineer,       │
│            hexagonal-reviewer, vue-engineer, k8s-engineer           │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 4. .claude/skills/  (user-invocable: true)                          │
│    Slash-commands that drive the workflow:                          │
│      /next-task /promote /discover /assign /progress /archive       │
│      /retro /document /dispatch-parallel /design-review             │
│      /post-delegation-gate /deploy /changelog /index-refresh        │
│    Each declares a TOKEN BUDGET so it doesn't blow up the session.  │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 5. docs/setup/ + docs/playbooks/                                    │
│    The deep playbooks linked from CLAUDE.md / rules:                │
│      setup/      — workflow-master, lesson-trigger-map,             │
│                    index-discipline, integration-branch-strategy,   │
│                    deployment-workflow, delegation-checklist,       │
│                    zero-fix-task-template                           │
│      playbooks/  — contract-first, parallel-conflict-prevention,    │
│                    post-delegation-review (THE 6-gate playbook)     │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 6. docs/designs/_templates/  +  docs/spec/                          │
│    Templates that force quality:                                    │
│      designs/_templates/DESIGN_TEMPLATE     — ≥500-line zero-fix    │
│      designs/_templates/DESIGN_LIGHT        — for surgical sweeps   │
│      designs/_templates/DESIGN_REVIEW       — checklist for /design-review │
│      designs/_templates/BACKLOG_ENTRY       — backlog row format    │
│      spec/STATUS.md                         — single-pane truth     │
│      spec/backlog.md                        — all work, ever        │
│      spec/sprints/sprint-S<N>.md            — task table per sprint │
│      spec/retros/sprint-S<N>-tasks.md       — live mini-retros      │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 7. Memory (optional location)                                       │
│    BRAIN_PATH set?  → external Obsidian vault                       │
│    BRAIN_PATH blank?→ in-repo .claude/memory/                       │
│    Per-agent memory always in-repo: .claude/agent-memory/<agent>/   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## How a typical task flows through the plane

1. **User invokes `/next-task`** (skill, layer 4) — reads STATUS.md
   (layer 6), picks the next un-started task from the active sprint
   file (layer 6), confirms with user.
2. **Skill enforces design-first (A005, layer 2)** — if the task has no
   design doc, dispatches `design-doc-writer` (agent, layer 3) to
   author one to `docs/designs/sprint-S<N>/D<NNN>-<slug>.md` using
   `DESIGN_TEMPLATE.md` (layer 6).
3. **Skill dispatches the implementation agent** via the `Agent` tool
   (e.g. `go-hexagonal-engineer` from the go-hex preset). The agent
   executes the **pre-task ritual** (layer 2): reads CLAUDE.md +
   brain-hot.md + the preset-specific rule file (e.g.
   `hex-boundaries.md`) + the design doc.
4. **Agent codes TDD-first (A001)** — failing test, implementation,
   green test. Invokes `superpowers:test-driven-development`.
5. **Agent commits and returns.** Skill triggers
   `/post-delegation-gate` (layer 4) which walks the 6-gate playbook
   (layer 5). Gate 3 dispatches the preset-specific reviewer (e.g.
   `hexagonal-reviewer`).
6. **Once green, skill prompts for live mini-retro** (A009 / L036) —
   user appends a 6-field row to
   `docs/spec/retros/sprint-S<N>-tasks.md` (layer 6).
7. **Skill updates STATUS.md** and prompts for the next task.

At sprint close, `/retro` (layer 4) aggregates the mini-retros, audits
the backlog (A017), moves STATUS.md prose to STATUS-archive.md, and
writes `docs/spec/retros/sprint-S<N>.md`. Lessons that emerged become
new L### entries in the Brain (layer 7), cited from `brain-hot.md` if
always-applicable.

---

## Why every layer matters

| Skip this layer | What goes wrong |
|---|---|
| CLAUDE.md (1) | Each session re-discovers the project; routing chosen by guess |
| rules/ (2) | Sub-agents forget the rules; code drifts away from convention |
| agents/ (3) | Main session does all the work; context blows up at ~5 files |
| skills/ (4) | Workflow is "what feels right today"; design-first slips |
| playbooks (5) | 6-gate review becomes a vibe check, not a checklist |
| templates (6) | Design docs vary wildly in quality; review takes 3× longer |
| memory (7) | Lessons learned in sprint S03 are lost by S07 |

The point is not that any one layer is magic. The point is that
removing one collapses the next two.

---

## What is opinionated vs flexible

**Universal (in `core/`):**
- The seven-layer structure
- The 6-gate review
- The 4-layer parallel safety
- The design-first principle + ≥500-line zero-fix threshold
- The live mini-retro pattern
- The STATUS / backlog / sprints / retros source-of-truth convention
- LSP-first navigation
- The 10 always-apply A-rules

**Opinionated, opt-in (in `presets/`):**
- Hexagonal architecture for Go (go-hex)
- Feature-Sliced Design for Next.js (nextjs-fsd)
- Pinia thin-store + Composition API for Vue (vue-pinia)
- Helm + ArgoCD + GitOps for Kubernetes (k8s-helm)

**Project-local (you fill in):**
- A011+ rules in `brain-hot.md`'s "Project-specific rules" section
- Your sprint cadence in `STATUS.md`
- Your task ID prefix (set at install time via `TASK_ID_PREFIX`)
- Your specific lessons in `.claude/memory/` (or your Obsidian Brain)

---

## Verification (after install + customization)

```bash
# 1. No placeholders remain (installer should have caught this)
grep -rln '{{[A-Z_]\{2,\}}}' . || echo "clean"

# 2. Every agent has the mandatory pre-task-ritual reference
grep -L 'agent-pre-task-ritual' .claude/agents/*.md && echo "fail" || echo "ok"

# 3. Every skill has a token budget section
for s in .claude/skills/*/SKILL.md; do
  grep -q '## Token budget' "$s" || echo "missing budget: $s"
done

# 4. STATUS.md is filled in (not just the template)
grep -q '_replace with your first sprint_' docs/spec/STATUS.md && \
  echo "STATUS.md still has placeholder rows" || echo "ok"

# 5. Sprint files exist for the active sprint
ls docs/spec/sprints/sprint-S*.md || echo "no sprint files yet — run /promote"

# 6. Brain pointer is set
grep -q '{{BRAIN_PATH}}' .claude/rules/brain-hot.md && \
  echo "brain-hot.md still has placeholder" || echo "ok"
```

If all checks return "ok", the plane is wired and ready to drive work.
