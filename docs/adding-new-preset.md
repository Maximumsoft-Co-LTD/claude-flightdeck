# Adding a new preset

Presets are opt-in tech-stack bundles installed on top of `core/` via
`./install.sh ... --preset <name>`. Adding one is just a matter of
putting files in the right shape.

## Directory layout

```
presets/<your-name>/
├── agents/
│   └── <engineer-or-reviewer>.md
├── rules/
│   └── <your-rule>.md
├── skills/
│   └── <skill-name>/SKILL.md
└── docs/setup/
    └── <some-doc>.md
```

Each subdirectory maps to a destination under the target project:

| Source path in preset           | Destination in target project        |
|---------------------------------|---------------------------------------|
| `presets/<n>/agents/foo.md`     | `.claude/agents/foo.md`               |
| `presets/<n>/rules/bar.md`      | `.claude/rules/bar.md`                |
| `presets/<n>/skills/baz/...`    | `.claude/skills/baz/...`              |
| `presets/<n>/docs/setup/x.md`   | `docs/setup/x.md`                     |

The installer copies recursively. If a preset file shares a name with a
core file, the preset wins (last write). Avoid collisions unless you
intend to override core.

## Worked example — adding a `python-fastapi` preset

```bash
mkdir -p presets/python-fastapi/{agents,rules,skills,docs/setup}
```

### 1. Agent

```yaml
# presets/python-fastapi/agents/fastapi-engineer.md
---
name: fastapi-engineer
description: Implement Python services using FastAPI + Pydantic v2 +
  SQLAlchemy 2. Follows hex layout (cmd → adapters → usecase → ports
  → domain), TDD with pytest, async-first I/O.
model: opus
tools:
  - Glob
  - Grep
  - LS
  - Read
  - Bash
  - Edit
  - Write
  - MultiEdit
  - TodoWrite
  - Agent
  - SendMessage
---

# fastapi-engineer

## Pre-task ritual (MANDATORY)

Read:
1. `.claude/rules/agent-pre-task-ritual.md`
2. `.claude/rules/brain-hot.md`
3. `.claude/rules/python-patterns.md` (this preset)
4. The task design doc at `docs/designs/sprint-S<N>/D<NNN>-<slug>.md`

Failing to read any of these = automatic review reject (A006/A011).

## What you do
… (specifics — async patterns, Pydantic v2 strict mode, …)

## What you DON'T do
- Skip type hints (PEP 561 + strict mypy)
- Use sync I/O in request handlers
- Author SQL by string concat (always SQLAlchemy 2)
```

### 2. Rule

```markdown
# presets/python-fastapi/rules/python-patterns.md
# Python + FastAPI patterns (preset rule — auto-loaded if installed)

## Always
- All handlers `async def`; never `def` (event loop starvation)
- Pydantic v2 with `model_config = ConfigDict(strict=True)`
- SQLAlchemy 2.0 syntax (`select(...)`, `session.execute(...)`)
- Type hints on every function (mypy strict in CI)
- Tests with pytest + httpx AsyncClient
…
```

### 3. Skill (optional)

```yaml
# presets/python-fastapi/skills/run-migrations/SKILL.md
---
name: run-migrations
description: "Apply Alembic migrations and verify schema head. Use:
  '/run-migrations', 'apply migrations'."
user_invocable: true
---

# /run-migrations

## Token budget (MANDATORY)
- Reads alembic.ini, head check via Bash; do not Read migration files
  in full unless one fails to apply.

## Steps
1. Bash: `alembic current`
2. Bash: `alembic upgrade head`
3. Verify head: `alembic heads`
4. Smoke: `pytest tests/integration/test_schema.py -x`
```

### 4. Doc

```markdown
# presets/python-fastapi/docs/setup/python-testing-patterns.md
# Python testing patterns

## pytest layout
…
## Fixtures with testcontainers (Postgres / Redis / Kafka)
…
## Async test ergonomics (anyio / asyncio.gather)
…
```

### 5. Register in README

Add a row to the preset table in the top-level `README.md`:

```markdown
| `python-fastapi` | `fastapi-engineer` agent + `python-patterns.md` rule + `/run-migrations` skill + `docs/setup/python-testing-patterns.md` |
```

### 6. Test

```bash
mkdir -p /tmp/test-pyinstall
./install.sh /tmp/test-pyinstall --preset python-fastapi --config <(cat <<EOF
PROJECT_NAME="PyTest"
PROJECT_SLUG=pytest
AGENT_PREFIX=py
TASK_ID_PREFIX=PY
TECH_STACK_DESC="Python 3.12 + FastAPI + Postgres"
BRAIN_PATH=""
PRESETS=python-fastapi
EOF
) --force

# Verify
ls /tmp/test-pyinstall/.claude/agents/    # should include fastapi-engineer.md
ls /tmp/test-pyinstall/.claude/rules/     # should include python-patterns.md
ls /tmp/test-pyinstall/.claude/skills/    # should include run-migrations/
ls /tmp/test-pyinstall/docs/setup/        # should include python-testing-patterns.md
grep -rln '{{[A-Z_]\{2,\}}}' /tmp/test-pyinstall && echo "FAIL: placeholders left" || echo "OK"
```

## Guidelines

- **Keep the preset focused.** One stack = one preset. Don't bundle
  "go + python + node" in one — installers should be able to pick
  exactly the languages they use.
- **Always include a rule file** if the preset has an architectural
  opinion (hex direction, FSD layers, …). Engineers reference it in
  their pre-task ritual.
- **Always include at least one reviewer agent** if your preset has
  architectural rules to enforce (it powers gate 3 of the 6-gate
  review).
- **Use placeholders** for project-specific values
  (`{{PROJECT_NAME}}`, `{{AGENT_PREFIX}}`, `{{TASK_ID_PREFIX}}`,
  `{{TECH_STACK_DESC}}`). The installer renders them.
- **Don't override core unless you mean to.** If your preset writes
  `.claude/rules/brain-hot.md.tmpl`, you replace the universal version.
  Almost always wrong — keep core rules in core, preset rules in
  `presets/<name>/rules/`.

## When NOT to make a preset

- The thing only applies to one specific project — keep it as a
  project-local rule / agent / skill, not a preset.
- The thing is a universally-good engineering practice — lift it into
  `core/` instead.
- The thing is just a list of common bash commands — put them in
  `docs/setup/<topic>.md` and link from the relevant agent / rule.
