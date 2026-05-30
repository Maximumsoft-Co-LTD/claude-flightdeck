# inbox/ 🟢 Capture

The lowest-friction stage. The only goal: **never lose a link or idea
because capturing it felt like work.**

## How to capture

Append one line to [`_inbox.md`](_inbox.md):

```
- [YYYY-MM-DD] <url> — <one phrase: why it caught your eye>  #track
```

Examples:

```
- [2026-05-30] https://docs.claude.com/... — official skills reference  #claude-code-core
- [2026-05-30] https://github.com/.../aider — diff-based edit loop, worth studying  #adjacent-tools
- [2026-05-30] idea: a /characterize skill that writes tests around legacy code  #legacy-modernization
```

## Rules

- **Don't read it now.** Capture is not processing. Reading happens at weekly triage.
- **Ideas count too.** Prefix with `idea:` instead of a URL.
- **One `#track` tag** from the [taxonomy](../README.md#taxonomy-the-6-research-tracks) if you know it; skip if unsure.
- **No verification needed at capture time** — but verify before it's promoted to a `sources/` note.

## Triage (weekly, ~30 min)

Walk the list top-down. For each line:

- **Worth a close read?** → create a `sources/YYYY-MM-DD-<slug>.md` note (see [`../sources/`](../sources/README.md)), then mark the inbox line `→ sources/<file>`.
- **Quality 1 / not relevant?** → mark `archived: <reason>`.
- **Not sure yet?** → leave it. Stale-but-maybe is fine here.

Keep processed/archived lines in place (struck through or annotated) for a
few weeks so you don't re-capture the same thing, then prune.
