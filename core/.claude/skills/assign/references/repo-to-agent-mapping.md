# Repo / Component → Subagent Mapping

> Loaded by `/assign` Step 1 when picking the `subagent_type` for the
> dispatch. The right agent gets the right preset rules
> auto-loaded (via the pre-task ritual) and matches the repo's
> architectural conventions.

## How to read this file

Each preset (the install-time `--preset` flag in this template) ships
a set of project-local agents under `.claude/agents/`. The mapping
below shows the canonical "what agent owns what work" for the most
common presets in this template, plus a fallback for unknown stacks.

## Concrete mappings

### Preset: `go-hex` (Go services using hexagonal architecture)

| Work class | `subagent_type` |
|---|---|
| Implement a use-case (`internal/app/<feature>`) | `go-hexagonal-engineer` |
| Implement a domain entity (`internal/domain/<entity>`) | `go-hexagonal-engineer` |
| Implement an HTTP adapter (`internal/adapter/http/`) | `go-hexagonal-engineer` |
| Implement a repo adapter (`internal/adapter/repo/postgres/`) | `go-hexagonal-engineer` |
| Add / change a Kafka producer / consumer | `kafka-pipeline-engineer` |
| Add tracing / metrics / log fields | `observability-engineer` |
| Cross-cutting review (Gate 3 — boundary) | `hexagonal-reviewer` |
| Multi-service architectural decision | `senior-tech-lead` |
| ≥500-line design doc authoring | `design-doc-writer` |

### Preset: `nextjs-fsd` (Next.js App Router with Feature-Sliced Design)

| Work class | `subagent_type` |
|---|---|
| New page (`app/<route>/page.tsx`) | `frontend-fsd-engineer` |
| New feature (`src/features/<feature>/`) | `frontend-fsd-engineer` |
| New widget (`src/widgets/<widget>/`) | `frontend-fsd-engineer` |
| New entity model (`src/entities/<entity>/`) | `frontend-fsd-engineer` |
| Shared UI primitive (`src/shared/ui/`) | `frontend-fsd-engineer` |
| Cross-route architectural decision | `senior-tech-lead` |
| Post-FE-sprint design fidelity gate | Invoke `/design-review` (skill, not agent) |
| ≥500-line design doc authoring | `design-doc-writer` |

### Preset: `vue-pinia` (Vue 3 + Pinia)

| Work class | `subagent_type` |
|---|---|
| New view / page (`src/views/<view>.vue`) | `vue-engineer` |
| New composable (`src/composables/`) | `vue-engineer` |
| New store (`src/stores/`) | `vue-engineer` |
| Shared component (`src/components/`) | `vue-engineer` |
| Cross-view architectural decision | `senior-tech-lead` |
| ≥500-line design doc authoring | `design-doc-writer` |

### Preset: `k8s-helm` (Kubernetes manifests / Helm charts)

| Work class | `subagent_type` |
|---|---|
| New Helm chart template | `k8s-engineer` |
| New Kustomization overlay | `k8s-engineer` |
| ArgoCD Application / ApplicationSet | `k8s-engineer` |
| Flux Kustomization / HelmRelease | `k8s-engineer` |
| RBAC / NetworkPolicy / PSP | `k8s-engineer` |
| Cross-cluster / multi-env architectural decision | `senior-tech-lead` |

### Built-in fallbacks (no preset matches)

| Work class | `subagent_type` |
|---|---|
| Multi-step task that doesn't fit a specialist | `general-purpose` |
| Read-only exploration / file search | `Explore` |
| Greenfield feature design + blueprint | `feature-dev:code-architect` |
| Deep-trace an existing feature code path | `feature-dev:code-explorer` |
| Generic code review | `feature-dev:code-reviewer` |

## Reviewer mappings (Gate 3 of post-delegation review)

The boundary / architectural reviewer is preset-specific:

| Preset | Reviewer |
|---|---|
| `go-hex` | `hexagonal-reviewer` |
| `nextjs-fsd` | `senior-tech-lead` (FSD-layer rules are checked) |
| `vue-pinia` | `senior-tech-lead` (composition / store boundary) |
| `k8s-helm` | `senior-tech-lead` (manifest hygiene + RBAC) |
| no preset | `senior-tech-lead` (generalist review) |

## Mixed-stack tasks

A task that spans frontend + backend (e.g. "implement X endpoint AND
its UI consumer") is split into TWO sub-tasks BEFORE dispatch:

- Sub-task A (BE) → backend engineer (per preset)
- Sub-task B (FE) → frontend engineer (per preset)

Contract change goes in a third PR that lands FIRST (see
`/dispatch-parallel` Conflict Radar Layer 3). Never dispatch a single
agent to write both sides of a contract — the contract becomes the
implicit + non-versioned glue and you'll regret it.

## How to add a new preset mapping

1. Add a row above with the work classes the preset's agents own.
2. Confirm the preset ships matching agent files in
   `.claude/agents/<agent-name>.md`.
3. Update `/assign` Step 1 if the parsing changes (which it usually
   doesn't — the mapping is data, not code).

## Anti-patterns

- ❌ Dispatching `general-purpose` for a preset-covered task. The
  preset agent has the right rules pre-loaded; `general-purpose`
  starts cold.
- ❌ Picking the reviewer agent as the implementer. Reviewers are
  read-only by design; their context is tuned for finding problems,
  not creating code.
- ❌ Using `Explore` to write code. `Explore` is read-only — it
  cannot commit.

## See also

- `dispatch-prompt-template.md` — the prompt block this mapping
  populates
- `../../../rules/sub-agent-workflow.md` §2 — full subagent inventory
  (the source of truth for what agents exist)
- `/dispatch-parallel` — when dispatching multiple agents at once,
  this mapping picks each one
