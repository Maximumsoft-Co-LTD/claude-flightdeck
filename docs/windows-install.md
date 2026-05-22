# Windows install

The PowerShell installer (`install.ps1`) is the native path for Windows. It
mirrors `install.sh` section-by-section so the two are interchangeable.
WSL with `install.sh` is also a fully supported alternative — pick whichever
matches your shell.

## Quick start (PowerShell)

```powershell
# Clone the template
git clone <this-repo> C:\code\ai-workflows
cd C:\code\ai-workflows

# Interactive (prompts for values) — no preset needed; core is architecture-agnostic
.\install.ps1 C:\code\my-new-service

# Or from a config file
Copy-Item template.config.example template.config
notepad template.config
.\install.ps1 C:\code\my-new-service -Config template.config

# See what would happen without writing anything
.\install.ps1 C:\code\my-new-service -DryRun

# Force-overwrite an existing .claude/ (otherwise it backs up first)
.\install.ps1 C:\code\my-new-service -Force
```

`Get-Help .\install.ps1 -Detailed` shows the full parameter list.

## ExecutionPolicy

By default Windows blocks unsigned scripts. The least-permissive policy
that lets `install.ps1` run is `RemoteSigned` for the current user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

You only need to do this once. If you can't change policy (managed
machine), bypass for a single invocation:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1 C:\code\my-new-service
```

## Subcommands & flags

Parity with `install.sh`:

| Bash | PowerShell |
|---|---|
| `./install.sh target` | `.\install.ps1 target` |
| `--profile standard` | `-Profile standard` |
| `--preset k8s-helm` | `-Preset k8s-helm` |
| `--config template.config` | `-Config template.config` |
| `--brain-path PATH` | `-BrainPath PATH` |
| `--dry-run` | `-DryRun` |
| `--force` | `-Force` |
| `--version` | `-Version` |
| `diff <target>` | `diff <target>` (positional, same syntax) |

## Line endings

`install.ps1` writes rendered files as **UTF-8 without BOM** via
`[System.IO.File]::WriteAllText`, and reads source files with
`Get-Content -Raw`, which preserves the source's line endings verbatim.
The `core/` and `presets/` files in this repo use LF, so the installed
target receives LF — matching the bash installer.

Caveat: if you clone this repo on Windows with default Git settings,
`git config --global core.autocrlf true` will rewrite LF to CRLF in your
working tree. The installer will then propagate CRLF into the target.
To avoid that:

```powershell
git config --global core.autocrlf input
# or per-repo:
git -C C:\code\ai-workflows config core.autocrlf false
```

Then `git checkout -- .` to refresh the working tree to LF.

## Hook permissions

`.claude/hooks/lint.sh` ships with the executable bit set. Windows
doesn't enforce that bit, so the installer is a no-op there. If you
later run the same target inside WSL, run:

```bash
chmod +x .claude/hooks/*.sh
```

The bash hooks themselves run under `bash` (or `wsl bash` on Windows).
Native Windows Claude Code uses the same `.claude/hooks/lint.sh` via
`bash` on PATH — install Git for Windows (which ships `bash.exe`) or
use WSL.

## When to prefer WSL

If your project already builds under WSL (Linux toolchains, `make`,
`docker`, `go`, `npm` running inside WSL), run `install.sh` from inside
WSL against the same path:

```bash
# inside WSL
./install.sh /mnt/c/code/my-new-service
```

This avoids any line-ending or path-translation surprises and uses the
exact same script that CI runs.

## Troubleshooting

- **"running scripts is disabled on this system"** — set
  `ExecutionPolicy RemoteSigned` (see above).
- **"profile template missing"** — the `core/` directory is incomplete.
  Re-clone or re-pull the template.
- **Placeholders still in output** — a new `{{VAR}}` was added to a
  `.tmpl` file but not to `install.ps1`'s `Invoke-Render`. Open an issue
  or patch the `Invoke-Render` function (search for the existing
  `.Replace('{{PROJECT_NAME}}', ...)` block).
- **`git rev-parse` fails / `source_commit` empty in manifest** — fine,
  just means the template wasn't installed from a git checkout. The
  installer continues without it.
