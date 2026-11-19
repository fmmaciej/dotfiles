# Dotfiles - Windows

WezTerm + psmux + PowerShell 7, Starship, skim, Yazi, Vim and OpenCode.

## Quick start

For a fresh Windows x64 installation.
Do not run over an existing bare `$HOME\.dotfiles` repository.

### 1. Enable Developer Mode

In **PowerShell as administrator**:

```powershell
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
```

### 2. Run bootstrap

Close the elevated window. Open **PowerShell, not as administrator**:

```powershell
Set-ExecutionPolicy -Scope Process Bypass; irm https://raw.githubusercontent.com/fmmaciej/dotfiles/windows-next/bootstrap.ps1 | iex
```

The bootstrap:

- Installs Scoop, Git and PowerShell 7.
- Installs WezTerm, psmux, Starship, Yazi, Vim and OpenCode.
- Installs skim, fd, bat, eza, ripgrep, ffmpeg, 7zip, jq and poppler.
- Installs MSYS2 and Stow.
- Updates existing Scoop packages; already current packages are left as-is.
- Clones `windows-next` into `$HOME\.dotfiles`.
- Links configurations with Stow.
- Installs Vim and psmux plugins.
- Checks command availability.

Wait for `Ready. Open WezTerm.`

### 3. Run WezTerm

```powershell
wezterm
```

### 4. Check tools

```powershell
pwsh -NoProfile -File "$HOME\.dotfiles\scripts\check-tools.ps1"
```

- Expected: all `OK`; missing commands are marked `MISSING`.
- Exit code: `0` when complete, `1` when tools are missing.
- Checks availability only; no installation or configuration tests.

## Scripts

- `bootstrap.ps1` - obtains helpers and coordinates setup in PowerShell 7.
- `scripts/windows/tools.ps1` - installs/updates applications with Scoop and installs Stow with MSYS2/pacman.
- `scripts/windows/dotfiles.ps1` - creates/reuses the checkout, checks conflicts, links configs and installs plugins.
- `scripts/check-tools.ps1` - checks native Windows commands.
- `scripts/check-tools.sh` - checks Bash, Perl, Stow and cygpath inside MSYS2.

## Notes

- If an MSYS2 update interrupts setup, close MSYS2 windows and rerun bootstrap.
- File conflicts stop linking. Back up/reconcile the listed files, then rerun;
  bootstrap does not overwrite them or pull/reset/stash the checkout.
- PowerShell profile locations come from `$PROFILE`, including Documents in OneDrive.
- SF Mono is optional and user-installed; otherwise WezTerm uses JetBrains Mono.

## Configuration

- [Bootstrap](docs/bootstrap.md)
- [PowerShell and Starship](docs/powershell.md)
- [WezTerm and palette](docs/wezterm.md)
- [psmux and keybindings](docs/psmux.md)
- [Yazi](docs/yazi.md)
- [Vim](docs/vim.md)
- [OpenCode](docs/opencode.md)
