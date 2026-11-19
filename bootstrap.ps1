# Windows x64 bootstrap. Runs from a local checkout or directly through irm | iex.
[CmdletBinding()]
param(
    [string] $RepositoryPath = (Join-Path $HOME '.dotfiles'),
    [string] $Revision
)

function Get-GitHubArchiveRevision {
    param([string] $Path)

    # GitHub ZIPs end with a 22-byte end-of-directory record and the full
    # commit SHA as a 40-byte comment. This also works in Windows PowerShell 5.1.
    $Stream = [IO.File]::OpenRead($Path)
    try {
        if ($Stream.Length -lt 62) { throw 'GitHub archive has no commit SHA.' }
        $null = $Stream.Seek(-62, [IO.SeekOrigin]::End)
        $Reader = New-Object IO.BinaryReader($Stream)
        $Tail = $Reader.ReadBytes(62)
    } finally {
        $Stream.Dispose()
    }
    $Commit = [Text.Encoding]::ASCII.GetString($Tail, 22, 40)
    if ([BitConverter]::ToUInt32($Tail, 0) -ne 0x06054b50 -or
        [BitConverter]::ToUInt16($Tail, 20) -ne 40 -or
        $Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'GitHub archive has no valid commit SHA.'
    }
    return $Commit
}

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
        # Obtain all helpers in one download, without Git or the GitHub API.
        if ($Revision -and $Revision -cnotmatch '^[0-9a-f]{40}$') { throw 'Expected a full Git commit SHA.' }
        $ArchiveRef = 'refs/heads/windows-next'
        $ArchiveDirectory = 'dotfiles-windows-next'
        if ($Revision) {
            $ArchiveRef = $Revision
            $ArchiveDirectory = "dotfiles-$Revision"
        }
        $DownloadRoot = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-bootstrap-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $DownloadRoot | Out-Null
        $Archive = Join-Path $DownloadRoot 'dotfiles.zip'
        Invoke-WebRequest "https://github.com/fmmaciej/dotfiles/archive/$ArchiveRef.zip" -UseBasicParsing -OutFile $Archive
        $ArchiveRevision = Get-GitHubArchiveRevision -Path $Archive
        if ($Revision -and $Revision -cne $ArchiveRevision) { throw 'GitHub archive revision does not match the requested commit.' }
        $Revision = $ArchiveRevision
        Expand-Archive -LiteralPath $Archive -DestinationPath $DownloadRoot
        $Source = Join-Path $DownloadRoot $ArchiveDirectory
        foreach ($Relative in @('bootstrap.ps1', 'scripts/windows/tools.ps1', 'scripts/windows/dotfiles.ps1')) {
            if (-not (Test-Path -LiteralPath (Join-Path $Source $Relative) -PathType Leaf)) {
                throw "GitHub archive is missing $Relative."
            }
        }
    }

    . (Join-Path $Source 'scripts/windows/tools.ps1')
    Ensure-Scoop
    Ensure-ScoopPackage git
    Ensure-ScoopPackage pwsh
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $Pwsh = Join-Path (Invoke-Scoop -Arguments @('prefix', 'pwsh')) 'pwsh.exe'
        $Parameters = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Source 'bootstrap.ps1'), '-RepositoryPath', $RepositoryPath)
        if ($Revision) { $Parameters += @('-Revision', $Revision) }
        & $Pwsh @Parameters
        if ($LASTEXITCODE -ne 0) { throw 'PowerShell 7 bootstrap failed; fix the reported problem and rerun.' }
        return
    }

    Ensure-WindowsTools
    Ensure-CompletionPredictor
    . (Join-Path $Source 'scripts/windows/dotfiles.ps1')
    $Repository = Ensure-DotfilesCheckout -Path $RepositoryPath -Revision $Revision
    # Existing checkouts keep their own helpers and changes; no pull/reset/stash.
    . (Join-Path $Repository 'scripts/windows/tools.ps1')
    . (Join-Path $Repository 'scripts/windows/dotfiles.ps1')
    $MsysRoot = Invoke-Scoop -Arguments @('prefix', 'msys2')
    Assert-DotfilesHost
    Assert-NativeSymlinks
    Ensure-Stow -MsysRoot $MsysRoot
    Install-DotfilesLinks -Repository $Repository -MsysRoot $MsysRoot
    Install-AtuinNushellIntegration
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
