# Git helper for a normal checkout or linked Git worktree.
# Resolve the managed file itself, not $HOME or the current working directory.
# Stow --no-folding links files individually, leaving directories real.
$DotfilesHelper = Get-Item -LiteralPath $PSCommandPath -Force -ErrorAction Stop

for ($DotfilesDepth = 0; $DotfilesHelper.LinkType -eq "SymbolicLink"; $DotfilesDepth++) {
    if ($DotfilesDepth -ge 32) {
        throw "dotfiles: too many symbolic links while resolving the helper."
    }

    $DotfilesLinkTarget = @($DotfilesHelper.Target)[0]
    if ([string]::IsNullOrWhiteSpace($DotfilesLinkTarget)) {
        throw "dotfiles: the helper's symbolic link has no target."
    }
    if (-not [System.IO.Path]::IsPathRooted($DotfilesLinkTarget)) {
        $DotfilesLinkTarget = Join-Path $DotfilesHelper.DirectoryName $DotfilesLinkTarget
    }
    $DotfilesHelper = Get-Item -LiteralPath $DotfilesLinkTarget -Force -ErrorAction Stop
}

# <repository>/powershell/.config/powershell/50-dotfiles.ps1
$DotfilesRepositoryCandidate = $DotfilesHelper.Directory.Parent.Parent.Parent.FullName
if (-not $DotfilesRepositoryCandidate -or
    -not (Test-Path -LiteralPath (Join-Path $DotfilesRepositoryCandidate ".git"))) {
    throw "dotfiles: expected a normal checkout or worktree; deploy this helper with Stow --no-folding."
}
$global:DotfilesRepository = $DotfilesRepositoryCandidate

function global:dot {
    & git -C $global:DotfilesRepository @args
}
