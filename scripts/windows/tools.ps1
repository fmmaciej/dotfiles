# Small bootstrap helpers. Scoop installs missing packages and updates existing ones.
function Get-ScoopRoot {
    if ($env:SCOOP) { return $env:SCOOP }
    $UserRoot = [Environment]::GetEnvironmentVariable('SCOOP', 'User')
    if ($UserRoot) { return $UserRoot }
    return (Join-Path $HOME 'scoop')
}

function Ensure-Scoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $Shims = Join-Path (Get-ScoopRoot) 'shims'
        if (Test-Path -LiteralPath (Join-Path $Shims 'scoop.ps1')) {
            $env:PATH = "$Shims;$env:PATH"
        } else {
            $Installer = Join-Path ([IO.Path]::GetTempPath()) ('scoop-install-' + [guid]::NewGuid().ToString('N') + '.ps1')
            try {
                Invoke-WebRequest 'https://get.scoop.sh' -UseBasicParsing -OutFile $Installer
                & $Installer
                if (-not $?) { throw 'Scoop installation failed.' }
            } finally {
                if (Test-Path -LiteralPath $Installer) { Remove-Item -LiteralPath $Installer -Force }
            }
        }
    }
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { throw 'Scoop is not available after installation.' }
}

function Invoke-Scoop {
    param([string[]] $Arguments)
    $global:LASTEXITCODE = 0
    & scoop @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Scoop failed: $($Arguments -join ' ')" }
}

function Ensure-ScoopPackage {
    param([string] $Name)
    $global:LASTEXITCODE = 0
    $null = & scoop prefix $Name 2>$null 6>$null
    $Action = if ($LASTEXITCODE -eq 0) { 'update' } else { 'install' }
    Invoke-Scoop -Arguments @($Action, $Name)
}

function Ensure-WindowsTools {
    foreach ($Name in @('git', 'pwsh', 'msys2', 'vim', 'starship', 'yazi', 'eza', 'skim', 'fd', 'bat', 'ripgrep', 'ffmpeg', '7zip', 'jq', 'poppler', 'psmux')) {
        Ensure-ScoopPackage $Name
    }
    if (-not (Test-Path -LiteralPath (Join-Path (Get-ScoopRoot) 'buckets/extras'))) {
        Invoke-Scoop -Arguments @('bucket', 'add', 'extras')
    }
    Ensure-ScoopPackage wezterm
    # New shims must be visible before the final availability check.
    $Shims = Join-Path (Get-ScoopRoot) 'shims'
    if (($env:PATH -split ';') -notcontains $Shims) { $env:PATH = "$Shims;$env:PATH" }
}

function Invoke-Msys {
    param([string] $MsysRoot, [string] $Command, [string[]] $Arguments = @())
    $SavedMsys = $env:MSYS
    $SavedSystem = $env:MSYSTEM
    $SavedPathType = $env:MSYS2_PATH_TYPE
    try {
        $env:MSYS = 'winsymlinks:nativestrict'
        $env:MSYSTEM = 'MSYS'
        $env:MSYS2_PATH_TYPE = 'strict'
        & (Join-Path $MsysRoot 'usr/bin/bash.exe') --login -c $Command dotfiles @Arguments
        if ($LASTEXITCODE -ne 0) { throw 'MSYS2 command failed. Resolve its error before rerunning bootstrap.' }
    } finally {
        $env:MSYS = $SavedMsys
        $env:MSYSTEM = $SavedSystem
        $env:MSYS2_PATH_TYPE = $SavedPathType
    }
}

function Ensure-Stow {
    param([string] $MsysRoot)
    if (-not (Test-Path -LiteralPath (Join-Path $MsysRoot 'usr/bin/stow'))) {
        # MSYS2 core upgrades can terminate the first shell. If that happens,
        # stop and rerun bootstrap; never continue after a partial upgrade.
        Invoke-Msys $MsysRoot 'pacman -Syu --noconfirm'
        Invoke-Msys $MsysRoot 'pacman -Syu --noconfirm && pacman -S --needed --noconfirm stow'
    }
    Invoke-Msys $MsysRoot 'for tool in bash perl stow cygpath; do command -v "$tool" >/dev/null || exit 1; done'
}
