# Programming Fundamentals (auto-loaded · reflex rules)

> Short reflex rules every code-writing agent applies. NOT a textbook —
> if something needs paragraphs of explanation, write a separate
> reference doc under `docs/setup/` and link from here.
>
> Fires on: any task whose phase 5 (Implement) is ✓ in the
> [phase matrix](./phase-matrix.md). Skip for `chore` / `docs` /
> `spike` work that doesn't change behaviour.

## The 7 fundamentals

1. **Data shape first.** Decide what the types LOOK LIKE before
   writing the code that operates on them. Make illegal states
   unrepresentable (sum types over flag-soup, non-empty collections
   over `[]?`, brand types over raw strings).
2. **One function, one thing — pure core, effects at the edge.**
   If you can't summarize a function in one sentence without `and`,
   split it. **The core is pure** (no I/O, no mutation, no clock /
   random / network) where you can make it so; side effects (I/O,
   logging, state mutation) live at the edge. **Prefer immutable
   values** for the data the core operates on — mutation-as-default
   makes the pure-core boundary impossible to defend.
3. **Name what it IS, not what it does.** `usersInLastMonth`, not
   `getUsers`. `Email`, not `String`. `isPaid`, not `paymentFlag`.
   Names lie when they outlive their meaning — rename in the same
   PR that changes the meaning.
4. **Errors are values; handle them deliberately.** Never swallow
   silently (no bare `except:` / `catch (_)`; no `if err != nil
   { /* ignore */ }`). Either handle (with a why), wrap with
   context, or propagate. Logging-and-continuing is a decision, not
   a default.
5. **Watch the complexity ceiling.** Functions > 50 lines OR
   cyclomatic > 10 → extract. Nesting > 3 levels → invert / early-
   return / extract. The ceiling is a smell trigger, not a hard rule
   — but you must justify exceeding it in a comment.
6. **No accidentally quadratic.** A loop inside a loop touching the
   same collection is O(n²). Hash-set lookups beat list scans.
   Profile before optimizing further; don't pre-optimize, but don't
   ship the obvious n² either.
7. **Read the existing code first.** Before adding a new helper, grep
   for one that already does the job (often with a slightly different
   name). Duplication is the most expensive defect — it compounds.

## TDD pre-flight (when phase 4 is ✓ for this type)

Before writing the implementation:

1. **Write the failing test.** Watch it red.
2. **Implement minimum to make it green.** No premature generality.
3. **Refactor with the test as your safety net.** Now is when
   complexity ceiling + naming + dedup happen — not at write-time.

See `.claude/rules/brain-hot.md` A001 (TDD by default) for the
non-negotiable version.

## When to skip

- One-line shell pipelines, throwaway notebooks, pure config edits
  with no logic.
- Renames done by an LSP / IDE that the compiler verified.
- Generated code where you don't own the generator.

## Anti-patterns (auto-reject in code review)

- `// TODO` without a ticket reference (`TODO(JIRA-123)` or
  `TODO(#456)`). Git blame gives an author, not a tracking system —
  open the ticket or remove the TODO.
- `if (true) { ... }` or commented-out blocks "in case we need it
  back." Git remembers. Delete it.
- Exception handlers that print + re-raise without adding context
  (the trace already has it).
- Magic numbers / strings without a named constant. `if status ==
  3` is unreadable; `if status == STATUS_REVIEWING` is fine.
- Public surface area added "just in case." YAGNI — every public
  symbol you add is a future maintenance bill.

## Tie-ins

- **A001 (TDD)** — fires when phase 4 = ✓.
- **A002 (zero-bug)** — these fundamentals are the cheapest way to
  avoid the bugs A002 forbids shipping.
- **Phase matrix** — every ✓ in row "5. Implement" → load this rule
  in the dispatched agent's pre-task ritual.
- **`git-workflow.md`** — atomic commits are the "one function, one
  thing" rule at delivery time.

## See also

- `.claude/rules/brain-hot.md` — the 10 A-rules
- `.claude/rules/phase-matrix.md` — when this rule fires
- `.claude/rules/agent-pre-task-ritual.md` — every agent reads this
  rule alongside `brain-hot.md`
