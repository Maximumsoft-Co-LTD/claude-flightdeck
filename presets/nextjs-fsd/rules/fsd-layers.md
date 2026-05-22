# FSD Layers (non-negotiable)

Auto-loaded for every session in this repo. Applies to the {{PROJECT_NAME}} Next.js app. Enforced by `eslint-plugin-boundaries` (`npm run lint`) + the frontend reviewer on every PR.

## Layer graph (allowed import direction)

```
app/       ← Next.js routes, layouts, providers, route handlers
  └─→ widgets/      composite UI blocks (compose features + entities)
        └─→ features/    vertical slices { ui, model, api, lib }
              └─→ entities/   domain entities (UI + types)
                    └─→ shared/    ui, api, lib, config, hooks
```

**Arrows go down only. Never up. Never sideways across siblings at the same level.**

## Forbidden imports (and why)

| Import | Reason | Failure mode if violated |
|---|---|---|
| `shared/*` → anything above | Shared must be the foundation, depended on by all | Cycles; can't extract `shared/` as a package |
| `entities/X` → `entities/Y` | Entities are independent atoms | Hidden coupling; an entity rename breaks unrelated entities |
| `features/X` → `features/Y` | Features are vertical slices; cross-feature wiring happens in widgets / app | Same as above; impossible to dead-code-eliminate one feature |
| `features/*` → `widgets/*` or `app/*` | Higher layers compose lower ones, not the reverse | Inverted dependency; can't reason about a feature in isolation |
| `widgets/*` → `app/*` | Same | Same |
| `entities/*` → `features/*` | Entities are below features | Same |

## Layer charter

| Layer | What goes here | What does NOT |
|---|---|---|
| `app/` | Next.js routes (`page.tsx`, `layout.tsx`), route handlers (`api/`), providers, global error boundary, middleware | UI primitives; feature logic |
| `widgets/` | A composite UI block that wires together multiple features and/or entities (e.g. `OrderDashboard`, `CustomerSidebar`) | Single-feature UI; raw data fetching |
| `features/` | A vertical slice — one user-visible behavior — with its own `{ ui, model, api, lib }` (e.g. `auth-2fa`, `order-create`) | UI shared across features; cross-feature composition |
| `entities/` | A domain entity: types + the minimal UI to render one (e.g. `<CustomerCard />`, `Customer` type, query keys) | Mutation logic; multi-entity views |
| `shared/` | `ui` (design-system primitives), `api` (apiGet / apiPost), `lib` (cn, format), `config`, `hooks`, `i18n` infra | Anything domain-specific; anything that imports from a higher layer |

## Mechanisms

1. **`eslint-plugin-boundaries`.** Configured in the project's eslint config. `boundaries/element-types` declares the allowed graph. `npm run lint` fails the build on a violation.

   ```jsonc
   {
     "settings": {
       "boundaries/elements": [
         { "type": "app",      "pattern": "src/app/**" },
         { "type": "widgets",  "pattern": "src/widgets/**" },
         { "type": "features", "pattern": "src/features/**" },
         { "type": "entities", "pattern": "src/entities/**" },
         { "type": "shared",   "pattern": "src/shared/**" }
       ]
     },
     "rules": {
       "boundaries/element-types": ["error", {
         "default": "disallow",
         "rules": [
           { "from": "app",      "allow": ["widgets", "features", "entities", "shared"] },
           { "from": "widgets",  "allow": ["features", "entities", "shared"] },
           { "from": "features", "allow": ["entities", "shared"] },
           { "from": "entities", "allow": ["shared"] },
           { "from": "shared",   "allow": ["shared"] }
         ]
       }]
     }
   }
   ```

2. **CI gate.** `npm run lint` runs in CI on every PR. Failures block merge.

3. **Reviewer agent.** The architectural reviewer dispatched in gate 3 of the 6-gate post-delegation review (`docs/playbooks/post-delegation-review.md`) reads this rule and flags violations the linter missed.

## Always-on companion rules

These apply to every component in this app, alongside the layer rule:

- **Semantic tokens only.** Use CSS custom properties (e.g. `--bg`, `--fg`, `--bd`, `--accent`) — never raw hex / Tailwind palette numbers in components. The palette lives in the design-system layer; component code never names a color.
- **4-state render per data view.** Every page / widget that fetches data renders `loading / error / empty / success` explicitly. An `if (!data) return null` swallows two states (error and empty) into one — wrong.
- **No hardcoded user-facing strings.** Every visible string goes through next-intl `t()`. Keys live in `i18n/messages/<locale>.json`; every locale file gets every key.
- **`null`-safe list coalescing.** Backends often return `null` for empty lists. Always `?? []` before `.map`.

## When you need to share

| Situation | Where it goes |
|---|---|
| A design-system primitive (Button, Input, Modal) | `src/shared/ui/` |
| An HTTP helper (apiGet / apiPost) | `src/shared/api/` |
| A pure utility (cn, formatDate) | `src/shared/lib/` |
| A type used in multiple features | `src/entities/<entity>/` (with the entity that owns it) |
| Composition of two features into one screen | A new widget in `src/widgets/<widget>/` |
| Composition of widgets into a route | A new page in `src/app/<route>/page.tsx` |

**Never** add a same-layer cross-import. **Never** lift a feature's internal types into `shared/` to dodge the layer rule — refactor the entity or compose in a widget instead.

## Why so strict

Same reason as the backend layer rule. Two failure classes that flat / convention-only layouts suffer from, both eliminated by structure:

1. **Cross-feature coupling.** Feature A imports a hook from feature B, which is later deleted in a "cleanup" sprint. Feature A breaks silently; the build still passes because TypeScript thinks the path is fine until runtime. Hard layer separation makes this impossible.
2. **Design-system drift.** Components reach across to a sibling feature's "shared" component, fork it, tweak it. Now there are two `Button` components, one ages, both diverge. A single `shared/ui/` with a layer rule that forbids reaching past it kills the drift.

## Related

- `.claude/agents/frontend-fsd-engineer.md` — engineer that follows this rule
- `.claude/skills/playwright-install/SKILL.md` — e2e setup
- `.claude/rules/sub-agent-workflow.md` — gate 3 of the 6-gate review
- `.claude/rules/brain-hot.md` — references this rule
