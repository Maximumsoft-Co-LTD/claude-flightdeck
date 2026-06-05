# File-Based Dispatch — write the brief to a file, let the agent read it

> **The rule:** never paste a long task spec into a subagent's `prompt`
> string. Write the spec to a **brief file**, then dispatch with a
> short, stable pointer prompt that tells the agent which file to read.

## Why

A very long inline `prompt` argument to the `Agent` tool is fragile:

- **It can stall / hang the dispatch.** Multi-thousand-line prompts
  (a pasted plan + full AC + touched-files matrix + code excerpts) push
  the dispatch payload past practical limits and the subagent can hang
  before it ever starts working.
- **It's not re-readable.** Once dispatched, the agent can't re-open the
  prompt to check a detail; a file it can re-Read as many times as it
  needs.
- **It's not auditable.** A brief file sits in the repo next to the
  design doc — you can diff it, review it, and the `audit.sh` hook trail
  lines up with a concrete artifact.
- **It bloats the orchestrator's context.** Building a giant prompt
  string inline burns main-session tokens; writing a file and pointing
  at it does not.

This mirrors how the [superpowers](https://github.com/obra/superpowers)
plugin works: plans and specs are written to files
(`docs/superpowers/plans/`, `docs/superpowers/specs/`) and the executing
subagent reads the file, while the reusable dispatch scaffolds are
themselves template files the controller fills in.

## The convention

### 1. Brief files live next to the design docs

```
docs/project/sprints/S<N>/designs/_briefs/<TASK_ID>-<role>.md
```

- `<role>` is the agent's job: `design`, `impl`, `review`, `retro`, …
- Examples:
  - `docs/project/sprints/S04/designs/_briefs/PROJ-S04.12-design.md` (for `design-doc-writer`)
  - `docs/project/sprints/S04/designs/_briefs/PROJ-S04.12-impl.md` (for the engineer)
  - `docs/project/sprints/S04/designs/_briefs/PROJ-S04.12-review.md` (for a reviewer)

The `_briefs/` folder is committed by default — it's a useful audit
trail of exactly what each agent was told. Projects that prefer
ephemeral briefs can add `docs/designs/*/_briefs/` to `.gitignore`.

### 2. The brief file holds the full spec

Everything you would have inlined goes in the file: the `[MANDATORY
READS]` list, the verification-JSON requirement, the task text, AC
(verbatim), touched-files matrix, test plan, cross-cutting flags, the
after-completion steps, and the output contract. For implementation
dispatch this is exactly the content of
[`../../.claude/skills/assign/references/dispatch-prompt-template.md`](../../.claude/skills/assign/references/dispatch-prompt-template.md)
— but written to the brief file instead of pasted into `prompt`.

### 3. The dispatch prompt is short and stable

The only thing passed as `prompt` is a pointer:

```
You are the <role> for <TASK_ID>.

Your brief: docs/project/sprints/S<N>/designs/_briefs/<TASK_ID>-<role>.md
Read it FIRST — it is your complete task input (intent, AC, context,
constraints, reads-first list). The dispatch prompt is intentionally
short; the detail is in the brief so this dispatch can't stall on an
oversized prompt.

Then execute your pre-task ritual (.claude/rules/agent-pre-task-ritual.md),
do the work, and report back per your output contract.
```

Full dispatch shape:

```
Agent(
  subagent_type: "<the role's agent>",
  description: "<role> for <TASK_ID>",
  prompt: "<the short pointer above>",
  isolation: "worktree"      # for any agent that writes
)
```

### 4. The agent reads its brief first

Every agent's pre-task ritual
([`../../.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md)
Step 0) starts with: *if the dispatch names a brief file, Read it before
anything else — it is the primary task input.* This makes all agents,
core and preset, brief-file-aware without special-casing.

## Worked example

Orchestrator, dispatching the design doc writer for `PROJ-S04.12`:

```
1. Write the brief:
   Write docs/project/sprints/S04/designs/_briefs/PROJ-S04.12-design.md
     <intent, AC, context grep excerpts, constraints, reads-first list>

2. Dispatch with the short pointer:
   Agent(
     subagent_type: "design-doc-writer",
     description: "design for PROJ-S04.12",
     prompt: "You are the design-doc-writer for PROJ-S04.12.
              Your brief: docs/project/sprints/S04/designs/_briefs/PROJ-S04.12-design.md
              Read it FIRST ... (short pointer) ..."
   )

3. The agent reads the brief, runs its ritual, writes
   docs/project/sprints/S04/designs/D012-<slug>.md, and reports back.
```

## When inline is still fine

For a genuinely tiny dispatch (a one-paragraph instruction, no AC, no
matrix), inline is fine — the brief file is overhead. The rule of thumb:
**if the spec is more than ~30 lines or includes AC + a touched-files
matrix, write a brief file.** Anything that would make you scroll the
`prompt` argument belongs in a file.

## See also

- [`../../.claude/rules/agent-pre-task-ritual.md`](../../.claude/rules/agent-pre-task-ritual.md) — Step 0 (read your brief)
- [`../../.claude/rules/sub-agent-workflow.md`](../../.claude/rules/sub-agent-workflow.md) — dispatch patterns
- [`../../.claude/skills/assign/references/dispatch-prompt-template.md`](../../.claude/skills/assign/references/dispatch-prompt-template.md) — the impl brief content
- [`lesson-trigger-map.md`](lesson-trigger-map.md) — what rules the brief must cite
