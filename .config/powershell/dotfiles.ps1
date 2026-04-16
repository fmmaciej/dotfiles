# Dotfiles helpers

$script:DotfilesGitDir = if ($env:DOTFILES_GIT_DIR) { $env:DOTFILES_GIT_DIR } else { Join-Path $HOME ".dotfiles" }
$script:DotfilesWorkTree = if ($env:DOTFILES_WORK_TREE) { $env:DOTFILES_WORK_TREE } else { $HOME }
$script:DotfilesViewDir = if ($env:DOTFILES_VIEW_DIR) { $env:DOTFILES_VIEW_DIR } else { Join-Path $HOME ".vscode-dotfiles" }

$env:DOTFILES_GIT_DIR = $script:DotfilesGitDir
$env:DOTFILES_WORK_TREE = $script:DotfilesWorkTree
$env:DOTFILES_VIEW_DIR = $script:DotfilesViewDir

function dot {
    git --git-dir="$script:DotfilesGitDir" --work-tree="$script:DotfilesWorkTree" @args
}

function dot-help {
    @"
dotfiles helpers

  dot status          show dotfiles repo status
  dot diff            show unstaged changes
  dot add <path>      track a file from `$HOME
  dot commit          commit staged dotfiles changes
  dot-sync            recreate ~/.vscode-dotfiles symlink view
  dot-code            open ~/.vscode-dotfiles in VS Code

Notes:
  ~/.dotfiles is the Git metadata directory.
  ~/.vscode-dotfiles is disposable and can be rebuilt with dot-sync.
  Symbolic links on Windows require Developer Mode or an elevated shell.
"@
}

function dot-code {
    if (-not (Test-Path -LiteralPath $script:DotfilesViewDir)) {
        dot-sync
    }

    code $script:DotfilesViewDir
}

function dot-sync {
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
            New-Item -ItemType SymbolicLink -Path $target -Target $source -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        Write-Error "dot-sync failed: $($_.Exception.Message). Enable Windows Developer Mode or run PowerShell as Administrator to create symbolic links."
    }
}
