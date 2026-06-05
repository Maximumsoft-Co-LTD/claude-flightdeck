# Verification JSON — Schema

> Loaded by `/assign` Step 8 (and by the dispatched agent's pre-task
> ritual). This file defines the exact JSON the dispatched agent must
> emit BEFORE writing any code. The orchestrator validates against
> this schema and rejects work that ships without it.

## Why this object exists

A dispatched subagent that skips the pre-task ritual is the #1 source
of post-delegation failures: wrong file paths, missed test plan,
applied wrong rules. Forcing a structured emission BEFORE code is the
cheapest gate against this class of failure.

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Dispatch Verification Object",
  "type": "object",
  "required": [
    "task_id",
    "type",
    "phase_list",
    "files_will_touch",
    "design_doc_read",
    "applicable_rules"
  ],
  "additionalProperties": false,
  "properties": {
    "task_id": {
      "type": "string",
      "pattern": "^[A-Z]+-S[0-9]+\\.[0-9]+$",
      "description": "Exact task ID from the sprint row, e.g. TG-S04.12"
    },
    "type": {
      "type": "string",
      "enum": ["feat", "fix", "refactor", "chore", "docs", "spike", "release"],
      "description": "Work type per the phase matrix (drives which phases run)"
    },
    "phase_list": {
      "type": "array",
      "minItems": 1,
      "items": {
        "oneOf": [
          { "type": "integer", "minimum": 1, "maximum": 12 },
          {
            "type": "string",
            "pattern": "^(\\d+|\\d+⚠.*|\\d+ \\([a-z-]+\\)|\\d+ trig.*)$"
          }
        ]
      },
      "description": "Phases this task runs, per phase-matrix.md. Use plain int for ✓, '<n>⚠ (note)' for ⚠, '<n> trig (reason)' for trigger phases."
    },
    "files_will_touch": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "string",
        "pattern": "^[a-zA-Z0-9_./-]+\\.[a-zA-Z0-9]+$"
      },
      "description": "Every file the agent will create OR modify. Must match the design doc's Touched Files matrix."
    },
    "design_doc_read": {
      "type": "boolean",
      "const": true,
      "description": "Must be true. Indicates the agent read the design doc end-to-end before emitting this JSON."
    },
    "applicable_rules": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "string",
        "pattern": "^(A\\d{3}|L\\d{3})$"
      },
      "description": "A### / L### rules the agent will actively apply, per the phase matrix + the task's domain rules."
    }
  }
}
```

## Example — valid object (feat)

```json
{
  "task_id": "TG-S04.12",
  "type": "feat",
  "phase_list": [1, 2, 3, 4, 5, 6, "7 trig (auth surface)", 8, 10, 11, 12],
  "files_will_touch": [
    "internal/domain/tenant/invite.go",
    "internal/app/tenant/create_invite.go",
    "internal/app/tenant/create_invite_test.go",
    "internal/adapter/repo/postgres/invite_repo.go",
    "internal/adapter/http/tenant_handler.go",
    "migrations/20260520_create_tenant_invites.sql"
  ],
  "design_doc_read": true,
  "applicable_rules": ["A001", "A002", "A005", "L036", "L116"]
}
```

## Example — valid object (fix)

```json
{
  "task_id": "TG-S04.15",
  "type": "fix",
  "phase_list": [1, "2⚠ (light)", 3, "4 (regression FIRST)", 5, 6, 8, "10⚠", 11, 12],
  "files_will_touch": [
    "internal/app/tenant/delete_test.go",
    "internal/app/tenant/delete.go"
  ],
  "design_doc_read": true,
  "applicable_rules": ["A001", "A002", "A005"]
}
```

## Example — invalid (auto-reject)

```json
{
  "task_id": "TG-S04.12",
  "type": "feature",                    // ❌ not in enum (use "feat")
  "phase_list": [],                     // ❌ minItems: 1
  "files_will_touch": ["main.go"],
  "design_doc_read": false,             // ❌ must be true
  "applicable_rules": []                // ❌ minItems: 1
}
```

Reject reasons:
- `type=feature` — must be one of `feat | fix | refactor | chore |
  docs | spike | release` (the phase-matrix vocabulary).
- `phase_list=[]` — every type has at least one ✓ phase per the
  matrix.
- `design_doc_read=false` — A005 violation. The agent cannot proceed.
- `applicable_rules=[]` — every code-touching task applies at least
  A002. Missing rules signals the agent didn't read brain-hot.md.

## Validation in the orchestrator

After receiving the dispatched agent's first message:

```bash
# Pseudocode for validation
if ! echo "$first_message" | jq -e '.design_doc_read == true' >/dev/null; then
  reject "Pre-task ritual not followed; design_doc_read must be true"
fi

# Cross-check against the design doc's Touched Files matrix
expected=$(grep -A 50 'Touched Files' docs/project/sprints/S<N>/designs/D<NNN>*.md | \
           grep -oE '\S+\.\w+' | sort -u)
actual=$(echo "$first_message" | jq -r '.files_will_touch[]' | sort -u)

if [ "$expected" != "$actual" ]; then
  warn "files_will_touch diverges from design doc Touched Files matrix"
fi
```

The orchestrator MAY tolerate strict-superset divergences (agent
declares MORE files than the design doc) but MUST reject if the agent
declares FEWER files than the design doc — that means the agent
plans to skip part of the work.

## Where the verification JSON ends up

The orchestrator captures the verification object and pins it to the
6-gate review record. If Gate 1 (Inspect) finds the diff edits a file
NOT in `files_will_touch`, the gate fails — the agent strayed.

## See also

- `dispatch-prompt-template.md` — the `[VERIFICATION]` section that
  prompts for this object
- `../../../rules/agent-pre-task-ritual.md` — the broader ritual the
  agent runs to produce the object
- `../../post-delegation-gate/SKILL.md` — Gate 1 cross-checks the
  declared files vs the diff
