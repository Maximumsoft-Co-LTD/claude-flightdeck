<!-- Thanks for contributing back to claude-flightdeck! -->

## What this changes

<!-- 1-3 sentences. What + why. -->

## Type

- [ ] New preset (`presets/<name>/`)
- [ ] Rule fix / addition (`core/.claude/rules/`)
- [ ] Skill fix / addition (`core/.claude/skills/`)
- [ ] Agent fix / addition (`core/.claude/agents/`)
- [ ] Playbook / docs (`core/docs/`)
- [ ] Installer (`install.sh` / `install.ps1`)
- [ ] Template-repo tooling (`contrib/`, `.github/`, examples)

## Checklist

- [ ] **VERSION bumped** if `core/` or `presets/` changed (the
      `contrib/pre-commit-version-guard.sh` hook enforces this — semver:
      patch for fixes, minor for features, major for breaking)
- [ ] **CHANGELOG.md** has an entry under the right version
- [ ] **De-domain-specified** — no project-specific names leaked into
      `core/` (no `idip-`, `agg-`, company-internal IDs); opinions live
      in `presets/`, not `core/`
- [ ] If a **skill** changed: it still has a `## Token budget` section
- [ ] If an **agent** changed: it still references
      `agent-pre-task-ritual.md`
- [ ] If a **`.tmpl`** changed: placeholders render cleanly
      (`grep -rn '{{' ` on a test install returns nothing)
- [ ] Ran the install smoke test:
      `./install.sh /tmp/pr-test --preset <relevant> --config <cfg> --force`
      and confirmed it lands clean
- [ ] If a **new preset**: followed `docs/adding-new-preset.md` +
      added a row to the preset table in `README.md`

## Verification evidence

<!-- Paste the actual command output proving the change works.
     Evidence before assertions (A003). -->

```
$ ./install.sh /tmp/pr-test ...
...
```

## Related

<!-- Link the issue this closes, if any: Closes #NN -->
