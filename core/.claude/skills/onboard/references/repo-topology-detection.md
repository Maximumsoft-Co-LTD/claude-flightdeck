# Repo Topology Detection — `detect-topology.sh` deep-dive

> Companion to `/onboard` Stage 0. The script emits a single JSON blob;
> this doc explains what each field means, how it's computed, and how
> downstream stages branch on it. Read on demand when Stage 0 returns
> something surprising.
>
> Source: `core/.claude/skills/onboard/scripts/detect-topology.sh`.

## The 7 `type` values

The `type` field is the headline. Everything downstream gates on it.

| `type` | When it fires | What changes downstream |
|---|---|---|
| `single-go` | Exactly one language detected (`go`), no per-area manifests at depth 1 | Stage 1 scan focuses on `cmd/` + `internal/` (or whatever layout exists); Stage 4 drafts ONE root `CLAUDE.md`, no per-area files; the code-style sampler seeds `code-style.md` from the Go files |
| `single-node` | Exactly one language (`typescript` or `javascript`), no per-area manifests | Stage 1 looks for `src/` + `app/`/`pages/`; `frameworks` (next/vue/react) tell the code-style sampler which UI files to read |
| `single-python` | Exactly one language (`python`), no per-area manifests | Stage 1 looks for `<pkg>/` + `tests/`; code-style sampler seeds `code-style.md` from the Python files |
| `single-other` | Single-language but not Go/Node/Python (`rust`, `java`, `ruby`, …) OR multi-language with no clear area dirs | Stage 1 falls back to generic structural scan; code-style sampler still derives conventions from whatever files exist |
| `monorepo` | ≥2 top-level dirs each carrying their own manifest, no `.gitmodules` | Stage 1 walks per-area; Stage 4 drafts ONE root `CLAUDE.md` PLUS one per-area `CLAUDE.md`; the code-style sampler runs per area so `code-style.md` has a section each |
| `meta-repo` | ≥2 areas detected AND `.gitmodules` present | Same per-area drafting as `monorepo`, plus offers Scenario 4 from `multi-repo-coordination.md` (onboard meta first, optionally onboard each submodule with inheritance) |
| `empty` | No languages AND no areas detected | Wizard warns + suggests committing the initial codebase before continuing. Stage 3 mining will return zero signals; Stage 5 ratification will be a no-op |

## Detection heuristics

### Language probes (depth 1 + targeted depth 3)

The script checks top-level manifest files first, then a bounded
`find` at depth ≤ 3 to catch monorepo cases where the manifest lives
under `backend/go.mod` rather than root `go.mod`:

```bash
[[ -f "$TARGET/go.mod" ]] && LANGS+=("go")
# else, if any go.mod within depth 3 (excluding vendor/), still "go"
```

The same pattern applies to `package.json` (TypeScript vs JavaScript
disambiguated by the presence of `tsconfig.json`), `pyproject.toml` /
`setup.py` / `requirements.txt` (Python), `Cargo.toml` (Rust),
`pom.xml` / `build.gradle*` (Java), `Gemfile` (Ruby).

`node_modules/`, `vendor/`, `.git/`, `target/`, `dist/`, `build/`,
`venv/`, `.venv/`, `__pycache__/` are skipped explicitly — they pollute
detection otherwise.

### Area probes (depth 1 only)

An "area" is a top-level dir holding a manifest indicating its own
build surface:

```bash
go.mod | package.json | pyproject.toml | Cargo.toml
| Chart.yaml | values.yaml | Makefile | Dockerfile
```

A Makefile or Dockerfile alone is enough to count — useful for `k8s/`
dirs that ship YAML + a Makefile but no language manifest.

## Edge cases

### Mixed-language repo at root (no clear primary)

Example: Go backend in `cmd/` + `internal/`, plus Python scripts in
`scripts/` at root, both compiled from root.

```
repo/
├── go.mod
├── requirements.txt
├── cmd/
└── scripts/
```

`N_LANGS = 2`, `N_AREAS = 0` → falls through to `single-other`. Stage 1
will surface BOTH languages, but Stage 4 won't draft a per-area
`CLAUDE.md` for `scripts/`. Operator decision: at Stage 5, propose an
A-rule like *"Python tooling lives in `scripts/`, Go service in
`cmd/`"* and explicitly mark `scripts/` for a future manual
`CLAUDE.md`.

### Monorepo where one area has no manifest

Example:

```
repo/
├── backend/go.mod
├── frontend/package.json
└── docs/         ← no manifest
```

