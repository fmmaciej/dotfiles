# Windows x64 bootstrap. Runs from a local checkout or directly through irm | iex.
[CmdletBinding()]
param(
    [string] $RepositoryPath = (Join-Path $HOME '.dotfiles'),
    [string] $Revision
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This bootstrap is for native Windows, not macOS, Linux or WSL.' }
if (-not [Environment]::Is64BitProcess -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this bootstrap in a 64-bit PowerShell on Windows x64.'
}
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
if ($Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Use a regular, non-administrator PowerShell. Scoop installs per user.'
}
$RepositoryPath = [System.IO.Path]::GetFullPath($RepositoryPath)
if ((Test-Path -LiteralPath $RepositoryPath) -and
    -not (Test-Path -LiteralPath (Join-Path $RepositoryPath '.git'))) {
    throw "Existing path is not a normal checkout/worktree: $RepositoryPath. Migrate a bare repo separately; nothing will be overwritten."
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$DownloadRoot = $null
try {
    $Source = $PSScriptRoot
    if (-not $Source) {
        # No Git is required to obtain the helper files. Pin the archive to one
        # commit so a branch update cannot mix helpers from different revisions.
        if (-not $Revision) {
            $Commit = Invoke-RestMethod 'https://api.github.com/repos/fmmaciej/dotfiles/commits/windows-next'
            $Revision = $Commit.sha
        }
        if ($Revision -notmatch '^[0-9a-f]{40}$') { throw 'Expected a full Git commit SHA.' }
        $DownloadRoot = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-bootstrap-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $DownloadRoot | Out-Null
        $Archive = Join-Path $DownloadRoot 'dotfiles.zip'
        Invoke-WebRequest "https://github.com/fmmaciej/dotfiles/archive/$Revision.zip" -UseBasicParsing -OutFile $Archive
        Expand-Archive -LiteralPath $Archive -DestinationPath $DownloadRoot
        $Source = Join-Path $DownloadRoot "dotfiles-$Revision"
    }

    . (Join-Path $Source 'scripts/windows/tools.ps1')
    Ensure-Scoop
    Ensure-ScoopPackage git
    Ensure-ScoopPackage pwsh
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $Pwsh = Join-Path (Get-ScoopRoot) 'apps/pwsh/current/pwsh.exe'
        $Parameters = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Source 'bootstrap.ps1'), '-RepositoryPath', $RepositoryPath)
        if ($Revision) { $Parameters += @('-Revision', $Revision) }
        & $Pwsh @Parameters
        if ($LASTEXITCODE -ne 0) { throw 'PowerShell 7 bootstrap failed; fix the reported problem and rerun.' }
        return
    }

    Ensure-WindowsTools
    . (Join-Path $Source 'scripts/windows/dotfiles.ps1')
    $Repository = Ensure-DotfilesCheckout -Path $RepositoryPath -Revision $Revision
    # Existing checkouts keep their own helpers and changes; no pull/reset/stash.
    . (Join-Path $Repository 'scripts/windows/tools.ps1')
    . (Join-Path $Repository 'scripts/windows/dotfiles.ps1')
    $MsysRoot = Join-Path (Get-ScoopRoot) 'apps/msys2/current'
    Assert-DotfilesHost
    Assert-NativeSymlinks
    Ensure-Stow -MsysRoot $MsysRoot
    Install-DotfilesLinks -Repository $Repository -MsysRoot $MsysRoot
    Install-PsmuxPlugins
    Install-VimPlugins
    & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repository 'scripts/check-tools.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Some tools are missing from PATH; see the availability check above.' }
    Write-Host 'Ready. Open WezTerm. SF Mono is optional and must be installed separately.'
} finally {
    # Only the exact disposable directory created by this invocation is removed.
    if ($DownloadRoot -and (Test-Path -LiteralPath $DownloadRoot)) {
        Remove-Item -LiteralPath $DownloadRoot -Recurse -Force
    }
}
