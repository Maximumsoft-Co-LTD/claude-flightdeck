<#
.SYNOPSIS
    AI-Workflows installer — copies the control-plane template into a target project.

.DESCRIPTION
    PowerShell port of install.sh. Works on PowerShell 5.1 (Windows 10/11
    default) and PowerShell 7+ (cross-platform). Mirrors the bash installer
    section-by-section so the two scripts can be read side-by-side.

    -Profile selects the permission/hook foundation rendered to
    .claude/settings.json (see docs/setup/permission-profiles.md):
      restricted  — read-only Bash allow-list (audit / pair-programming sessions)
      standard    — common dev tools (go/make/git/gh/docker/npm/curl/jq + read-only)  [DEFAULT]
      permissive  — Bash(*) with a deny-list of obviously destructive shapes

    Vars substituted in *.tmpl files (Mustache-style {{NAME}}):
      PROJECT_NAME, PROJECT_SLUG, AGENT_PREFIX, TECH_STACK_DESC, BRAIN_PATH, TASK_ID_PREFIX

.PARAMETER Target
    The target project directory. When using `diff`, this is the installed
    project to inspect. Pass the literal string `diff` first to invoke the
    drift subcommand: `.\install.ps1 diff <target>`.

.PARAMETER Profile
    Permission profile: restricted | standard | permissive. Default: standard.

.PARAMETER Preset
    Comma-separated preset names to merge over core/. E.g. "k8s-helm". Optional — core is architecture-agnostic.

.PARAMETER Config
    Path to a KEY="value" config file (same shape as template.config.example).

.PARAMETER BrainPath
    External Brain path (Obsidian vault). Blank = use in-repo .claude/memory/.

.PARAMETER DryRun
    Show what would happen without writing anything.

.PARAMETER Force
    Overwrite existing .claude/ / CLAUDE.md without backing up.

.PARAMETER Version
    Print template version and exit.

.PARAMETER Help
    Show usage and exit.

.EXAMPLE
    .\install.ps1 C:\code\my-new-service

.EXAMPLE
    .\install.ps1 .\target -Profile restricted

.EXAMPLE
    .\install.ps1 .\target -Preset k8s-helm -BrainPath C:\Obsidian\brain

.EXAMPLE
    .\install.ps1 .\target -Config template.config -Force

.EXAMPLE
    .\install.ps1 .\target -DryRun

.EXAMPLE
    .\install.ps1 diff C:\code\my-new-service
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target,

    [Parameter(Position = 1)]
    [string]$MaybeTarget,

    [ValidateSet('restricted', 'standard', 'permissive')]
    [string]$Profile = 'standard',

    [string]$Preset,
    [string]$Config,
    [string]$BrainPath,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Version,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------- color helpers ----------
