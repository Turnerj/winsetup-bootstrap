<#
    Installs PowerShell 7, Git and GitHub CLI, sets the git identity, then
    clones the private winsetup-core repo (the actual setup content) and hands
    off to its run.ps1. Along with bootstrap.ps1 this is the only thing that's
    public - it reveals nothing else about what gets installed/configured.

    Started by bootstrap.ps1 in an administrator window, which downloads it and
    runs it with iex - so it never calls `exit` (that would close the window
    before its output could be read).

    This is intentionally the only script written to work on the Windows
    PowerShell 5.1 that ships with Windows - everything after this point
    assumes PowerShell 7 is available.

    No -WhatIf here - bootstrapping (installing prerequisites, cloning) has
    no meaningful preview of its own. Once winsetup-core is cloned, run
    .\run.ps1 -WhatIf directly in that folder to preview configuration
    changes.
#>

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This needs an administrator window - run bootstrap.ps1 instead."
}

$coreRepo = 'Turnerj/winsetup-core'
$coreDestination = Join-Path $env:USERPROFILE 'Documents\winsetup-core'

function Write-Status {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

Write-Status "[1/5] Checking prerequisites..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget was not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
}

Write-Status "[2/5] Installing PowerShell 7..."
winget install --id Microsoft.PowerShell -e --source winget --silent --accept-package-agreements --accept-source-agreements
switch ($LASTEXITCODE) {
    0 { Write-Status "PowerShell 7 installed." -Color Green }
    # Observed winget exit code for "already installed, nothing to upgrade".
    -1978335189 { Write-Status "PowerShell 7 already up to date." -Color Green }
    default { Write-Warning "winget exited with code $LASTEXITCODE installing PowerShell 7 - check the output above." }
}

Write-Status "[3/5] Enabling 'winget configure' (required for run.ps1)..."
winget configure --enable
if ($LASTEXITCODE -eq 0) {
    Write-Status "'winget configure' enabled." -Color Green
}
else {
    Write-Warning "winget exited with code $LASTEXITCODE enabling 'winget configure' - check the output above."
}

Write-Status "[4/5] Installing Git and GitHub CLI..."
# gh repo clone shells out to the system git binary - it doesn't bundle its own,
# and winget's GitHub.cli package declares no dependency on it, so it has to be
# installed explicitly here before the clone below.
winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Warning "winget exited with code $LASTEXITCODE installing Git - check the output above."
}
winget install --id GitHub.cli -e --source winget --silent --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    Write-Warning "winget exited with code $LASTEXITCODE installing GitHub CLI - check the output above."
}

# Both installers just updated the system/user PATH via the registry, which
# this already-running process never re-reads on its own. Without refreshing
# it here, gh.exe would be invisible not just to this script but to any child
# process it spawns - including gh's own internal shell-out to git for clone/
# push/pull, which no amount of resolving gh.exe's own path would fix.
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path = @($machinePath, $userPath) -join ';'

Write-Status "Setting git identity..."
git config --global user.name 'Turnerj'
git config --global user.email 'git@turnerj.com'

$ghCommand = Get-Command gh.exe -ErrorAction SilentlyContinue
if (-not $ghCommand) {
    Write-Warning "Could not find gh.exe after install. Open a new terminal and re-run this script."
    return
}
$ghPath = $ghCommand.Source

Write-Status "[5/5] Checking GitHub authentication..."
& $ghPath auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Status "Not logged into GitHub yet - launching 'gh auth login' (follow the browser prompt)..." -Color Yellow
    & $ghPath auth login --git-protocol https --web
    if ($LASTEXITCODE -ne 0) {
        Write-Error "GitHub authentication failed or was cancelled."
    }
    Write-Status "Authenticated with GitHub." -Color Green
}
else {
    Write-Status "Already authenticated with GitHub." -Color Green
}

if (Test-Path $coreDestination) {
    Write-Status "$coreDestination already exists - not re-cloning. Delete it first if you want a fresh clone." -Color Yellow
}
else {
    Write-Status "Cloning $coreRepo to $coreDestination..."
    & $ghPath repo clone $coreRepo $coreDestination
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone $coreRepo - check the output above."
    }
}

# run.ps1 handles finding PowerShell 7 and running the setup from there.
# Windows PowerShell 5.1 blocks script files by default, so bypass the
# policy for this one process.
Write-Status "Handing off to run.ps1 in winsetup-core..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $coreDestination 'run.ps1')
