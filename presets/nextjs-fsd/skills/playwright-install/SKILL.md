---
name: playwright-install
description: "Install Playwright browsers and verify E2E readiness. Usage: /playwright-install [--run] [--spec <file>] [--check]"
user_invocable: true
disable-model-invocation: true
---

# Playwright Install — E2E Testing Setup & Verification

Install Playwright browsers, verify E2E readiness, and optionally run tests.
Ensures the testing environment is correctly set up before any E2E work.

## Token budget (MANDATORY)

- Bash-only skill — no file Reads in the install path. Token cost is the `npx playwright install` output.
- If `--run` is passed, defer to Playwright's reporter; do not duplicate spec output in the chat.
- Do NOT Read `playwright.config.*` unless `--check` fails — only then to diagnose.

## Input

- `/playwright-install` — install browsers + verify setup
- `/playwright-install --run` — install + run all E2E tests
- `/playwright-install --spec e2e/<spec-path>` — install + run a specific spec
- `/playwright-install --check` — only verify if already installed (no install)

## Steps

### 1. Verify the frontend directory

```bash
cd <frontend-app-dir>
grep "@playwright/test" package.json
```

If not found → `npm install -D @playwright/test` first.

### 2. Install Playwright browsers

```bash
cd <frontend-app-dir>
npx playwright install --with-deps chromium
```

**Why only chromium?** — `playwright.config.ts` typically targets `chromium` for CI speed. Add `firefox` / `webkit` here if your config includes them.
`--with-deps` installs system dependencies (fonts, libs) needed for headless mode.

**Expected output:** "Downloading Chromium ... done" — if already installed, it's a no-op (fast).

### 3. Verify installation

```bash
cd <frontend-app-dir>
npx playwright --version
```

Should print a version matching `@playwright/test` in `package.json`.

### 4. Verify the config

Read `<frontend-app-dir>/playwright.config.ts` and confirm:
- `testDir` exists (often `./e2e`)
- `baseURL` matches the dev server (often `http://localhost:3000` for Next.js)
- `projects` includes chromium (and any other browsers you target)

### 5. Check E2E test files

```bash
ls <frontend-app-dir>/e2e/
```

Report how many spec files exist and their categories.

### 6. Run tests (if `--run` or `--spec` flag)

**Pre-flight:**
- Verify the frontend dev server is reachable: `curl -s http://localhost:3000 > /dev/null && echo "OK" || echo "FAIL"`
- Verify any backend the app depends on is reachable: `curl -s http://localhost:8080/healthz > /dev/null && echo "OK" || echo "FAIL"`
- If either fails → warn user: "Start local stack first (`make up` or equivalent)"

**Run:**

```bash
cd <frontend-app-dir>

# All tests
npx playwright test

# Specific spec
npx playwright test e2e/<spec-path>

# UI mode (interactive)
npx playwright test --ui
```

### 7. Report results

Display a summary table:

```
| Item                  | Status     |
|-----------------------|------------|
| Playwright version    | x.y.z      |
| Chromium installed    | ok         |
| Config valid          | ok         |
| E2E specs found       | <n>        |
| Dev server running    | ok / fail  |
| Backend running       | ok / fail  |
| Tests passed (if ran) | X/Y        |
```

## Error recovery

| Error | Fix |
|-------|-----|
| `npx: command not found` | `npm install` first — node_modules missing |
| `browserType.launch: Executable doesn't exist` | Re-run `npx playwright install --with-deps chromium` |
| `Error: page.goto: net::ERR_CONNECTION_REFUSED` | Dev server not running — `npm run dev` |
| `EACCES permission denied` | Run with `sudo npx playwright install-deps` for system libs |
| `TimeoutError` | Check the backend is running; increase the timeout in `playwright.config.ts` |

## When this skill runs automatically

Referenced in the workflow at these checkpoints:

- **Post-Delegation Review gate 6 (integration smoke)** — Browser smoke test requires Playwright.
- **E2E-per-task** — Any task with a UI change must pass E2E before done.
- **Sprint checkpoint** — Integration regression uses `npx playwright test`.

## Related

- `.claude/agents/frontend-fsd-engineer.md` — owner of the FSD frontend work
- `.claude/rules/fsd-layers.md` — the layer rule the engineer follows
- `docs/playbooks/post-delegation-review.md` — gate 6 is integration smoke