function Write-Note { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Warn { param([string]$Msg) Write-Host "warn: $Msg" -ForegroundColor Yellow }
function Write-Ok   { param([string]$Msg) Write-Host "  ok  $Msg" -ForegroundColor Green }
function Write-Die  {
    param([string]$Msg)
    Write-Host "ERROR: $Msg" -ForegroundColor Red
    exit 1
}

# ---------- version load ----------
# Read template version from the canonical VERSION file (single source of
# truth). Empty if the file is missing — the installer still works but no
# manifest version field will be written.
$AiwfVersion = ''
$VersionFile = Join-Path $PSScriptRoot 'VERSION'
if (Test-Path -LiteralPath $VersionFile -PathType Leaf) {
    $AiwfVersion = (Get-Content -LiteralPath $VersionFile -TotalCount 1).Trim()
}

if ($Version) {
    $v = if ([string]::IsNullOrEmpty($AiwfVersion)) { 'unknown' } else { $AiwfVersion }
    Write-Host "AI-Workflows v$v"
    exit 0
}

if ($Help) {
    Get-Help -Detailed $PSCommandPath
    exit 0
}

# ---------- arg parse: subcommand detection ----------
# Currently supported: `diff <target>` — compare installed manifest vs
# current template. Otherwise the first positional is the install target.
$SubCommand = ''
if ($Target -eq 'diff') {
    $SubCommand = 'diff'
    $Target = $MaybeTarget
}
elseif ($MaybeTarget) {
    Write-Die "unexpected positional arg: $MaybeTarget"
}

# ---------- diff subcommand ----------
# Reports drift between a target's `.ai-workflows/manifest.json` and the
# current template. Lists files modified since the manifest's mtime.
if ($SubCommand -eq 'diff') {
    if ([string]::IsNullOrEmpty($Target)) { Write-Die 'diff: missing <target-dir>' }
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        Write-Die "diff: target not found: $Target"
    }
    $Manifest = Join-Path $Target '.ai-workflows/manifest.json'
    if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
        Write-Die "diff: no manifest at $Manifest (target not installed via this template?)"
    }
    # -AsHashtable would be ideal but isn't available in PS 5.1 / 7.0. Use
    # raw JSON regex extraction so install_date stays a string (PowerShell
    # auto-coerces ISO strings to DateTime, which then re-renders in the
    # local culture format).
    $rawJson = Get-Content -LiteralPath $Manifest -Raw
    $installed = if ($rawJson -match '"version"\s*:\s*"([^"]*)"') { $Matches[1] } else { 'unknown' }
    $sourceCommit = if ($rawJson -match '"source_commit"\s*:\s*"([^"]*)"') { $Matches[1] } else { '' }
    $installDate = if ($rawJson -match '"install_date"\s*:\s*"([^"]*)"') { $Matches[1] } else { '' }

    $tpl = if ([string]::IsNullOrEmpty($AiwfVersion)) { 'unknown' } else { $AiwfVersion }
    Write-Host "Target installed v$installed, current template v$tpl."
    Write-Host "  manifest      $Manifest"
    Write-Host "  install_date  $(if ([string]::IsNullOrEmpty($installDate)) { '?' } else { $installDate })"
    Write-Host "  source_commit $(if ([string]::IsNullOrEmpty($sourceCommit)) { '<unknown / tarball install>' } else { $sourceCommit })"
    Write-Host ''
    if (-not [string]::IsNullOrEmpty($installDate)) {
        Write-Note "Files in target's .claude/ and docs/playbooks/ modified since install_date:"
        # Use the manifest's mtime as the stable reference (touched at install end).
        $refTime = (Get-Item -LiteralPath $Manifest).LastWriteTime
        $roots = @(
            (Join-Path $Target '.claude'),
            (Join-Path $Target 'docs/playbooks')
        )
        $changed = @()
        foreach ($r in $roots) {
            if (Test-Path -LiteralPath $r) {
                $changed += Get-ChildItem -LiteralPath $r -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -gt $refTime } |
                    ForEach-Object {
                        $_.FullName.Substring($Target.Length).TrimStart('\', '/')
                    }
            }
        }
        $changed | Sort-Object -Unique | ForEach-Object { Write-Host $_ }
    }
    Write-Host ''
    if (-not [string]::IsNullOrEmpty($AiwfVersion) -and -not [string]::IsNullOrEmpty($installed) -and $installed -ne $AiwfVersion) {
        Write-Warn "version drift: target v$installed vs template v$AiwfVersion"
        Write-Warn "upgrade path (current): re-run install.ps1 $Target -Force after backing up."
    }
    exit 0
}

if ([string]::IsNullOrEmpty($Target)) {
    Write-Die 'missing <target-dir> (try -Help)'
}

# ---------- config load / prompt ----------
function Get-Slug {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $s = $Text.ToLowerInvariant()
    $s = [regex]::Replace($s, '[^a-z0-9]+', '-')
    $s = $s.Trim('-')
    return $s
}

# Mutable bag of placeholders. Treated like a small scope.
$Vars = @{
    PROJECT_NAME    = ''
    PROJECT_SLUG    = ''
    AGENT_PREFIX    = ''
    TECH_STACK_DESC = ''
    TASK_ID_PREFIX  = ''
    BRAIN_PATH      = $BrainPath
}

