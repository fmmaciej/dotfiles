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
$script:BootstrapArguments = @()
$script:MockBootstrapExit = 0
$script:UpdateEvents = [Collections.Generic.List[string]]::new()
function global:git {
    $script:UpdateEvents.Add('git')
    $script:GitArguments = @($args)
    $global:LASTEXITCODE = $script:MockGitExit
}
function global:pwsh {
    $script:UpdateEvents.Add('bootstrap')
    $script:BootstrapArguments = @($args)
    $global:LASTEXITCODE = $script:MockBootstrapExit
}

function Test-DotUpdate {
    param([string] $Repo, [string] $CallerDirectory)
    $script:UpdateEvents.Clear()
    dot update
    Assert-True (($script:UpdateEvents -join ',') -eq 'git,bootstrap') 'dot update must pull before running bootstrap'
    Assert-True (($script:GitArguments -join '|') -eq "-C|$Repo|pull|--ff-only") 'dot update must fast-forward its own checkout'
    Assert-True ($script:BootstrapArguments.Count -eq 8) 'dot update changed the bootstrap argument count'
    Assert-True (($script:BootstrapArguments[0..4] -join '|') -eq '-NoLogo|-NoProfile|-ExecutionPolicy|Bypass|-File') 'Bootstrap must run in a clean PowerShell process'
    Assert-True ($script:BootstrapArguments[5] -eq (Join-Path $Repo 'bootstrap.ps1')) 'dot update chose the wrong bootstrap'
    Assert-True ($script:BootstrapArguments[6] -eq '-RepositoryPath' -and $script:BootstrapArguments[7] -eq $Repo) 'dot update must pass its checkout explicitly, preserving spaces'
    Assert-True ($LASTEXITCODE -eq 0) 'Successful update must return zero'
    Assert-True ((Get-Location).Path -eq $CallerDirectory) 'dot update changed the caller directory'

    $script:MockGitExit = 7
    $script:UpdateEvents.Clear()
    dot update
    Assert-True (($script:UpdateEvents -join ',') -eq 'git') 'A failed pull must not launch bootstrap'
    Assert-True ($LASTEXITCODE -eq 7) 'dot update lost the pull failure code'
    $script:MockGitExit = 0

    $script:MockBootstrapExit = 9
    dot update
    Assert-True ($LASTEXITCODE -eq 9) 'dot update lost the bootstrap failure code'
    $script:MockBootstrapExit = 0

    $script:UpdateEvents.Clear()
    $Rejected = $false
    try { dot update --unexpected } catch { $Rejected = $_.Exception.Message -eq 'Usage: dot update' }
    Assert-True ($Rejected -and $script:UpdateEvents.Count -eq 0) 'Unsupported update arguments must not be silently ignored or execute commands'
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
    Test-DotUpdate -Repo $Repo -CallerDirectory $Other

    # Also support ordinary checkouts, whose .git is a directory.
    Remove-Item -LiteralPath (Join-Path $Repo ".git") -Force
    New-Item -ItemType Directory -Path (Join-Path $Repo ".git") | Out-Null
    . $Helper
    dot status
    Assert-True ($script:GitArguments[1] -eq $Repo) "ordinary checkout detection failed"
    Test-DotUpdate -Repo $Repo -CallerDirectory $Other

    foreach ($Relative in @($false, $true)) {
        $Name = if ($Relative) { "relative.ps1" } else { "absolute.ps1" }
        $Link = Join-Path $HomeDir $Name
        $Target = if ($Relative) { [System.IO.Path]::GetRelativePath($HomeDir, $Helper) } else { $Helper }
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
        . $Link
        dot status
        Assert-True ($script:GitArguments[1] -eq $Repo) "helper did not resolve its source through a symlink"
        Test-DotUpdate -Repo $Repo -CallerDirectory $Other
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
    Write-Output "PASS: syntax, checkout/worktree, Git forwarding, dot update ordering/failure/paths, exit code, caller directory, symlinks, invalid placement, retired helpers"
} finally {
    Set-Location -LiteralPath $SavedLocation.Path
    Remove-Item -LiteralPath 'Function:global:git', 'Function:global:pwsh' -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Fixture) {
        Remove-Item -LiteralPath $Fixture -Recurse -Force
    }
}
