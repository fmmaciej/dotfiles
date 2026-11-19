# Development-only mocked checks. Does not install tools, access the network,
# load the user's profile, or deploy to the real HOME. Not a health checker.
$ErrorActionPreference = 'Stop'
$Repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $Repository 'scripts/windows/tools.ps1')
. (Join-Path $Repository 'scripts/windows/dotfiles.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$Fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-bootstrap-test-' + [guid]::NewGuid().ToString('N'))
$OriginalHome = $HOME
$OriginalScoop = $env:SCOOP
$OriginalPath = $env:PATH
$OriginalThemeBg = $env:THEME_BG
$OriginalThemeAccent = $env:THEME_ACCENT
$OriginalPsmuxSession = $env:PSMUX_TARGET_SESSION
$OriginalLocation = Get-Location
$script:ScoopCalls = [Collections.Generic.List[string]]::new()
$script:ScoopPaths = @{}
$script:ScoopFailure = ''
$script:GitCalls = [Collections.Generic.List[string]]::new()
$global:DotfilesTestThemeOptions = @{}
try {
    New-Item -ItemType Directory -Path $Fixture | Out-Null
    Set-Variable -Name HOME -Value (Join-Path $Fixture 'home with spaces') -Force
    $env:SCOOP = Join-Path $Fixture 'scoop with spaces'
    New-Item -ItemType Directory -Path $HOME, $env:SCOOP | Out-Null

    function global:scoop {
        $script:ScoopCalls.Add($args -join ' ')
        $global:LASTEXITCODE = 0
        if (($args -join ' ') -eq $script:ScoopFailure) {
            $global:LASTEXITCODE = 1
            return
        }
        if ($args[0] -eq 'prefix') {
            if ($script:ScoopPaths.ContainsKey($args[1])) { return $script:ScoopPaths[$args[1]] }
            $global:LASTEXITCODE = 1
            return
        }
        if ($args[0] -eq 'install') {
            $Directory = Join-Path $env:SCOOP "apps/$($args[1])/synthetic-version"
            New-Item -ItemType Directory -Path $Directory -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $Directory 'scoop-manifest.json') -Value '{}'
            $script:ScoopPaths[$args[1]] = $Directory
        } elseif ($args[0] -eq 'update') {
            Assert-True ($script:ScoopPaths.ContainsKey($args[1])) 'Only installed packages should be updated'
        } elseif ($args[0] -eq 'bucket') {
            New-Item -ItemType Directory -Path (Join-Path $env:SCOOP 'buckets/extras') -Force | Out-Null
        } else {
            throw 'Unexpected Scoop command'
        }
    }
    Ensure-Scoop
    Ensure-WindowsTools
    Assert-True (@($script:ScoopCalls | Where-Object { $_ -like 'install *' }).Count -eq 17) 'Expected 17 missing packages to be installed'
    Assert-True (@($script:ScoopCalls | Where-Object { $_ -like 'update *' }).Count -eq 0) 'New packages do not need another update'
    Assert-True (@($script:ScoopCalls | Where-Object { $_ -eq 'bucket add extras' }).Count -eq 1) 'Expected one extras bucket addition'
    $script:ScoopCalls.Clear()
    Ensure-WindowsTools
    Assert-True (@($script:ScoopCalls | Where-Object { $_ -like 'update *' }).Count -eq 17) 'Rerun must ask Scoop to update all existing packages, including already current ones'
    Assert-True (@($script:ScoopCalls | Where-Object { $_ -like 'install *' -or $_ -like 'bucket *' }).Count -eq 0) 'Rerun must not reinstall packages or re-add extras'

    # Existing installations need neither a legacy manifest nor a current junction.
    $MsysPath = Join-Path $Fixture 'existing MSYS2 with spaces'
    New-Item -ItemType Directory -Path $MsysPath | Out-Null
    $script:ScoopPaths['msys2'] = $MsysPath
    $script:ScoopCalls.Clear()
    Ensure-ScoopPackage msys2
    Assert-True (($script:ScoopCalls -join '|') -eq 'prefix msys2|update msys2') 'Existing MSYS2 must be updated without checking manifest.json'
    Assert-True ((Invoke-Scoop -Arguments @('prefix', 'msys2')) -eq $MsysPath) 'Use the installation path returned by Scoop, preserving spaces'

    foreach ($Case in @(
        @{ Name = 'msys2'; Command = 'update msys2' },
        @{ Name = 'missing-package'; Command = 'install missing-package' }
    )) {
        $script:ScoopFailure = $Case.Command
        $script:ScoopCalls.Clear()
        $Rejected = $false
        try { Ensure-ScoopPackage $Case.Name } catch {
            $Rejected = $_.Exception.Message -eq "Scoop failed: $($Case.Command)"
        }
        Assert-True $Rejected 'Install/update failures must stop bootstrap'
        Assert-True (($script:ScoopCalls -join '|') -eq "prefix $($Case.Name)|$($Case.Command)") 'A failed update must not fall back to reinstalling'
    }
    $script:ScoopFailure = ''

    $Checkout = Join-Path $Fixture 'checkout with spaces'
    New-Item -ItemType Directory -Path (Join-Path $Checkout '.git') -Force | Out-Null
    foreach ($Relative in @('bootstrap.ps1', 'scripts/windows/tools.ps1', 'scripts/windows/dotfiles.ps1', 'tmux/.tmux.conf')) {
        $File = Join-Path $Checkout $Relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $File) -Force | Out-Null
        Set-Content -LiteralPath $File -Value '# synthetic'
    }
    $script:FakeTop = $Checkout
    $script:FakeOrigin = 'https://github.com/fmmaciej/dotfiles.git'
    $script:FakeHead = 'a' * 40
    function global:git {
        $script:GitCalls.Add($args -join ' ')
        $global:LASTEXITCODE = 0
        if ($args[0] -ne '-C') { throw 'Unexpected mutating Git invocation' }
        if ($args[2] -notin @('rev-parse', 'remote')) { throw 'Unexpected mutating Git command' }
        if ($args[2] -eq 'remote') { return $script:FakeOrigin }
        if ($args[3] -eq 'HEAD') { return $script:FakeHead }
        return $script:FakeTop
    }
    $Result = Ensure-DotfilesCheckout -Path $Checkout -Revision $script:FakeHead
    Assert-True ($Result -eq $Checkout) 'Existing checkout was not preserved'
    $Rejected = $false
    try { Ensure-DotfilesCheckout -Path $Checkout -Revision ('b' * 40) } catch { $Rejected = $true }
    Assert-True $Rejected 'Revision mismatch must stop without resetting the checkout'
    foreach ($Origin in @(
        'https://github.com/fmmaciej/dotfiles.git',
        'https://github.com/fmmaciej/dotfiles',
        'https://github.com:443/fmmaciej/dotfiles.git/',
        'git@github.com:fmmaciej/dotfiles.git',
        'git@github.com:fmmaciej/dotfiles',
        'ssh://git@github.com/fmmaciej/dotfiles.git',
        'ssh://git@github.com:22/fmmaciej/dotfiles',
        'https://GITHUB.COM/FMMACIEJ/DOTFILES.git'
    )) {
        $script:FakeOrigin = $Origin
        $Result = Ensure-DotfilesCheckout -Path $Checkout
        Assert-True ($Result -eq $Checkout) "Valid origin was rejected: $Origin"
    }
    foreach ($Origin in @(
        'https://github.com/other/repo.git',
        'https://notgithub.com/fmmaciej/dotfiles.git',
        'https://github.com.example.org/fmmaciej/dotfiles.git',
        'git@notgithub.com:fmmaciej/dotfiles.git',
        'ssh://git@notgithub.com/fmmaciej/dotfiles.git',
        'https://github.com@example.org/fmmaciej/dotfiles.git',
        'https://example.org/github.com/fmmaciej/dotfiles.git',
        'https://github.com/fmmaciej/other.git',
        'https://github.com/fmmaciej/dotfiles.git.extra',
        'https://github.com/fmmaciej/dotfiles.git?extra',
        'https://github.com/fmmaciej/dotfiles.git#extra',
        'http://github.com/fmmaciej/dotfiles.git',
        'https://github.com:444/fmmaciej/dotfiles.git',
        'prefix https://github.com/fmmaciej/dotfiles.git',
        "https://github.com/fmmaciej/dotfiles.git`n"
    )) {
        $script:FakeOrigin = $Origin
        $Rejected = $false
        try { Ensure-DotfilesCheckout -Path $Checkout } catch {
            $Rejected = $_.Exception.Message -like 'Existing checkout has a different origin*'
        }
        Assert-True $Rejected "Foreign or malformed origin must be rejected: $Origin"
    }

    # Capture the deployment command rather than invoking MSYS2 or Stow.
    function Invoke-Msys {
        param([string] $MsysRoot, [string] $Command, [string[]] $Arguments)
        $script:DeployCommand = $Command
        $script:DeployArguments = $Arguments
    }
    Install-DotfilesLinks -Repository $Checkout -MsysRoot 'synthetic'
    Assert-True ($script:DeployArguments[0] -eq $Checkout -and $script:DeployArguments[1] -eq $HOME) 'Stow paths were changed/split'
    Assert-True ($script:DeployCommand.IndexOf('--simulate') -lt $script:DeployCommand.LastIndexOf('stow --dir')) 'Dry-run must precede apply'
    Assert-True ($script:DeployCommand -match 'set -e' -and $script:DeployCommand -notmatch '--adopt|--override') 'Conflicts must stop deployment'

    foreach ($Name in @('ppm', 'psmux-logging')) {
        $Directory = Join-Path $HOME ".psmux/plugins/$Name"
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Directory "$Name.ps1") -Value '# synthetic - never run'
    }
    # Existing plugins take the no-network path and must remain byte-for-byte.
    Install-PsmuxPlugins
    foreach ($Name in @('vim-airline', 'vim-airline-themes', 'vim-code-dark', 'vim-surround', 'nerdtree')) {
        New-Item -ItemType Directory -Path (Join-Path $HOME "vimfiles/plugged/$Name/.git") -Force | Out-Null
    }
    function global:vim { throw 'Existing plugins must not trigger Vim or network access' }
    Install-VimPlugins

    # Only synthetic modules are sourced; the real profile/history is never read.
    $ModuleDirectory = Join-Path $HOME '.config/powershell'
    New-Item -ItemType Directory -Path $ModuleDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $ModuleDirectory '20-second.ps1') -Value '$global:DotfilesTestLoaded += "20"'
    Set-Content -LiteralPath (Join-Path $ModuleDirectory '10-first.ps1') -Value '$global:DotfilesTestLoaded += "10"'
    Set-Content -LiteralPath (Join-Path $ModuleDirectory 'unmanaged.ps1') -Value 'throw "Unnumbered local file must not run"'
    $global:DotfilesTestLoaded = @()
    . (Join-Path $Repository 'powershell/.config/powershell/profile.ps1')
    . (Join-Path $Repository 'powershell/.config/powershell/profile.ps1')
    Assert-True (($global:DotfilesTestLoaded -join ',') -eq '10,20') 'Loader must use numbered order exactly once'

    $global:DotfilesTestYaziDirectory = Join-Path $Fixture 'chosen directory with spaces'
    New-Item -ItemType Directory -Path $global:DotfilesTestYaziDirectory | Out-Null
    function global:yazi {
        $Position = [array]::IndexOf($args, '--cwd-file')
        [IO.File]::WriteAllText($args[$Position + 1], $global:DotfilesTestYaziDirectory + "`n")
    }
    . (Join-Path $Repository 'powershell/.config/powershell/40-aliases.ps1')
    y 'synthetic input with spaces'
    Assert-True ((Get-Location).Path -eq $global:DotfilesTestYaziDirectory) 'y did not keep the chosen directory'
    Set-Location -LiteralPath $OriginalLocation.Path

    function global:psmux {
        Assert-True ($args[0] -eq '-t' -and $args[1] -eq '=theme-fixture') 'Theme must pin the exact originating session'
        Assert-True ($args[2] -eq 'set-option') 'Unexpected psmux command in palette adapter'
        $global:DotfilesTestThemeOptions[$args[4]] = $args[5]
        $global:LASTEXITCODE = 0
    }
    $env:PSMUX_TARGET_SESSION = 'theme-fixture'
    $env:THEME_BG = '#123456'
    $env:THEME_ACCENT = 'invalid - must not become a command/style'
    & (Join-Path $Repository 'tmux/.tmux/themes/vscode-dark-modern/colors.ps1')
    Assert-True ($global:DotfilesTestThemeOptions['status-style'] -like '*bg=#123456') 'Theme ignored the exported WezTerm palette'
    Assert-True ($global:DotfilesTestThemeOptions['pane-active-border-style'] -eq 'fg=#007acc') 'Invalid color should use a safe fallback'

    # The availability checker only resolves names. Checked applications must
    # never run; git/vim above would reject an invocation here.
    function global:Get-Command {
        param([string] $Name, [object] $ErrorAction)
        if ($Name -ne $global:DotfilesTestMissingCommand) { [pscustomobject]@{ Name = $Name } }
    }
    $global:DotfilesTestMissingCommand = ''
    $Output = & (Join-Path $Repository 'scripts/check-tools.ps1')
    Assert-True ($LASTEXITCODE -eq 0 -and -not ($Output -match '^MISSING')) 'Complete availability check should pass'
    $global:DotfilesTestMissingCommand = 'sk'
    $Output = & (Join-Path $Repository 'scripts/check-tools.ps1')
    Assert-True ($LASTEXITCODE -eq 1 -and ($Output -match '^MISSING  sk ')) 'Missing-command check should fail with code 1'

    Write-Output 'PASS: mocked Scoop install/update/rerun and failures, checkout guards, dry-run ordering, existing plugins, loader, Yazi wrapper, shared palette and availability-only checker'
} finally {
    Set-Location -LiteralPath $OriginalLocation.Path
    Set-Variable -Name HOME -Value $OriginalHome -Force
    $env:SCOOP = $OriginalScoop
    $env:PATH = $OriginalPath
    $env:THEME_BG = $OriginalThemeBg
    $env:THEME_ACCENT = $OriginalThemeAccent
    $env:PSMUX_TARGET_SESSION = $OriginalPsmuxSession
    Remove-Variable -Scope Global -Name DotfilesTestThemeOptions, DotfilesTestMissingCommand, DotfilesTestLoaded, DotfilesTestYaziDirectory, DotfilesProfileLoaded -ErrorAction SilentlyContinue
    foreach ($Name in @('scoop', 'git', 'vim', 'yazi', 'psmux', 'Get-Command')) {
        Remove-Item -LiteralPath "Function:global:$Name" -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -LiteralPath $Fixture -Recurse -Force }
}
