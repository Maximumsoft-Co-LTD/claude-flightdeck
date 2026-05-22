# Settings.json soft-merge

When you re-install `AI-Workflows` into a project that **already has a
customized `.claude/settings.json`** (e.g. extra `permissions.allow`
rules, a different `model`, custom hooks beyond the foundation's lint
hook), the installer preserves your copy and writes the new foundation
settings beside it instead of overwriting.

## What you see after re-install

```
target-project/.claude/
├── settings.json                 ← your original, preserved
└── settings.foundation.json      ← what the installer wanted to ship
```

Plus a `warn` message in the installer output telling you to merge.

## What to merge

The foundation update almost always touches one of three things:

| Where | What's new | How to merge |
|---|---|---|
| `hooks.PostToolUse` | `lint.sh` matcher / wiring (or other future hooks) | **Add this block** to your `settings.json` if missing. Idempotent — re-running install will warn again until it's in. |
| `permissions.allow` | New Bash patterns the foundation needs | Append the missing patterns; don't replace your list. Order doesn't matter. |
| `hooks.SessionStart` | Future expansion (currently empty `[]`) | Usually safe to merge — anything new in foundation is read-only context loading. |

Everything else (`model`, `env`, your own custom hooks, your own
permissions) stays as-is.

## Manual merge recipe

If you have `jq` (recommended):

```bash
cd target-project
# Soft-merge foundation INTO your existing settings.
#   - permissions.allow: union, deduped
#   - top-level scalars / objects (model, env, etc.): user wins
#   - hooks.{PreToolUse,PostToolUse,SessionStart,SubagentStop}: concatenate
#     foundation + user arrays, then de-dupe by `matcher` (foundation wins on tie)
jq -s '
  .[0] as $user | .[1] as $found |

  # Concatenate two hook-arrays and de-dupe by `matcher` (first wins).
  def merge_hook_arrays($a; $b):
    (($a // []) + ($b // []))
    | unique_by(.matcher);

  # Merge a hook section (object of matcher-keyed arrays) for one event.
  def merge_event($u; $f):
    merge_hook_arrays($f; $u);

  $user
  # 1. Union permissions.allow
  | .permissions.allow = ((($user.permissions.allow // []) + ($found.permissions.allow // [])) | unique)
  # 2. Hooks: per-event concat-then-dedupe-by-matcher
  | .hooks = (
      ($user.hooks // {}) as $uh
      | ($found.hooks // {}) as $fh
      | reduce ["PreToolUse","PostToolUse","SessionStart","SubagentStop","Stop","UserPromptSubmit"][] as $evt
          ($uh;
           if ($fh[$evt] // null) == null and (.[$evt] // null) == null then .
           else .[$evt] = merge_event(.[$evt] // []; $fh[$evt] // [])
           end)
    )
' .claude/settings.json .claude/settings.foundation.json \
  > .claude/settings.merged.json

# Inspect the result
diff -u .claude/settings.json .claude/settings.merged.json | less

# If you're happy:
mv .claude/settings.merged.json .claude/settings.json
rm .claude/settings.foundation.json
```

> **Caveat.** The recipe assumes hooks are keyed by `matcher`. If your
> hooks share a matcher but differ in `command` (e.g. you customized
> the foundation's `Write|Edit` hook to call a different script),
> hand-merge — the automatic dedupe will keep whichever appears first
> (foundation wins). Run a `diff` after merging and patch the surviving
> entry by hand if your custom `command` was the one that mattered.

Without `jq`: open both files side by side in your editor, copy the
foundation's `hooks` block + any `permissions.allow` entries you don't
already have, paste into your `settings.json`, save, delete
`settings.foundation.json`.

## Why not auto-merge?

The installer is intentionally conservative. `settings.json` controls
two things you don't want stomped:

1. **Permissions** — auto-merging could grant the foundation more than
   you intended, or revoke a pattern you carefully added.
2. **Hooks** — running someone else's PostToolUse / PreToolUse
   automatically would let the foundation inject arbitrary commands
   into your dev loop. Surface them; let you read and approve.

The cost of one manual merge per upgrade is small. The cost of a
silent merge that broke your permissions is large. So: side-by-side,
not silent.

## Suppressing the warning on fresh installs

If the target had a `settings.json` that exactly matches a fresh
foundation render (sorted-line equality, modulo key order), the
installer silently discards the stash — no warning, no snippet file.
This means: **the first install never triggers the merge path**, only
re-installs into a customized target do.

## What if I want the foundation values to win?

Re-run with `--force`:

```bash
./install.sh ./target --force ...
```

`--force` **deletes** any existing `.claude/` outright (no backup) and
**skips the soft-merge entirely** — the foundation `settings.json`
overwrites whatever was there. There is no recovery path inside the
installer itself: rely on git (the target should be a git repo, so the
old `.claude/settings.json` is recoverable via `git checkout HEAD --
.claude/settings.json`).

Without `--force`, the default behavior is conservative: `.claude/` is
**moved** to `.claude.backup-<timestamp>/` and the soft-merge path
runs, preserving your `settings.json` if it differs from the
foundation.

## See also

- `install.sh` — the `soft_merge_settings()` function does the
  comparison + side-by-side write
- `core/.claude/settings.json.tmpl` — the foundation source
- `docs/how-to-customize.md` — what to safely customize in
  `settings.json` long-term
