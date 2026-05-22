# Multi-Repo Coordination — sharing the workflow across projects

> `/onboard` is repo-scoped — each `install.sh` lands the template in
> one project. But real orgs run multiple projects on the same
> control-plane. This doc covers the four scenarios the wizard handles
> + the troubleshooting checklist for shared `brain-hot.md` conflicts.
>
> Companion to `docs/setup/multi-team-deployment.md` (the canonical
> org-fork pattern); the file you're reading is the WIZARD's view of
> the same problem.

## Scenario 1 — Single repo, single team

The basic case. One project, one team, no sharing.

**Stage 0 detection:**
```json
{ "existing_install": false, "sibling_installs": [], "has_submodules": false }
```

**Wizard behavior:** runs the 8 stages as documented in
`core/.claude/skills/onboard/SKILL.md`. No special handling. Stage 4
drafts A011+ rules from this project's signals only.

**When to revisit:** if the team later spins up a second related
service, that second project's `/onboard` run will detect the first
one as a sibling (Scenario 2).

## Scenario 2 — Sibling repos at the same parent dir

A second project lives next to the first, both share workflow
conventions. Common layout:

```
~/code/
├── service-billing/        ← installed previously
│   └── .ai-workflows/manifest.json
└── service-orders/         ← /onboard running here
```

**Stage 0 detection:**
```json
{ "sibling_installs": ["../service-billing"], "has_submodules": false }
```

**Wizard behavior:** Stage 4 dispatch includes an extra `AskUserQuestion`:

> Inherit project-local A-rules from sibling `../service-billing`?
> This copies the ratified A011+ rules from the sibling's
> `brain-hot.md` into this project's drafts. You can still
> drop / edit any of them at Stage 5 ratification.

If **yes**:

1. Read `../service-billing/.claude/rules/brain-hot.md`, extract the
   `## Project-specific rules` section.
2. Merge into THIS project's Stage 4 candidates. De-dup by rule name
   (case-insensitive).
3. Tag merged candidates with `(inherited from service-billing)` in
   the evidence cite — operator sees the provenance at Stage 5.
4. Document the inheritance link in
   `docs/setup/sibling-repos.md` (a template lands in the target —
   one short paragraph naming the sibling + why the inheritance
   exists).

If **no**: proceed with own-signals-only drafting; the sibling
detection is recorded in `_onboard-staging/topology.json` but doesn't
affect the drafts.

**Inheritance is soft.** No symlink, no live sync. The sibling's
A-rules are copied **at the time of `/onboard`**; later changes in the
sibling don't propagate. To re-sync, run `/onboard rules` and accept
the inheritance offer again.

### When sibling inheritance is wrong

