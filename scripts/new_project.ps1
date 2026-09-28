# new_project.ps1 - create a new Flutter app from project-template-app.
#
# One line, from any folder (Windows PowerShell 5.1+):
#
#   irm https://raw.githubusercontent.com/mohammeddaeh/project-template-app/master/scripts/new_project.ps1 | iex
#
# Without questions (every parameter is optional; a missing one is asked):
#
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/mohammeddaeh/project-template-app/master/scripts/new_project.ps1))) `
#       -Package zakat_app -Name "Zakat" -AppId com.awqaf.zakat -BaseUrl https://api.example.com -Preset simple
#
# The backend twin lives at the same path in project-template-backend - swap
# the repository name in the URL, nothing else.
#
# This file stays thin on purpose: check tools, clone, hand over. Every file
# edit lives in scripts/setup_project.dart, so there is one implementation, and
# it is the one a teammate can also run by hand.
#
# Kept ASCII-only: Windows PowerShell 5.1 reads a BOM-less local .ps1 as ANSI,
# and would garble any Arabic literal. The Dart side prints the Arabic.
#
# Never `exit` here: under `irm | iex` it would close the caller's window.

param(
    [string]$Package,
    [string]$Name,
    [string]$AppId,
    [string]$BaseUrl,
    [string]$BaseUrlStaging,
    [string]$BaseUrlProd,
    [ValidateSet('', 'simple', 'enterprise', 'custom')]
    [string]$Preset,
    [string]$Directory,
    [string]$Remote,
    [string]$Source = 'https://github.com/mohammeddaeh/project-template-app.git',
    [string]$Branch = 'master'
)

function Write-Step([string]$msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Warn2([string]$msg) { Write-Host "   !!  $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "`n   XX  $msg`n" -ForegroundColor Red }

function Read-Value([string]$prompt, [string]$default, [scriptblock]$validate) {
    while ($true) {
        $hint = if ($default) { " [$default]" } else { '' }
        $value = (Read-Host "?  $prompt$hint").Trim()
        if (-not $value) { $value = $default }
        $problem = & $validate $value
        if (-not $problem) { return $value }
        Write-Warn2 $problem
    }
}

$packageRule = {
    param($v)
    if ($v -cnotmatch '^[a-z][a-z0-9_]*$') { 'lowercase letters, digits and _ only, starting with a letter (e.g. zakat_app)' }
}
$appIdRule = {
    param($v)
    if ($v -cnotmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') { 'reverse-domain, lowercase, two segments at least (e.g. com.awqaf.zakat)' }
}
$requiredRule = { param($v) if (-not $v) { 'cannot be empty' } }
$urlRule = { param($v) if ($v -and $v -notmatch '^https?://') { 'must start with http:// or https:// (or leave empty)' } }
$presetRule = { param($v) if ($v -notin @('simple', 'enterprise', 'custom')) { 'simple, enterprise or custom' } }

function Test-Tool([string]$tool, [string]$hint) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Write-Ok $tool; return $true }
    Write-Fail "'$tool' not found on PATH. $hint"
    return $false
}

function Invoke-NewProject {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor DarkCyan
    Write-Host '  New app from project-template-app' -ForegroundColor DarkCyan
    Write-Host '============================================================' -ForegroundColor DarkCyan

    Write-Step 'Checking tools'
    if (-not (Test-Tool 'git' 'Install from https://git-scm.com')) { return }
    if (-not (Test-Tool 'flutter' 'Install Flutter and add it to PATH: https://docs.flutter.dev/get-started/install')) { return }
    if (-not (Test-Tool 'dart' 'It ships with Flutter - add flutter\bin to PATH.')) { return }

    Write-Step 'Project details'
    if (-not $Package) { $Package = Read-Value 'Dart package / folder name (e.g. zakat_app)' '' $packageRule }
    elseif (& $packageRule $Package) { Write-Fail "-Package: $(& $packageRule $Package)"; return }

    if (-not $Name) { $Name = Read-Value 'App display name' '' $requiredRule }

    if (-not $AppId) { $AppId = Read-Value 'Application ID' "com.company.$Package" $appIdRule }
    elseif (& $appIdRule $AppId) { Write-Fail "-AppId: $(& $appIdRule $AppId)"; return }

    if (-not $baseUrlGiven) {
        $BaseUrl = Read-Value 'BASE_URL for dev (empty = fill .env.dev.json later)' '' $urlRule
    }
    if (-not $Preset) { $Preset = Read-Value 'Optional modules: simple / enterprise / custom' 'simple' $presetRule }

    if (-not $Directory) { $Directory = Join-Path (Get-Location) $Package }
    $Directory = [System.IO.Path]::GetFullPath($Directory)
    if ((Test-Path $Directory) -and (Get-ChildItem -Force $Directory | Select-Object -First 1)) {
        Write-Fail "$Directory already exists and is not empty."
        return
    }

    Write-Step "Cloning $Source ($Branch)"
    git clone --depth 1 --branch $Branch $Source $Directory
    if ($LASTEXITCODE -ne 0) { Write-Fail 'git clone failed - see the output above.'; return }

    $templateRef = (git -C $Directory rev-parse --short HEAD).Trim()
    Remove-Item -Recurse -Force (Join-Path $Directory '.git')
    Write-Ok "template @ $templateRef - history dropped, the new project starts clean"

    Push-Location $Directory
    try {
        Write-Step 'Running scripts/setup_project.dart'
        $setupArgs = @(
            'run', 'scripts/setup_project.dart',
            '--name', $Name,
            '--app-id', $AppId,
            '--package', $Package,
            '--template-ref', $templateRef
        )
        if ($BaseUrl) { $setupArgs += @('--base-url', $BaseUrl) }
        if ($BaseUrlStaging) { $setupArgs += @('--base-url-staging', $BaseUrlStaging) }
        if ($BaseUrlProd) { $setupArgs += @('--base-url-prod', $BaseUrlProd) }
        # `custom` asks flag by flag inside the Dart script, so no --preset;
        # the answers above were already confirmed, so --yes skips the recap.
        if ($Preset -ne 'custom') { $setupArgs += @('--preset', $Preset) }
        $setupArgs += '--yes'

        dart @setupArgs
        $setupOk = $LASTEXITCODE -eq 0
        Write-Step 'Initial commit'
        git init --quiet
        git symbolic-ref HEAD refs/heads/master
        # A failed setup is not committed: the first commit should be a state
        # that passed the checks, not one somebody has to remember was broken.
        if ($setupOk) {
            git -c core.safecrlf=false add -A
            git commit --quiet -m "Initial commit from project-template-app@$templateRef"
            if ($LASTEXITCODE -eq 0) { Write-Ok 'committed' }
            else { Write-Warn2 'commit failed - set git user.name / user.email, then: git add -A; git commit' }
        }
        else {
            Write-Warn2 'setup_project failed (see above) - repository initialised, NOT committed. Fix, re-run the checks, then commit.'
        }

        if ($Remote) {
            git remote add origin $Remote
            Write-Ok "origin = $Remote  (push when ready: git push -u origin master)"
        }
    }
    finally {
        Pop-Location
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor DarkCyan
    if ($setupOk) { Write-Host "  Ready: $Directory" -ForegroundColor Green }
    else { Write-Host "  Created with failing checks: $Directory" -ForegroundColor Yellow }
    Write-Host '============================================================' -ForegroundColor DarkCyan
    Write-Host "  cd `"$Directory`""
    if (-not $BaseUrl) { Write-Host '  # put BASE_URL in .env.dev.json first' }
    Write-Host '  flutter run --flavor dev --dart-define-from-file=.env.dev.json'
    Write-Host '  Next: readme/00_START_HERE.md, phase 3.'
    Write-Host ''
}

# Captured here: inside the function $PSBoundParameters is its own, empty.
$baseUrlGiven = $PSBoundParameters.ContainsKey('BaseUrl')
Invoke-NewProject