`docs/` is NOT counted as an area (no manifest). Result: `monorepo`
with `areas: [backend, frontend]`. Stage 4 drafts per-area
`CLAUDE.md` for backend + frontend only. `docs/` documentation
conventions land in `team-conventions.md` instead, since there's no
build surface to describe.

### Detached submodules

`.gitmodules` lists submodules but `git submodule status` shows them
uninitialized:

```
-abc123 path/to/submodule
```

The script detects `.gitmodules` and flags `has_submodules: true`
regardless of init state. Stage 4 inheritance offers will still
appear — the operator can accept (and the wizard will read whatever's
checked out) or defer until after `git submodule update --init`.

### Empty git repo (initialized, no commits)

`git init` ran, no commits yet:

```bash
git_repo: true
git_commits: 0
```

Stage 3 mining will exit silently (zero signals). The wizard warns at
Stage 0:

```
git_commits: 0 — Stage 3 will return zero signals.
Recommend: make 5-10 commits of real work, then re-run `/onboard rules`.
```

Operator can still finish Stages 1-2 + 4-7 — they just get no
historical A-rule candidates.

### Bare clone (no `.git/` dir)

`git rev-parse --git-dir` succeeds via the `GIT_DIR` env var pointing
elsewhere. The script handles this: `git_repo: true`, `git_commits`
populated. Rare in onboarding (bare clones aren't working trees), but
won't hard-fail.

## Framework detection + preset recommendation

The core engineers are architecture-agnostic, so language/framework
detection drives the **code-style sampler**, not an architecture choice.

| Detected | Effect |
|---|---|
| `"next"` / `"vue"` / `"react"` in any `package.json` | Added to `frameworks` → tells Stage 3-D which UI files to sample |
| Area named `k8s`/`charts`/`deploy`, OR `Chart.yaml` at root | Recommends the `k8s-helm` preset (the only shipped preset) |

The `presets_recommended` array only ever contains `k8s-helm`. If it's
recommended but `existing_install` shows it's NOT installed, Stage 0
surfaces a "missing preset" note and offers to re-run `install.sh
--preset k8s-helm`. (Opinionated backend/frontend architecture presets
are no longer shipped — author one as a custom preset if your team wants
it; see `docs/adding-new-preset.md`.)

## Sibling-install detection

The script looks **one directory up** for siblings carrying
`.ai-workflows/manifest.json`:

```bash
PARENT="$(dirname "$TARGET")"
for sib in "$PARENT"/*/; do
  [[ -f "$sib.ai-workflows/manifest.json" ]] && SIBLINGS+=("../$sib")
done
```

One level only — by design, not a depth bug. Most real org layouts
either (a) share a single parent (`~/code/service-a`, `~/code/service-b`)
or (b) use the org-fork pattern from `docs/setup/multi-team-deployment.md`
where the shared rules live in the fork itself.

If the operator's layout is unusual (e.g. all services under
`~/code/org/services/<svc>`), the wizard prompts at Stage 4 to
manually supply the sibling path.

## Re-running detection

The script is idempotent — no cache, no state. Re-run any time:

```bash
.claude/skills/onboard/scripts/detect-topology.sh "$PROJECT_DIR" | jq .
```

If the topology changes mid-onboard (e.g. operator adds a new top-level
service dir between Stage 0 and Stage 4), abort the wizard, re-run
Stage 0, decide whether to start over or `/onboard refresh` against
the new shape.

## Limitations

- **No Bazel detection.** Bazel monorepos (`BUILD` / `WORKSPACE` files,
  no per-area language manifests) are classified as `single-other` or
  `empty` depending on whether any language files are at root. Adding
  Bazel detection requires probing `BUILD` files at depth ≤ 3.
- **No nested-workspace recursion.** Yarn / pnpm / npm workspaces with
  `packages/*` won't surface each package as a separate "area" — the
  script only walks depth 1.
- **No `.git/modules/` crawl.** Submodule detection is `.gitmodules`
  presence-only. If `.gitmodules` is missing but `.git/modules/`
  has content, the script reports `has_submodules: false`.
- **No remote-only detection.** Sibling-install discovery is
  filesystem-local; sibling installs that live on a different machine
  / cluster won't appear.

If any of these limitations bite, file an enhancement against the
script. In the meantime, the wizard's Stage 4 dispatch prompt accepts
operator-supplied overrides for area lists, sibling paths, and preset
selection.

## See also

- `core/.claude/skills/onboard/scripts/detect-topology.sh` — the script
- `core/.claude/skills/onboard/SKILL.md` — Stage 0 invocation
- `references/multi-repo-coordination.md` — sibling + meta-repo handling
- `core/docs/setup/multi-team-deployment.md` — org-fork pattern
