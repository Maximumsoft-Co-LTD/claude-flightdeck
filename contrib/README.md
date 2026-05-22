# contrib/

Optional tooling for **template maintainers** + **adopters who want
extra ergonomics**. Nothing here is shipped by `install.sh` into target
projects — these live alongside the template, not inside it.

## What's here

| File | For | Install how |
|---|---|---|
| [`install-completion.bash`](./install-completion.bash) | Adopters running `install.sh` often | Symlink into `~/.bash_completion.d/` or `source` per-shell |
| [`pre-commit-version-guard.sh`](./pre-commit-version-guard.sh) | Template repo maintainers | Symlink as `.git/hooks/pre-commit` in this repo |

## `install-completion.bash`

Tab-complete `./install.sh` flags + their values:

```
./install.sh --profile <TAB>       # restricted standard permissive
./install.sh --preset <TAB>        # go-hex,nextjs-fsd,vue-pinia,k8s-helm
./install.sh diff <TAB>            # directory glob
./install.sh <TAB>                 # directory glob (install target)
```

**Install (one session):**
```bash
source contrib/install-completion.bash
```

**Install (permanent, bash):**
```bash
mkdir -p ~/.bash_completion.d
ln -s "$(pwd)/contrib/install-completion.bash" ~/.bash_completion.d/aiwf
# Source it from .bashrc if your distro doesn't auto-load .bash_completion.d:
echo 'source ~/.bash_completion.d/aiwf' >> ~/.bashrc
```

**Install (permanent, zsh with bashcompinit):**
```bash
echo 'autoload bashcompinit && bashcompinit' >> ~/.zshrc
echo "source $(pwd)/contrib/install-completion.bash" >> ~/.zshrc
```

## `pre-commit-version-guard.sh`

For the AI-Workflows **template repo itself** — not for installed
targets. Refuses commits that change `core/` or `presets/` without also
bumping `VERSION`. Catches the silent-drift class: someone adds a rule
to `core/.claude/rules/` and forgets the version bump, so `install.sh
diff` can't detect it.

**Install:**
```bash
ln -s "$(pwd)/contrib/pre-commit-version-guard.sh" .git/hooks/pre-commit
```

**Or via `pre-commit` framework** (in `.pre-commit-config.yaml`):
```yaml
repos:
  - repo: local
    hooks:
      - id: aiwf-version-guard
        name: AIWF VERSION bump guard
        entry: contrib/pre-commit-version-guard.sh
        language: script
        stages: [commit]
```

**Bypass for a single commit:**
```bash
AIWF_SKIP_VERSION_GUARD=1 git commit -m 'whitespace cleanup'
```

## Why these are in `contrib/` and not `core/`

`core/` is what `install.sh` copies into every project. These two
files are tooling for the **template** itself + an **opt-in ergonomic
add-on** — they shouldn't pollute every installed target's `.claude/`
directory.

If you want similar guards inside an installed project (e.g. block
commits that change `.claude/rules/` without bumping a project-local
version), copy + adapt — the patterns are short.

## Adding a new contrib script

Same shape:
1. Drop the script in this directory.
2. `chmod +x` it.
3. Add a row to the table at the top of this README explaining who
   it's for and how to install.
4. Mention it in the top-level `README.md` if it's high-value for
   adopters.
