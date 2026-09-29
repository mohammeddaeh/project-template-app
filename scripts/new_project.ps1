# new_project.ps1 - create a new Flutter app from project-template-app.
#
# One line, from any folder (Windows PowerShell 5.1+):
#
#   irm https://raw.githubusercontent.com/mohammeddaeh/project-template-app/master/scripts/new_project.ps1 | iex
#
# Without questions (every parameter is optional; a missing one is asked):
#
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/mohammeddaeh/project-template-app/master/scripts/new_project.ps1))) `
#       -Package zakat_app -Name "Zakat" -AppId com.awqaf.zakat -BaseUrl https://api.example.com -Preset simple `
#       -Remote awqaf/zakat_app
#
# -Remote (owner/name or URL) is pushed to once the checks pass. It must be an
# EMPTY repository; a missing one is created with GitHub CLI (`gh`) when present.
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

# git and gh print progress ("Cloning into...", "To https://...") on stderr.
# Windows PowerShell 5.1 renders stderr of a native command as a red
# NativeCommandError in several hosts (VS Code, ISE) - a successful clone then
# reads like a failure. Merged and printed as text; $LASTEXITCODE still decides.
# No param block on purpose: a declared parameter would swallow a native flag
# that happens to prefix-match its name.
function Invoke-Native {
    $exe, $rest = $args
    $ErrorActionPreference = 'Continue'
    & $exe @rest 2>&1 | ForEach-Object {
        # A blank stderr line stringifies to its type name, not to ''.
        $line = if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
        Write-Host "   $line"
    }
}

function Test-Tool([string]$tool, [string]$hint) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Write-Ok $tool; return $true }
    Write-Fail "'$tool' not found on PATH. $hint"
    return $false
}

# --- Push target -------------------------------------------------------------
# Asked BEFORE the clone and the long checks, and verified then: a wrong URL
# found after ten minutes of tests is a second run, found here it is a retype.
# Only an EMPTY repository is accepted - pushing a fresh history onto one that
# already has commits (a README ticked on GitHub counts) is refused anyway.

function ConvertTo-RepoUrl([string]$value) {
    if ($value -match '^[\w.-]+/[\w.-]+$') { return "https://github.com/$value.git" }
    return $value
}

function Get-RepoSlug([string]$url) {
    if ($url -match 'github\.com[:/]([\w.-]+/[\w.-]+?)(\.git)?/?$') { return $Matches[1] }
    return $null
}

function Read-PushTarget([string]$given) {
    $hasGh = [bool](Get-Command 'gh' -ErrorAction SilentlyContinue)
    while ($true) {
        $value = $given
        $given = $null
        if (-not $value) {
            $value = (Read-Host '?  GitHub repo to push to - owner/name or URL (empty = no push)').Trim()
        }
        if (-not $value) { return $null }
        $url = ConvertTo-RepoUrl $value

        $env:GIT_TERMINAL_PROMPT = '0'
        $refs = git ls-remote $url 2>$null
        $reachable = $LASTEXITCODE -eq 0
        Remove-Item Env:GIT_TERMINAL_PROMPT

        if ($reachable -and -not $refs) { Write-Ok "$url - exists and is empty"; return @{ Url = $url; Create = $false } }
        if ($reachable) { Write-Warn2 "$url already has commits - use a new, EMPTY repository (no README, no .gitignore)."; continue }

        $slug = Get-RepoSlug $url
        if ($hasGh -and $slug) {
            $answer = (Read-Host "?  $slug not found (or no access). Create it with gh? private / public / no [private]").Trim().ToLower()
            if (-not $answer) { $answer = 'private' }
            if ($answer -in @('private', 'public')) { return @{ Url = $url; Create = $true; Slug = $slug; Visibility = $answer } }
            continue
        }
        Write-Warn2 "$url not found or no access. Create it on GitHub first (empty: no README), then enter it again."
        if (-not $hasGh) { Write-Warn2 'Or install GitHub CLI (winget install GitHub.cli; gh auth login) and this script creates it for you.' }
    }
}