function Read-ConfigFile {
    # Parse a KEY="value" config file (template.config.example shape).
    # Lines starting with # are comments. Quotes are stripped.
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Die "config file not found: $Path"
    }
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trim = $line.Trim()
        if ($trim -eq '' -or $trim.StartsWith('#')) { continue }
        if ($trim -match '^([A-Z_][A-Z0-9_]*)\s*=\s*(.*)$') {
            $key = $Matches[1]
            $val = $Matches[2].Trim()
            # strip optional surrounding quotes
            if ($val -match '^"(.*)"$' -or $val -match "^'(.*)'$") {
                $val = $Matches[1]
            }
            if ($Vars.ContainsKey($key)) {
                # don't overwrite -BrainPath provided as a flag
                if ($key -eq 'BRAIN_PATH' -and -not [string]::IsNullOrEmpty($Vars.BRAIN_PATH)) { continue }
                $Vars[$key] = $val
            }
            elseif ($key -eq 'PRESETS') {
                if ([string]::IsNullOrEmpty($Preset)) { $script:Preset = $val }
            }
        }
    }
    Write-Note "loaded config: $Path"
}

function Read-Var {
    # $Key into $Vars; prompt with optional default. Skip if already set.
    param(
        [string]$Key,
        [string]$Prompt,
        [string]$Default = ''
    )
    if (-not [string]::IsNullOrEmpty($Vars[$Key])) { return }
    # Best-effort interactive detection. In a non-interactive shell we
    # fall back to the default (matching the bash flow loosely — bash
    # reads from /dev/tty regardless; PowerShell can't always do that).
    $interactive = $true
    try {
        if ([Environment]::UserInteractive -eq $false) { $interactive = $false }
    } catch { $interactive = $true }

    if (-not $interactive) {
        $Vars[$Key] = $Default
        return
    }

    $label = if ([string]::IsNullOrEmpty($Default)) { $Prompt } else { "$Prompt [$Default]" }
    $val = Read-Host -Prompt $label
    if ([string]::IsNullOrEmpty($val)) { $val = $Default }
    $Vars[$Key] = $val
}

if (-not [string]::IsNullOrEmpty($Config)) {
    Read-ConfigFile -Path $Config
}

# interactive prompts for anything still empty
Read-Var -Key 'PROJECT_NAME'    -Prompt 'Project name (human-readable, e.g. "My Service")'
$slugDefault = Get-Slug -Text $Vars.PROJECT_NAME
Read-Var -Key 'PROJECT_SLUG'    -Prompt 'Project slug (kebab-case)' -Default $slugDefault
Read-Var -Key 'AGENT_PREFIX'    -Prompt 'Agent prefix (e.g. "myservice")' -Default $Vars.PROJECT_SLUG
Read-Var -Key 'TECH_STACK_DESC' -Prompt 'Tech stack (free text)' -Default 'TBD'
$taskDefault = $Vars.AGENT_PREFIX.ToUpperInvariant()
Read-Var -Key 'TASK_ID_PREFIX'  -Prompt 'Task ID prefix (e.g. "PROJ" -> PROJ-001)' -Default $taskDefault
if ([string]::IsNullOrEmpty($Vars.BRAIN_PATH)) {
    Read-Var -Key 'BRAIN_PATH' -Prompt 'External Brain path (Obsidian vault, blank to use in-repo .claude/memory/)' -Default ''
}

# validate slug
if ($Vars.PROJECT_SLUG -notmatch '^[a-z0-9][a-z0-9-]*$') {
    Write-Die "PROJECT_SLUG must be kebab-case: got '$($Vars.PROJECT_SLUG)'"
}
if ($Vars.AGENT_PREFIX -notmatch '^[a-z0-9][a-z0-9-]*$') {
    Write-Die "AGENT_PREFIX must be kebab-case: got '$($Vars.AGENT_PREFIX)'"
}

# resolve target (create + canonicalize)
function Resolve-AbsolutePath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

