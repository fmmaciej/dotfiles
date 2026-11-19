# Run with pwsh -NoProfile -File tests/powershell/Test-Dotfiles.ps1.
# Fixtures contain only the Git helper, mock commands, and synthetic files.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Source = Join-Path $Repository "powershell/.config/powershell/50-dotfiles.ps1"

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$ParseFiles = @(Get-ChildItem -LiteralPath $Repository -Recurse -File -Filter '*.ps1' | ForEach-Object FullName)
foreach ($File in $ParseFiles) {
    $Tokens = $null
    $ParseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($File, [ref] $Tokens, [ref] $ParseErrors)
    Assert-True ($ParseErrors.Count -eq 0) "PowerShell syntax error in $File"
}

$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-test-" + [guid]::NewGuid().ToString("N"))
$SavedLocation = Get-Location
$script:GitArguments = @()
$script:MockGitExit = 0
function global:git {
    $script:GitArguments = @($args)
    $global:LASTEXITCODE = $script:MockGitExit
}

try {
    $Repo = Join-Path $Fixture "repo with spaces"
    $HelperDir = Join-Path $Repo "powershell/.config/powershell"
    $Other = Join-Path $Fixture "some other directory"
    $HomeDir = Join-Path $Fixture "synthetic home/.config/powershell"
    New-Item -ItemType Directory -Path $HelperDir, $Other, $HomeDir | Out-Null
    $Helper = Join-Path $HelperDir "50-dotfiles.ps1"
    Copy-Item -LiteralPath $Source -Destination $Helper

    # A linked Git worktree has a .git file rather than a directory.
    Set-Content -LiteralPath (Join-Path $Repo ".git") -Value "gitdir: synthetic-not-read"
    Set-Location -LiteralPath $Other
    . $Helper
    dot status --short "two words"
    Assert-True ($script:GitArguments.Count -eq 5) "dot changed the argument count"
    Assert-True ($script:GitArguments[0] -eq "-C") "dot did not use git -C"
    Assert-True ($script:GitArguments[1] -eq $Repo) "dot chose the wrong repository"
    Assert-True ($script:GitArguments[2] -eq "status") "dot changed the command"
    Assert-True ($script:GitArguments[3] -eq "--short") "dot changed an option"
    Assert-True ($script:GitArguments[4] -eq "two words") "dot split an argument containing spaces"
    Assert-True ((Get-Location).Path -eq $Other) "dot changed the caller's directory"

    $script:MockGitExit = 7
    dot status
    Assert-True ($LASTEXITCODE -eq 7) "dot did not preserve Git's exit code"
    $script:MockGitExit = 0

    # Also support ordinary checkouts, whose .git is a directory.
    Remove-Item -LiteralPath (Join-Path $Repo ".git") -Force
    New-Item -ItemType Directory -Path (Join-Path $Repo ".git") | Out-Null
    . $Helper
    dot status
    Assert-True ($script:GitArguments[1] -eq $Repo) "ordinary checkout detection failed"

    foreach ($Relative in @($false, $true)) {
        $Name = if ($Relative) { "relative.ps1" } else { "absolute.ps1" }
        $Link = Join-Path $HomeDir $Name
        $Target = if ($Relative) { [System.IO.Path]::GetRelativePath($HomeDir, $Helper) } else { $Helper }
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
        . $Link
        dot status
        Assert-True ($script:GitArguments[1] -eq $Repo) "helper did not resolve its source through a symlink"
    }

    # A global helper must also retain its root when called from another script.
    # That caller has a different script scope, so a $script:-scoped root is wrong.
    $Caller = Join-Path $Other 'caller.ps1'
    Set-Content -LiteralPath $Caller -Value @'
function git { $args }
dot status
'@
    $CallerArguments = @(& $Caller)
    Assert-True ($CallerArguments[0] -eq '-C' -and $CallerArguments[1] -eq $Repo) 'dot lost its source root in another script scope'

    $Standalone = Join-Path $Other "standalone.ps1"
    Copy-Item -LiteralPath $Source -Destination $Standalone
    $Rejected = $false
    try { . $Standalone } catch { $Rejected = $true }
    Assert-True $Rejected "a copied helper outside a repository should be rejected"

    foreach ($Retired in @("dot-code", "dot-sync", "dot-help", "New-DotfilesViewLink")) {
        Assert-True (-not (Get-Command -Name $Retired -ErrorAction SilentlyContinue)) "retired helper was recreated: $Retired"
    }
    Write-Output "PASS: syntax, direct checkout, Git worktree, argument forwarding, exit code, caller directory, absolute/relative symlinks, invalid placement, retired helpers"
} finally {
    Set-Location -LiteralPath $SavedLocation.Path
    if (Test-Path -LiteralPath $Fixture) {
        Remove-Item -LiteralPath $Fixture -Recurse -Force
    }
}