function Publish-Repo($target) {
    Write-Step "Pushing to $($target.Url)"
    if ($target.Create) {
        Invoke-Native gh repo create $target.Slug "--$($target.Visibility)" --source . --remote origin --push
    }
    else {
        git remote add origin $target.Url
        Invoke-Native git push -u origin master
    }
    if ($LASTEXITCODE -eq 0) { Write-Ok "pushed - $($target.Url)"; return $true }
    Write-Warn2 'push failed (see above). The commit is local; fix access, then: git push -u origin master'
    return $false
}

# Cloned into TEMP, then copied without .git - never cloned in place.
# Deleting .git after an in-place clone fails when anything holds it open:
# VS Code, open on the parent folder, sees the new repository and runs
# `git fetch` in it within seconds (FETCH_HEAD, tmp_pack_* locked). The old
# code then went on with the TEMPLATE's history still there, and the "initial"
# commit landed on top of it. A folder that never had a .git cannot keep one.
# Returns the template's short commit, or $null on failure.
function Copy-Template([string]$source, [string]$branch, [string]$target) {
    $staging = Join-Path ([System.IO.Path]::GetTempPath()) ('new_project_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    # Not piped, and --quiet: the pipe shows no progress anyway, so a long
    # clone looked frozen. Errors still print.
    git clone --quiet --depth 1 --branch $branch $source $staging
    if ($LASTEXITCODE -ne 0) { Write-Fail 'git clone failed - see the output above.'; return $null }

    $ref = (git -C $staging rev-parse --short HEAD).Trim()
    New-Item -ItemType Directory -Force $target | Out-Null
    Get-ChildItem -Force $staging | Where-Object { $_.Name -ne '.git' } |
        Copy-Item -Destination $target -Recurse -Force

    Remove-Item -Recurse -Force $staging -ErrorAction SilentlyContinue
    if (Test-Path $staging) { Write-Warn2 "temporary clone left at $staging (locked) - safe to delete later" }
    return $ref
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
    $pushTarget = Read-PushTarget $Remote

    if (-not $Directory) { $Directory = Join-Path (Get-Location) $Package }
    $Directory = [System.IO.Path]::GetFullPath($Directory)
    if ((Test-Path $Directory) -and (Get-ChildItem -Force $Directory | Select-Object -First 1)) {
        Write-Fail "$Directory already exists and is not empty."
        return
    }

    Write-Step "Cloning $Source ($Branch)"
    $templateRef = Copy-Template $Source $Branch $Directory
    if (-not $templateRef) { return }
    Write-Ok "template @ $templateRef - copied without its history, the new project starts clean"

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

        # Piped only when nothing is asked (`custom` asks flag by flag): a pipe
        # would hold back a prompt that does not end in a newline.
        if ($Preset -ne 'custom') { Invoke-Native dart @setupArgs } else { dart @setupArgs }
        $setupOk = $LASTEXITCODE -eq 0
        Write-Step 'Initial commit'
        # Last line of defence: a .git here is somebody else's history, and the
        # initial commit must not land on it.
        if (Test-Path .git) { Write-Fail "$Directory already has a .git - refusing to commit onto it."; return }
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

        $pushed = $false
        if ($pushTarget -and $setupOk) { $pushed = Publish-Repo $pushTarget }
        elseif ($pushTarget) { Write-Warn2 "not pushed to $($pushTarget.Url) - nothing committed yet" }
    }
    finally {
        Pop-Location
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor DarkCyan
    if ($setupOk) { Write-Host "  Ready: $Directory" -ForegroundColor Green }
    else { Write-Host "  Created with failing checks: $Directory" -ForegroundColor Yellow }
    Write-Host '============================================================' -ForegroundColor DarkCyan
    if ($pushed) { Write-Host "  GitHub: $($pushTarget.Url)" }
    Write-Host "  cd `"$Directory`""
    if (-not $BaseUrl) { Write-Host '  # put BASE_URL in .env.dev.json first' }
    Write-Host '  flutter run --flavor dev --dart-define-from-file=.env.dev.json'
    Write-Host '  Next: readme/00_START_HERE.md, phase 3.'
    Write-Host ''
}

# Captured here: inside the function $PSBoundParameters is its own, empty.
$baseUrlGiven = $PSBoundParameters.ContainsKey('BaseUrl')
Invoke-NewProject