if (-not (Test-Path -LiteralPath $Target)) {
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $Target | Out-Null
    } else {
        # dry-run: synthesize an absolute path without creating
        $Target = Resolve-AbsolutePath -Path $Target
    }
}
if (Test-Path -LiteralPath $Target) {
    $Target = (Resolve-Path -LiteralPath $Target).Path
}

Write-Note 'Install plan:'
Write-Host "  target          $Target"
Write-Host "  project name    $($Vars.PROJECT_NAME)"
Write-Host "  project slug    $($Vars.PROJECT_SLUG)"
Write-Host "  agent prefix    $($Vars.AGENT_PREFIX)"
Write-Host "  task prefix     $($Vars.TASK_ID_PREFIX)"
Write-Host "  tech stack      $($Vars.TECH_STACK_DESC)"
$brainDisplay = if ([string]::IsNullOrEmpty($Vars.BRAIN_PATH)) { '<in-repo .claude/memory/>' } else { $Vars.BRAIN_PATH }
Write-Host "  brain path      $brainDisplay"
$presetDisplay = if ([string]::IsNullOrEmpty($Preset)) { '<core only>' } else { $Preset }
Write-Host "  presets         $presetDisplay"
Write-Host "  profile         $Profile"
Write-Host "  dry-run         $(if ($DryRun) { 'yes' } else { 'no' })"
Write-Host "  force           $(if ($Force) { 'yes' } else { 'no' })"
Write-Host ''

# ---------- existence / backup ----------
function Backup-Existing {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    if ($Force) {
        if ($DryRun) {
            Write-Warn "would -Force overwrite: $Path"
        } else {
            Write-Warn "-Force: removing $Path"
            Remove-Item -LiteralPath $Path -Recurse -Force
        }
        return
    }
    # InvariantCulture so Buddhist / Hebrew / Persian locales don't skew the year.
    $ts = (Get-Date).ToString('yyyyMMdd-HHmmss', [System.Globalization.CultureInfo]::InvariantCulture)
    $bak = "$Path.backup-$ts"
    if ($DryRun) {
        Write-Warn "would back up: $Path -> $bak"
    } else {
        Write-Warn "backing up: $Path -> $bak"
        Move-Item -LiteralPath $Path -Destination $bak
    }
}

# settings.json gets soft-merge treatment below — DON'T back it up here.
foreach ($p in @((Join-Path $Target 'CLAUDE.md'), (Join-Path $Target 'docs/spec/STATUS.md'))) {
    if (Test-Path -LiteralPath $p) { Backup-Existing -Path $p }
}

# Path the soft-merge step looks for the user's old settings at.
$StashPath = $null

try {

# .claude/ as a whole: back up unless --force. Stash settings.json inside
# the backup dir so a mid-install abort doesn't leave a stale, potentially
# secret-bearing file lying around in the user's project.
$claudeDir = Join-Path $Target '.claude'
if (Test-Path -LiteralPath $claudeDir) {
    $existingSettings = Join-Path $claudeDir 'settings.json'
    $hadSettings = Test-Path -LiteralPath $existingSettings -PathType Leaf
    Backup-Existing -Path $claudeDir
    if ($hadSettings -and -not $DryRun -and -not $Force) {
        # find the backup we just made (most recent .claude.backup-*).
        # -Force needed on Unix-like systems where dot-prefixed dirs are hidden.
        $latestBak = Get-ChildItem -LiteralPath $Target -Directory -Filter '.claude.backup-*' -Force -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestBak -and (Test-Path -LiteralPath (Join-Path $latestBak.FullName 'settings.json'))) {
            $StashPath = Join-Path $latestBak.FullName '.user-settings.json.stash'
            try {
                Copy-Item -LiteralPath (Join-Path $latestBak.FullName 'settings.json') -Destination $StashPath -Force
            } catch {
                $StashPath = $null
            }
        }
    }
}

