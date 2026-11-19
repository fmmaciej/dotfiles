function Ensure-DotfilesCheckout {
    param([string] $Path, [string] $Revision)
    if (-not (Test-Path -LiteralPath $Path)) {
        & git clone --branch windows-next https://github.com/fmmaciej/dotfiles.git $Path
        if ($LASTEXITCODE -ne 0) { throw 'Could not clone dotfiles. Any partial checkout has been left untouched.' }
    }
    $TopLevel = & git -C $Path rev-parse --show-toplevel
    if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($TopLevel) -ne [IO.Path]::GetFullPath($Path)) {
        throw "Not an ordinary checkout/worktree root: $Path"
    }
    $Origin = & git -C $Path remote get-url origin
    # Match the whole URL, not a suffix of a lookalike host. Accept standard
    # HTTPS and GitHub SSH forms (including their explicit default ports).
    $ExpectedOrigin = '\A(?:https://github\.com(?::443)?/|git@github\.com:|ssh://git@github\.com(?::22)?/)fmmaciej/dotfiles(?:\.git)?/?\z'
    if ($LASTEXITCODE -ne 0 -or $Origin -notmatch $ExpectedOrigin) {
        throw 'Existing checkout has a different origin; it will not be changed.'
    }
    if ($Revision) {
        $Head = & git -C $Path rev-parse HEAD
        if ($LASTEXITCODE -ne 0 -or $Head -ne $Revision) {
            throw 'Checkout and downloaded bootstrap revisions differ. Review/update the checkout manually, then run its local bootstrap.ps1. No pull/reset/stash was performed.'
        }
    }
    foreach ($Required in @('bootstrap.ps1', 'scripts/windows/tools.ps1', 'scripts/windows/dotfiles.ps1', 'tmux/.tmux.conf')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $Required))) {
            throw "Checkout is not the prepared Windows layout: missing $Required"
        }
    }
    return $Path
}

function Assert-DotfilesHost {
    $Documents = [Environment]::GetFolderPath('MyDocuments')
    $Expected = Join-Path $HOME 'Documents'
    if ([IO.Path]::GetFullPath($Documents) -ne [IO.Path]::GetFullPath($Expected)) {
        throw "Documents is redirected to $Documents. Review profile destinations before linking; no Documents directory will be replaced."
    }
    foreach ($OtherConfig in @('.psmux.conf', '.psmuxrc')) {
        if (Test-Path -LiteralPath (Join-Path $HOME $OtherConfig)) {
            throw "Existing $OtherConfig takes precedence over .tmux.conf. Review it before deployment."
        }
    }
}

function Assert-NativeSymlinks {
    $Probe = Join-Path $HOME ('.dotfiles-symlink-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $Probe | Out-Null
        $SourceFile = Join-Path $Probe 'source.txt'
        Set-Content -LiteralPath $SourceFile -Value 'symlink permission probe'
        New-Item -ItemType SymbolicLink -Path (Join-Path $Probe 'link.txt') -Target $SourceFile -ErrorAction Stop | Out-Null
    } catch {
        throw 'Native symlinks are unavailable. Enable Windows Developer Mode if allowed by your policy, then rerun. No elevation or link emulation will be used.'
    } finally {
        if (Test-Path -LiteralPath $Probe) { Remove-Item -LiteralPath $Probe -Recurse -Force }
    }
}

function Install-DotfilesLinks {
    param([string] $Repository, [string] $MsysRoot)
    $Deploy = @'
set -e
repo="$(cygpath -u "$1")"
target="$(cygpath -u "$2")"
packages=(common powershell starship tmux vim wezterm yazi)
stow --dir="$repo" --target="$target" --no-folding --simulate --verbose --restow "${packages[@]}"
stow --dir="$repo" --target="$target" --no-folding --verbose --restow "${packages[@]}"
'@
    Invoke-Msys -MsysRoot $MsysRoot -Command $Deploy -Arguments @($Repository, $HOME)
}

function Install-PsmuxPlugins {
    # Pin the native plugin source. Existing plugin directories are never updated
    # or overlaid by bootstrap; future updates are an explicit PPM action.
    $Commit = '3e94beff2159ee2c4dbb4180918930c328ab93c9'
    $Plugins = @('ppm', 'psmux-logging')
    $Missing = @()
    foreach ($Name in $Plugins) {
        $Destination = Join-Path $HOME ".psmux/plugins/$Name"
        if (Test-Path -LiteralPath $Destination) {
            if (-not (Test-Path -LiteralPath (Join-Path $Destination "$Name.ps1"))) {
                throw "Incomplete/existing plugin directory: $Destination. Review it manually; bootstrap will not overwrite it."
            }
        } else { $Missing += $Name }
    }
    if ($Missing.Count -eq 0) { return }
    $Temporary = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-plugins-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $Temporary | Out-Null
    try {
        $Archive = Join-Path $Temporary 'plugins.zip'
        Invoke-WebRequest "https://github.com/psmux/psmux-plugins/archive/$Commit.zip" -OutFile $Archive
        Expand-Archive -LiteralPath $Archive -DestinationPath $Temporary
        $PluginRoot = Join-Path $HOME '.psmux/plugins'
        New-Item -ItemType Directory -Path $PluginRoot -Force | Out-Null
        foreach ($Name in $Missing) {
            $Destination = Join-Path $PluginRoot $Name
            if (Test-Path -LiteralPath $Destination) { throw "Plugin destination appeared during setup: $Destination. Review it before rerunning." }
            Copy-Item -LiteralPath (Join-Path $Temporary "psmux-plugins-$Commit/$Name") -Destination $Destination -Recurse
        }
    } finally {
        Remove-Item -LiteralPath $Temporary -Recurse -Force
    }
}

function Install-VimPlugins {
    $Plugins = @('vim-airline', 'vim-airline-themes', 'vim-code-dark', 'vim-surround', 'nerdtree')
    foreach ($Name in $Plugins) {
        $Directory = Join-Path $HOME "vimfiles/plugged/$Name"
        if ((Test-Path -LiteralPath $Directory) -and -not (Test-Path -LiteralPath (Join-Path $Directory '.git'))) {
            throw "Existing unmanaged/incomplete Vim plugin directory: $Directory. Review it before rerunning."
        }
    }
    $Missing = @($Plugins | Where-Object { -not (Test-Path -LiteralPath (Join-Path $HOME "vimfiles/plugged/$_/.git")) })
    if ($Missing.Count -eq 0) { return }
    & vim -Nu (Join-Path $HOME '_vimrc') -i NONE -n -es -c 'PlugInstall --sync' -c 'qa!'
    if ($LASTEXITCODE -ne 0) { throw 'Vim plugin installation failed. Rerun :PlugInstall from Vim to inspect the error.' }
    foreach ($Name in $Plugins) {
        if (-not (Test-Path -LiteralPath (Join-Path $HOME "vimfiles/plugged/$Name/.git"))) {
            throw "Vim plugin is missing after PlugInstall: $Name"
        }
    }
}
