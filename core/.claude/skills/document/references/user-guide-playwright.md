# User Guide via Playwright — Screenshot-Driven Docs

> Loaded by `/document user-guide` (or `/document <page>`) when the
> output is a human-facing walkthrough of the UI. Covers: page-tree
> discovery, screenshot conventions, multi-locale capture, dark mode,
> accessibility annotations.

## When this reference applies

- Generating user-facing onboarding / how-to docs.
- Refreshing screenshots after a UI change.
- Multi-locale or multi-theme product where the doc must reflect each
  variant.

## Why Playwright (not curl)

SPAs return an empty HTML shell to curl. The doc needs the *rendered*
UI, which requires JS execution + asset load + hydration. Playwright
drives a real Chromium / Firefox / WebKit and captures the actual
visible state.

```
curl https://app.example.com/dashboard
→ <html><head>...</head><body><div id="root"></div></body></html>
  (empty — useless for docs)

playwright navigate + screenshot
→ a 1440x900 PNG of the actual dashboard with data populated
```

## Page-tree discovery

Discover all routes the app exposes BEFORE deciding what to document.

### Option A — read the route table (Next.js, React Router)

```bash
# Next.js App Router: routes are derived from src/app/**/page.tsx
find src/app -name 'page.tsx' -not -path '*/_*' | \
  sed 's|src/app||; s|/page.tsx||; s|^$|/|' | sort -u
```

### Option B — sitemap

```bash
curl -s https://app.example.com/sitemap.xml | \
  xmllint --xpath '//*[local-name()="loc"]/text()' - | \
  sort -u
```

### Option C — Playwright crawler (locator API)

Use Playwright's `locator.evaluateAll` (or `locator.all`) to gather
internal links from the rendered page. Save the deduplicated path set
to `scripts/route-manifest.json`.

The discovered routes feed Step 2 of `/document`. Diff against
existing `docs/user-guide/*.md` to find documented vs undocumented
routes.

## Screenshot conventions

### Filenames

```
docs/user-guide/_shots/<page>-<locale>-<theme>-<width>.png

# Examples
docs/user-guide/_shots/dashboard-en-light-1440.png
docs/user-guide/_shots/dashboard-en-dark-1440.png
docs/user-guide/_shots/dashboard-th-light-1440.png
docs/user-guide/_shots/dashboard-en-light-360.png
```

Predictable filenames mean refreshing is `rm docs/user-guide/_shots/*
&& <re-capture script>` — no orphan files.

### Resolutions

| Width | Use case |
|---|---|
| 1440 | Primary desktop screenshot (most readers) |
| 1024 | Tablet / narrow desktop |
| 768 | Tablet portrait |
| 360 | Phone |

Capture 1440 + 360 at minimum. Add 1024 / 768 only when the page has
meaningfully different layouts at those widths.

### Alt text

Every embedded screenshot in the doc carries descriptive alt text —
not the filename. The alt text is also the doc's a11y story.

```markdown
![Dashboard showing the welcome panel, recent activity feed, and three
metric tiles (Active Users, Revenue, Churn).](_shots/dashboard-en-light-1440.png)
```

NOT:

```markdown
![dashboard-en-light-1440](_shots/dashboard-en-light-1440.png)
```

## Capture script — multi-page, multi-locale, multi-theme

Use Playwright's `newContext` with `viewport`, `locale`, and
`colorScheme` parameters to spin one browser context per locale ×
theme × width combination. Iterate the page list inside each context,
call `page.goto(route)`, `page.waitForLoadState('networkidle')`, then
`page.screenshot({ path })` per the filename convention above.

Authentication once per context is enough — log in at the start of
the context with `page.fill` + `page.click`, then visit every page in
the manifest before closing the context.

Skeleton:

```
PAGES   = [{route, name}, ...]
LOCALES = ['en', 'th', ...]
THEMES  = ['light', 'dark']
WIDTHS  = [1440, 360]

for each (locale × theme × width):
    context = browser.newContext({ viewport, locale, colorScheme: theme })
    page    = context.newPage()
    login(page)
    for each PAGE:
        page.goto(PAGE.route)
        page.waitForLoadState('networkidle')
        page.screenshot({ path: `${SHOT_DIR}/${PAGE.name}-${locale}-${theme}-${width}.png` })
    context.close()
```

A reference script ships at `scripts/capture-user-guide.js` once you
fill in the placeholder values; commit it so the doc-refresh is
reproducible.

## Dark mode

Most apps detect dark mode via `prefers-color-scheme: dark`. Playwright
sets it via `colorScheme: 'dark'` in `newContext()`. If your app reads
a stored theme from `localStorage` instead, inject it via
`context.addInitScript` BEFORE navigation so the storage value is
present at first paint.

Verify by looking at the screenshot — many apps half-respect the
preference (component A is dark, component B is light = a real bug
worth filing).

## Multi-locale capture

Caveats:

- **The locale must be reachable.** If switching locale requires
  clicking a menu, script that interaction.
- **Time-zone matters.** Capture with a consistent TZ so dates / times
  read the same across locales (set `timezoneId: 'UTC'` in
  `newContext` unless the app is TZ-sensitive on purpose).
- **RTL languages** (Arabic, Hebrew) reverse layouts — capture them
  too if supported; review carefully.

## Accessibility annotations

Embed an a11y summary per page using `@axe-core/playwright`. Run the
axe analyzer after each navigation, save the JSON sidecar next to the
screenshot, and surface a one-line a11y status in the rendered doc:

```markdown
![Dashboard ...](_shots/dashboard-en-light-1440.png)

> a11y: 0 critical, 0 serious violations (axe-core 4.x).
```

Any `serious` / `critical` violations are findings — file them to the
sprint backlog rather than ship the doc with a known a11y problem.

## Page-content extraction

For the prose (not just screenshots), pull live text from the
rendered page using Playwright locators (e.g. `page.locator('h1')`,
`page.locator('main p').first()`). Use the extracted text as the seed
for the Markdown body — much less drift than writing it from
imagination.

## Manifest entry

```json
{
  "scope": "user-guide",
  "source": "https://app.example.com",
  "outputs": [
    {"path": "docs/user-guide/dashboard.md", "tool": "playwright@1.x"},
    {"path": "docs/user-guide/_shots/dashboard-en-light-1440.png", "tool": "playwright@1.x"}
  ],
  "generated_at": "2026-05-22T10:30:00Z",
  "app_sha": "<git SHA of the frontend repo at capture time>"
}
```

## Common pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| `curl` instead of browser | Screenshot is blank or shows the loader | Always Playwright for SPA |
| `waitForLoadState('load')` too early | Skeleton screens in screenshots | Use `'networkidle'` + an explicit `waitForSelector` for the main content |
| Login leaks into screenshot | Email / password visible in the shot | Use a dedicated `demo@` account; mask PII via a locator that swaps text before capture |
| Time-sensitive content drifts | Doc re-captures show different relative times ("3m ago" vs "5m ago") | Mock the clock OR avoid capturing the relative-time area |
| Different OS = different fonts | Doc reviewer's screenshot differs from CI's | Pin to a single capture environment (Docker image) |
| Animations mid-screenshot | Blurry / mid-transition shots | Disable transitions via an injected stylesheet before capture |
| `fullPage: true` on infinite scroll | 50MB PNG that no one wants to render | Scope to viewport; use multiple shots for long pages |

## Related

- `manifest-format.md` — the index manifest pinned by capture
- `api-openapi.md` / `api-proto.md` — sibling references for contract
  docs
- `../../review/SKILL.md` — uses the same Playwright capture
  machinery for the design-fidelity gate (`/review design`)