# ---------- copy core ----------
function Copy-Tree {
    # Recursively copy $Src/* -> $Dst/, preserving dotfiles.
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path -LiteralPath $Src -PathType Container)) { return }
    if ($DryRun) {
        Get-ChildItem -LiteralPath $Src -Recurse -File -Force | ForEach-Object {
            $rel = $_.FullName.Substring($Src.Length).TrimStart('\', '/')
            Write-Host "  + $(Join-Path $Dst $rel)"
        }
        return
    }
    if (-not (Test-Path -LiteralPath $Dst)) {
        New-Item -ItemType Directory -Force -Path $Dst | Out-Null
    }
    # Copy contents (not the parent dir). Force = include hidden + overwrite.
    Get-ChildItem -LiteralPath $Src -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Dst -Recurse -Force
    }
}

Write-Note "Copying core/ -> $Target/"
Copy-Tree -Src (Join-Path $PSScriptRoot 'core') -Dst $Target

# Ensure hook scripts are executable after copy. Windows: no-op (the bit
# isn't enforced). pwsh on macOS/Linux: best-effort chmod +x via the
# native binary if it's on PATH.
$hooksDir = Join-Path $Target '.claude/hooks'
if (-not $DryRun -and (Test-Path -LiteralPath $hooksDir -PathType Container)) {
    # Detect Windows without tripping strict-mode on PS 5.1 (where $IsWindows is undefined).
    $isWin = $true
    $iwVar = Get-Variable -Name IsWindows -ErrorAction SilentlyContinue
    if ($iwVar -and $null -ne $iwVar.Value) { $isWin = [bool]$iwVar.Value }
    if (-not $isWin) {
        $chmod = Get-Command chmod -ErrorAction SilentlyContinue
        if ($chmod) {
            Get-ChildItem -LiteralPath $hooksDir -Recurse -File -Filter '*.sh' -ErrorAction SilentlyContinue | ForEach-Object {
                & chmod +x $_.FullName | Out-Null
            }
        }
    }
}

# ---------- select permission profile ----------
# core/ ships three settings.<profile>.json.tmpl variants. Pick the one
# matching --profile, rename it to settings.json.tmpl so the render pass
# turns it into settings.json. Discard the other two.
function Select-Profile {
    $chosen = Join-Path $Target ".claude/settings.$Profile.json.tmpl"
    $targetTmpl = Join-Path $Target '.claude/settings.json.tmpl'
    if ($DryRun) {
        Write-Note "would select profile: $Profile (settings.$Profile.json.tmpl -> settings.json)"
        return
    }
    if (-not (Test-Path -LiteralPath $chosen -PathType Leaf)) {
        Write-Die "profile template missing: $chosen (corrupt install or new profile not on disk)"
    }
    Move-Item -LiteralPath $chosen -Destination $targetTmpl -Force
    foreach ($variant in @('restricted', 'standard', 'permissive')) {
        $p = Join-Path $Target ".claude/settings.$variant.json.tmpl"
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
    }
    Write-Ok "profile selected: $Profile (-> .claude/settings.json)"
}
Select-Profile

# ---------- merge presets ----------
if (-not [string]::IsNullOrEmpty($Preset)) {
    $presetList = $Preset -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    foreach ($p in $presetList) {
        $presetSrc = Join-Path $PSScriptRoot "presets/$p"
        if (-not (Test-Path -LiteralPath $presetSrc -PathType Container)) {
            Write-Die "preset not found: $p (look in $(Join-Path $PSScriptRoot 'presets'))"
        }
        Write-Note "Merging preset/$p -> $Target/.claude + docs/"
        # preset layout mirrors install destinations:
        #   presets/<name>/agents/* -> .claude/agents/
        #   presets/<name>/rules/*  -> .claude/rules/
        #   presets/<name>/skills/* -> .claude/skills/
        #   presets/<name>/docs/*   -> docs/
        $pairs = @(
            @{ Sub = 'agents'; Dst = (Join-Path $Target '.claude/agents') },
            @{ Sub = 'rules';  Dst = (Join-Path $Target '.claude/rules')  },
            @{ Sub = 'skills'; Dst = (Join-Path $Target '.claude/skills') },
            @{ Sub = 'docs';   Dst = (Join-Path $Target 'docs')           }
        )
        foreach ($pair in $pairs) {
            $src = Join-Path $presetSrc $pair.Sub
            if (Test-Path -LiteralPath $src -PathType Container) {
                Copy-Tree -Src $src -Dst $pair.Dst
            }
        }
    }
}