- Siblings use different stacks (e.g. one Go, one Python). Their
  A-rules are stack-coupled (e.g. "Use `errgroup` for goroutine
  cleanup") → drop, don't inherit.
- The sibling's rules are stale (last edit ≥ 6 months ago). Better to
  let the wizard's fresh mining re-derive them.
- Operator wants the new project to consciously diverge from the
  sibling's conventions.

## Scenario 3 — Org-wide convention sharing (≥ 3 siblings)

Sibling-by-sibling copying scales poorly past 2-3 projects. When
Stage 0 reports `≥ 3` sibling installs, the wizard recommends the
**org-fork pattern** instead.

**Stage 0 detection:**
```json
{ "sibling_installs": ["../svc-a", "../svc-b", "../svc-c"], ... }
```

**Wizard behavior:** Stage 4 dispatch surfaces:

> 3 sibling installs detected. At this scale, sibling-by-sibling
> inheritance becomes a copy-paste mess. Consider the org-fork
> pattern instead — fork the template once for your org, add
> `org-rules.md` for team-shared A-rules, install all projects from
> the fork. See `docs/setup/multi-team-deployment.md`.
>
> Continue with sibling inheritance anyway? (Y/n, default n)

If **n** (default): the wizard drops the inheritance offer and
proceeds with own-signals-only. The operator can do the org fork on
their schedule.

If **Y**: proceeds as Scenario 2 — merge ratified A-rules from each
sibling. Note: rules from multiple siblings may contradict. The
drafter de-dups by name + surfaces conflicting bodies in the Stage 5
ratification UI so the operator picks the winning version.

**The migration path** (org fork after sibling-copy adoption):

1. Fork AI-Workflows to `<org>/ai-workflows-internal`.
2. Promote the most-common A011+ rules across siblings into
   `core/.claude/rules/org-rules.md.tmpl` in the fork.
3. Re-install each project from the fork: `<org>/ai-workflows-internal/install.sh
   <project> --preset <...> --force`. The soft-merge preserves
   project customizations; the fork's `org-rules.md` lands beside
   each project's `brain-hot.md`.
4. Drop the (now redundant) inherited entries from each project's
   `brain-hot.md` A011+ section.

Full mechanic: `docs/setup/multi-team-deployment.md`.

## Scenario 4 — Meta-repo with submodules

A meta-repo coordinates multiple submodule services. The meta owns
the control plane (`STATUS.md`, `backlog.md`, retros); each submodule
ships its own area-scoped `CLAUDE.md` + its own code.

**Stage 0 detection:**
```json
{ "type": "meta-repo", "has_submodules": true, "areas": ["svc-a", "svc-b"] }
```

**Wizard behavior:** Stage 4 dispatch offers TWO paths:

1. **Onboard the meta-repo first.** The wizard runs all 8 stages
   against the meta. `CLAUDE.md` lives at meta root; per-area
   `CLAUDE.md` files live INSIDE each submodule (the wizard writes
   them into the submodule's working tree, but does NOT commit to the
   submodule — the operator decides when to commit + push the
   submodule's CLAUDE.md).
2. **Onboard each submodule independently.** After (1) completes,
   the operator can `cd` into each submodule and run `/onboard` again
   there. Each submodule run detects the meta as a parent (special
   case of Scenario 2) and offers to inherit from the meta's
   `brain-hot.md`.

The aggegator-style pattern (referenced in this template's source
notes): treat the meta-repo as the sprint hub + each submodule as a
service that pulls rules from the hub. The meta's `brain-hot.md` is
canonical; submodules inherit, never the reverse.

**Submodule onboarding tips:**

- Always run `git submodule update --init` BEFORE submodule onboard,
  so the submodule's working tree has actual code to scan.
- The submodule's `/onboard` will detect the parent as a sibling.
  Accept the inheritance offer to get the meta's A-rules.
- Don't draft a `STATUS.md` inside a submodule — it lives in the
  meta-repo only. Stage 6 of the submodule onboard knows to skip
  STATUS / backlog creation if a parent install is detected.

## Shared `brain-hot.md` — merge-conflict troubleshooting

The most common multi-repo failure mode: two teams edit a shared
`brain-hot.md` concurrently, both push, merge conflict.

### Rule 1: one team owns the canonical `brain-hot.md`

Pick a canonical owner. For sibling-inherit setups → the senior
sibling. For org-fork → the fork repo's maintainer. For meta-repo →
the meta-repo team.

### Rule 2: propose changes via PR, never direct-commit

Even small edits to the canonical `brain-hot.md` go through PR. The
owner reviews + merges + tags a version. Downstream installs pull
the new version via `install.sh upgrade` or `/onboard refresh`.

### Rule 3: never both edit + push concurrently

If you must edit locally, branch first:

```bash
git -C <canonical-repo> checkout -b chore/brain-hot-add-A015
# ... edit ...
git -C <canonical-repo> commit -am "chore: add A015 (postgres advisory locks)"
git -C <canonical-repo> push -u origin chore/brain-hot-add-A015
# open PR — let the owner merge
```

### Rule 4: if a merge conflict still happens

```bash
# In the conflicted branch:
git -C <canonical-repo> diff --name-only --diff-filter=U
# Open .claude/rules/brain-hot.md in your editor
# RESOLVE BY KEEPING BOTH RULES, renumbering as needed
# Never delete a rule the other team added without asking
git -C <canonical-repo> add .claude/rules/brain-hot.md
git -C <canonical-repo> commit
```

A-rules are accretive. Two teams adding different rules → keep both.
Never resolve "ours / theirs" without reading both contributions.

### Rule 5: re-onboard downstream after canonical changes

When the canonical `brain-hot.md` changes meaningfully, run
`/onboard refresh` in each downstream project to pull the new rules
into local drafts. Operator ratifies again (the refresh wizard shows
DELTA only).

## Decision tree

```
Stage 0 reports …                               → Use scenario …
─────────────────────────────────────────────────────────────────
sibling_installs = []                           → Scenario 1
sibling_installs = [1 item]                     → Scenario 2 (offer inherit)
sibling_installs = [2+ items]                   → Scenario 2 + warning
sibling_installs = [3+ items]                   → Scenario 3 (recommend org-fork)
has_submodules = true                           → Scenario 4 (offer meta-first)
sibling_installs = [...] AND has_submodules     → Scenario 4 wins; sibling
                                                  inheritance is per-submodule, not meta-level
```

## See also

- `core/.claude/skills/onboard/SKILL.md` — wizard's multi-repo
  coordination block (Stage 4 dispatch)
- `core/docs/setup/multi-team-deployment.md` — canonical org-fork
  pattern
- `core/docs/setup/onboarding-guide.md` — human companion (multi-repo
  decision tree section)
- `references/repo-topology-detection.md` — how Stage 0 surfaces the
  signals this doc branches on
