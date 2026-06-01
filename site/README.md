# `site/` — the claude-flightdeck usage & workflow site

A small, **dependency-free static site** that communicates what this template
is and how its workflow operates — published via GitHub Pages.

> **Why it exists (CLAUDE.md rule 7):** onboarding people to the workflow with
> prose alone is slow. This site is the visual, scannable explainer (hero,
> animated flight-path, use-case "mission profiles", agents/skills roster).
> Crucially, the **data-driven pages are GENERATED from the repo's own sources
> of truth**, so they cannot drift from the template as it changes.
>
> This site lives only in the template repo — `install.sh` copies `core/` +
> `presets/`, never `site/`, so nothing here ships into a target project.

## What's generated from what

| Page | Source of truth |
|---|---|
| `changelog.html` | `CHANGELOG.md` |
| `research.html` | `docs/research/INDEX.md` (incl. the shipped scoreboard) |
| `agents.html` | `core/.claude/agents/*.md` + `presets/*/agents/*.md` (frontmatter) |
| `skills.html` | `core/.claude/skills/*/SKILL.md` + `presets/*/skills/*` (frontmatter) |
| `index.html` | `content/index.html.part` (curated) + live counts |
| `workflow.html` | `content/workflow.html.part` (curated) |

Stat counters (agents / skills / rules / shipped upgrades) are computed at
build time, so they're always accurate.

## Layout

```
site/
├── generate.py          # the generator — zero third-party deps, any python3
├── assets/
│   ├── style.css        # Tesla-inspired minimal theme
│   └── deck.js          # scroll-reveal, count-up, nav, mobile menu (vanilla)
├── content/
│   ├── _shell.html      # the page shell (head, nav, footer) — token-replaced
│   ├── index.html.part  # curated hero + use-cases + flight-path
│   └── workflow.html.part
└── dist/                # GENERATED output (gitignored) — what Pages serves
```

## Build & preview locally

```bash
python3 site/generate.py            # → site/dist/*.html
( cd site/dist && python3 -m http.server 8099 )
# open http://localhost:8099/index.html
```

No `pip install`, no Node, no build toolchain — just `python3`.

## How it's published (GitHub Pages via Actions)

`.github/workflows/pages.yml` runs `generate.py` on every push to `main` that
touches `site/**`, `CHANGELOG.md`, `docs/research/INDEX.md`, or the core
agents/skills, then deploys `site/dist/` to Pages.

**One-time repo setting:** Settings → Pages → *Build and deployment* →
**Source: GitHub Actions**. (Done once by a repo admin; the workflow handles
the rest. Live URL: `https://maximumsoft-co-ltd.github.io/claude-flightdeck/`.)

## Editing

- **Curated copy** (hero, use-cases, the workflow explainer): edit
  `content/index.html.part` / `content/workflow.html.part`. Tokens like
  `__N_SKILLS__`, `__GH__` are replaced by the generator.
- **Look & feel:** `assets/style.css` (one cohesive theme) + `assets/deck.js`.
- **Data pages** (agents/skills/research/changelog): you don't edit these —
  change the underlying source file and rebuild.

> The Pages workflow is committed, executable CI config — treat changes to it
> as a security-review surface (see
> [`../core/docs/setup/agent-config-security.md`](../core/docs/setup/agent-config-security.md)).