# ---------- render placeholders ----------
function Invoke-Render {
    # Render Mustache placeholders in $Src. If $Src ends with .tmpl, also
    # rename (strip suffix). Otherwise edit in place.
    param([string]$Src)
    $dst = if ($Src.EndsWith('.tmpl')) { $Src.Substring(0, $Src.Length - 5) } else { $Src }
    if ($DryRun) {
        if ($Src -ne $dst) {
            Write-Host "  ~ $Src -> $dst (render + rename)"
        } else {
            Write-Host "  ~ $Src (in-place render)"
        }
        return
    }
    $content = Get-Content -LiteralPath $Src -Raw -ErrorAction Stop
    $brain = if ([string]::IsNullOrEmpty($Vars.BRAIN_PATH)) { '.claude/memory' } else { $Vars.BRAIN_PATH }
    $content = $content.Replace('{{PROJECT_NAME}}',    $Vars.PROJECT_NAME)
    $content = $content.Replace('{{PROJECT_SLUG}}',    $Vars.PROJECT_SLUG)
    $content = $content.Replace('{{AGENT_PREFIX}}',    $Vars.AGENT_PREFIX)
    $content = $content.Replace('{{TECH_STACK_DESC}}', $Vars.TECH_STACK_DESC)
    $content = $content.Replace('{{BRAIN_PATH}}',      $brain)
    $content = $content.Replace('{{TASK_ID_PREFIX}}',  $Vars.TASK_ID_PREFIX)

    # Write UTF-8 (no BOM) preserving the source's line endings as-is.
    # -Raw read preserves bytes; we use .NET to avoid Set-Content's BOM
    # quirks on PS 5.1.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($dst, $content, $utf8NoBom)
    if ($Src -ne $dst) {
        Remove-Item -LiteralPath $Src -Force
    }
}

Write-Note 'Rendering placeholders...'
# Pass 1: every *.tmpl gets rendered + renamed.
Get-ChildItem -LiteralPath $Target -Recurse -File -Force -Filter '*.tmpl' -ErrorAction SilentlyContinue | ForEach-Object {
    Invoke-Render -Src $_.FullName
}

# Pass 2: every other text file gets in-place placeholder substitution
# (only files that actually contain a {{...}} placeholder, for speed).
# Limit to .claude/, docs/, CLAUDE.md, and README.md so we never touch
# user-tracked code outside the workflow scope.
$placeholderRegex = '\{\{[A-Z_][A-Z_0-9]+\}\}'
$roots = @(
    (Join-Path $Target '.claude'),
    (Join-Path $Target 'docs'),
    (Join-Path $Target 'CLAUDE.md'),
    (Join-Path $Target 'README.md')
)
foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r)) { continue }
    if (Test-Path -LiteralPath $r -PathType Leaf) {
        if ($r -like '*.tmpl') { continue }
        $head = Get-Content -LiteralPath $r -Raw -ErrorAction SilentlyContinue
        if ($head -and $head -match $placeholderRegex) {
            Invoke-Render -Src $r
        }
        continue
    }
    Get-ChildItem -LiteralPath $r -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.FullName -like '*.tmpl') { return }
        # Quick scan — read content once. Skip files with no placeholder.
        try {
            $head = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop
        } catch { return }
        if ($head -match $placeholderRegex) {
            Invoke-Render -Src $_.FullName
        }
    }
}

