# Dotfiles - Windows

Native Windows environment: WezTerm, psmux, PowerShell 7, Starship, skim, Yazi
and Vim. Scoop installs applications; MSYS2/Stow links their configuration.

## Fresh installation

On Windows x64, enable **Developer Mode** for native symlinks if your machine's
policy allows it. Open a regular **PowerShell, not as administrator**, and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass; irm https://raw.githubusercontent.com/fmmaciej/dotfiles/windows/bootstrap.ps1 | iex
```

Then **open WezTerm**. Choose an existing psmux session or create one.

SF Mono is preferred when installed system-wide. Otherwise WezTerm uses its
bundled JetBrains Mono. The bootstrap does not download fonts.

## Check tools

```powershell
pwsh -NoProfile -File "$HOME\.dotfiles\scripts\check-tools.ps1"
```

Only checks command availability: `OK` / `MISSING`, exit code `0` / `1`.
It does not install anything or test configuration.

## Everyday use

- `dot ...` - Git in the source checkout; edit that checkout directly.
- `Ctrl+R` - select a command from history with skim (does not execute it).
- `Ctrl+T` - select a file with skim and a bat preview.
- `y` - open Yazi and keep its last directory on exit.
- `Ctrl+A` - psmux prefix, matching the Mac tmux setup.

Application packages mirror paths under `$HOME`, as on `mac`/`wsl`.
Support scripts and documentation are not Stow packages; never use `stow *`.

[Windows details](docs/windows.md) · [Existing bare-repo migration](docs/windows-migration.md)
· [Branches/worktrees](docs/worktrees.md) · [Validation status](docs/windows-validation.md)
