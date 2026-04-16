# Dotfiles helpers

$script:DotfilesGitDir = if ($env:DOTFILES_GIT_DIR) { $env:DOTFILES_GIT_DIR } else { Join-Path $HOME ".dotfiles" }
$script:DotfilesWorkTree = if ($env:DOTFILES_WORK_TREE) { $env:DOTFILES_WORK_TREE } else { $HOME }
$script:DotfilesViewDir = if ($env:DOTFILES_VIEW_DIR) { $env:DOTFILES_VIEW_DIR } else { Join-Path $HOME ".vscode-dotfiles" }
$script:DotfilesCodeProfile = if ($env:DOTFILES_CODE_PROFILE) { $env:DOTFILES_CODE_PROFILE } else { "Dotfiles" }

$env:DOTFILES_GIT_DIR = $script:DotfilesGitDir
$env:DOTFILES_WORK_TREE = $script:DotfilesWorkTree
$env:DOTFILES_VIEW_DIR = $script:DotfilesViewDir
$env:DOTFILES_CODE_PROFILE = $script:DotfilesCodeProfile

function global:dot {
    git --git-dir="$script:DotfilesGitDir" --work-tree="$script:DotfilesWorkTree" @args
}

function global:dot-help {
    @"
dotfiles helpers

  dot status          show dotfiles repo status
  dot diff            show unstaged changes
  dot add <path>      stage a tracked file from `$HOME
  dot add -f <path>   track a new ignored file from `$HOME
  dot commit          commit staged dotfiles changes
  dot-sync            recreate ~/.vscode-dotfiles editor view
  dot-code            open ~/.vscode-dotfiles in VS Code profile Dotfiles

Notes:
  ~/.dotfiles is the Git metadata directory.
  ~/.vscode-dotfiles is disposable and can be rebuilt with dot-sync.
  dot-sync uses symbolic links when possible and file hard links otherwise.
"@
}

function global:dot-code {
    if (-not (Test-Path -LiteralPath $script:DotfilesViewDir)) {
        dot-sync
    }

    code --profile $script:DotfilesCodeProfile $script:DotfilesViewDir
}

function New-DotfilesViewLink {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Source,

        [Parameter(Mandatory = $true)]
        [string] $Target
    )

    if (-not $script:DotfilesViewLinkType) {
        try {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force -ErrorAction Stop | Out-Null
            $script:DotfilesViewLinkType = "SymbolicLink"
            return
        } catch {
            $script:DotfilesViewLinkType = "HardLink"
        }
    }

    if ($script:DotfilesViewLinkType -eq "SymbolicLink") {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force -ErrorAction Stop | Out-Null
        return
    }

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Cannot create a hard link for non-file path: $Source"
    }

    New-Item -ItemType HardLink -Path $Target -Target $Source -Force -ErrorAction Stop | Out-Null
}

function global:dot-sync {
    $expectedViewDir = Join-Path $HOME ".vscode-dotfiles"
    if ($script:DotfilesViewDir -ne $expectedViewDir) {
        Write-Error "dot-sync: refusing to replace unexpected view dir: $script:DotfilesViewDir"
        return
    }

    try {
        if (Test-Path -LiteralPath $script:DotfilesViewDir) {
            Remove-Item -LiteralPath $script:DotfilesViewDir -Recurse -Force -ErrorAction Stop
        }

        New-Item -ItemType Directory -Path $script:DotfilesViewDir -Force -ErrorAction Stop | Out-Null
        $script:DotfilesViewLinkType = $null

        dot ls-files | ForEach-Object {
            $file = $_
            if ([string]::IsNullOrWhiteSpace($file)) {
                return
            }

            $source = Join-Path $script:DotfilesWorkTree $file
            $target = Join-Path $script:DotfilesViewDir $file
            $targetDir = Split-Path -Parent $target

            if (-not (Test-Path -LiteralPath $source)) {
                return
            }

            New-Item -ItemType Directory -Path $targetDir -Force -ErrorAction Stop | Out-Null
            New-DotfilesViewLink -Source $source -Target $target
        }

        Write-Host "dot-sync: recreated $script:DotfilesViewDir using $script:DotfilesViewLinkType links"
    } catch {
        Write-Error "dot-sync failed: $($_.Exception.Message)"
    }
}