# ---------- settings.json soft-merge ----------
# If the target had a pre-existing settings.json that looked customized
# (different from a fresh foundation render), preserve it. The foundation
# version becomes a side-by-side snippet for hand-merge.
# NOTE: ConvertTo-CanonicalJson must be defined before Invoke-SoftMergeSettings
# is *called*, but PowerShell registers function definitions at execution
# time, so we put the helper first.
function ConvertTo-CanonicalJson {
    # Deterministic JSON encoding: object keys sorted recursively; arrays
    # preserved in source order (hook arrays are order-sensitive).
    param($InputObject)
    if ($null -eq $InputObject) { return 'null' }
    if ($InputObject -is [bool]) { if ($InputObject) { return 'true' } else { return 'false' } }
    if ($InputObject -is [string]) { return ($InputObject | ConvertTo-Json -Compress) }
    if ($InputObject -is [int] -or $InputObject -is [long] -or $InputObject -is [double] -or $InputObject -is [decimal]) {
        return ($InputObject | ConvertTo-Json -Compress)
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $parts = @()
        foreach ($item in $InputObject) { $parts += (ConvertTo-CanonicalJson -InputObject $item) }
        return '[' + ($parts -join ',') + ']'
    }
    # PSCustomObject / hashtable: sort property names
    $props = @()
    if ($InputObject -is [System.Collections.IDictionary]) {
        $names = $InputObject.Keys | Sort-Object
        foreach ($n in $names) {
            $k = ($n | ConvertTo-Json -Compress)
            $v = ConvertTo-CanonicalJson -InputObject $InputObject[$n]
            $props += "${k}:$v"
        }
    } else {
        $names = $InputObject.PSObject.Properties.Name | Sort-Object
        foreach ($n in $names) {
            $k = ($n | ConvertTo-Json -Compress)
            $v = ConvertTo-CanonicalJson -InputObject ($InputObject.$n)
            $props += "${k}:$v"
        }
    }
    return '{' + ($props -join ',') + '}'
}

function Invoke-SoftMergeSettings {
    if ([string]::IsNullOrEmpty($StashPath)) { return }
    if (-not (Test-Path -LiteralPath $StashPath -PathType Leaf)) { return }
    $foundation = Join-Path $Target '.claude/settings.json'
    if ($DryRun) {
        Write-Note 'would soft-merge settings.json (snippet beside user copy)'
        return
    }
    # Compare stash (user) vs fresh foundation. Use canonicalized JSON
    # (deep-sort keys; preserve array order — array order matters because
    # hook execution follows it). Fall back to byte-equality if JSON parse
    # fails on either side.
    $equal = $false
    try {
        $userObj  = Get-Content -LiteralPath $StashPath  -Raw | ConvertFrom-Json -ErrorAction Stop
        $foundObj = Get-Content -LiteralPath $foundation -Raw | ConvertFrom-Json -ErrorAction Stop
        $userCanon  = ConvertTo-CanonicalJson -InputObject $userObj
        $foundCanon = ConvertTo-CanonicalJson -InputObject $foundObj
        if ($userCanon -ceq $foundCanon) { $equal = $true }
    } catch {
        try {
            $a = Get-FileHash -LiteralPath $StashPath  -Algorithm SHA256
            $b = Get-FileHash -LiteralPath $foundation -Algorithm SHA256
            if ($a.Hash -eq $b.Hash) { $equal = $true }
        } catch { $equal = $false }
    }
    if ($equal) { return }
    # Non-trivial differences -> preserve user copy, write foundation as snippet.
    Move-Item -LiteralPath $foundation -Destination (Join-Path $Target '.claude/settings.foundation.json') -Force
    Copy-Item -LiteralPath $StashPath -Destination $foundation -Force
    Write-Warn 'settings.json had customizations — preserved user version.'
    Write-Warn 'Foundation hooks + permissions written to:'
    Write-Warn "    $(Join-Path $Target '.claude/settings.foundation.json')"
    Write-Warn 'Merge manually (the hook block is what is new — see docs/setup/settings-merge.md).'
}

Invoke-SoftMergeSettings

# ---------- placeholder lint (verify nothing left) ----------
if (-not $DryRun) {
    $leftover = @()
    Get-ChildItem -LiteralPath $Target -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $c = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop
        } catch { return }
        if ($c -match '\{\{[A-Z_]{2,}\}\}') {
            $leftover += $_.FullName
        }
    }
    if ($leftover.Count -gt 0) {
        Write-Warn 'unrendered placeholders remain in:'
        foreach ($f in $leftover) { Write-Host "   $f" }
        Write-Warn '(probably a new var added to a .tmpl but not to install.ps1 — patch the Invoke-Render block)'
    }
}

# ---------- write install manifest ----------
# Drift control: record what got installed where + which template commit
# produced it. The `diff` subcommand reads this back. Placeholder VALUES
# beyond the public placeholders are deliberately NOT recorded.
function Write-Manifest {
    if ($DryRun) {
        Write-Note "would write manifest: $(Join-Path $Target '.ai-workflows/manifest.json')"
        return
    }
    $manifestDir = Join-Path $Target '.ai-workflows'
    if (-not (Test-Path -LiteralPath $manifestDir)) {
        New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
    }
    $manifest = Join-Path $manifestDir 'manifest.json'
    # ISO8601 UTC — use InvariantCulture so non-Gregorian locales
    # (e.g. Thai Buddhist) don't shift the year by ~543 years.
    $installDate = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    $sourceCommit = ''
    try {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            $sourceCommit = (& git -C $PSScriptRoot rev-parse --short HEAD 2>$null)
            if ($null -eq $sourceCommit) { $sourceCommit = '' }
            $sourceCommit = $sourceCommit.Trim()
        }
    } catch { $sourceCommit = '' }

    # Force array typing — PS 5.1's ConvertTo-Json renders a single-element
    # pipeline as a bare value, and an empty array as "". Wrap explicitly.
    $presetsArr = [System.Collections.ArrayList]@()
    if (-not [string]::IsNullOrEmpty($Preset)) {
        foreach ($p in ($Preset -split ',')) {
            $t = $p.Trim()
            if ($t -ne '') { [void]$presetsArr.Add($t) }
        }
    }

    $obj = [ordered]@{
        version       = if ([string]::IsNullOrEmpty($AiwfVersion)) { 'unknown' } else { $AiwfVersion }
        install_date  = $installDate
        source_commit = $sourceCommit
        profile       = $Profile
        presets       = @($presetsArr)
        placeholders  = [ordered]@{
            PROJECT_NAME    = $Vars.PROJECT_NAME
            PROJECT_SLUG    = $Vars.PROJECT_SLUG
            AGENT_PREFIX    = $Vars.AGENT_PREFIX
            TASK_ID_PREFIX  = $Vars.TASK_ID_PREFIX
            TECH_STACK_DESC = $Vars.TECH_STACK_DESC
            BRAIN_PATH_SET  = (-not [string]::IsNullOrEmpty($Vars.BRAIN_PATH))
        }
    }
    $json = $obj | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($manifest, $json, $utf8NoBom)
    Write-Ok "wrote manifest: $manifest"
}
Write-Manifest

# ---------- next steps ----------
Write-Host ''
Write-Ok 'install complete.'
Write-Host ''
Write-Note 'Next steps:'
@"
  1. cd "$Target"
  2. Edit docs/spec/STATUS.md — set your first sprint
  3. Append project-specific rules to .claude/rules/brain-hot.md
     (add your A001, A002, ... local rules section)
  4. Edit CLAUDE.md — fill in the dispatch-routing table for your stack
  5. Open Claude Code in the project, then try:
        /next-task        — pick something to work on
        /design-review    — UI fidelity gate (if you ship UI)
        /retro            — sprint close + audit
"@ | Write-Host

if (-not [string]::IsNullOrEmpty($Vars.BRAIN_PATH)) {
    Write-Note "External Brain wired: $($Vars.BRAIN_PATH) (see brain-hot.md footer)"
} else {
    Write-Note 'In-repo Brain enabled: .claude/memory/ (set BRAIN_PATH later to switch)'
}

}
finally {
    # Trap-equivalent cleanup — reap the stash on any exit path.
    if (-not [string]::IsNullOrEmpty($StashPath) -and (Test-Path -LiteralPath $StashPath -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $StashPath -Force -ErrorAction SilentlyContinue
    }
}
