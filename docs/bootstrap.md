# Bootstrap

## Scripts

- `bootstrap.ps1` obtains helpers and coordinates setup in PowerShell 7.
- `scripts/windows/tools.ps1` installs tools with Scoop and MSYS2/pacman.
- `scripts/windows/dotfiles.ps1` prepares the checkout, Stow links and plugins.

## Installation flow

- Downloads the `windows-next` archive directly, without Git or GitHub API calls.
- Reads its commit SHA from the ZIP metadata to check the checkout revision.
- Installs Scoop, Git and PowerShell 7; re-enters PowerShell 7 when necessary.
- Installs/updates CompletionPredictor from PowerShell Gallery for the current user.
- Creates a normal `windows-next` checkout at `$HOME\.dotfiles`.
- Checks profile destinations, competing psmux configs and native symlink permissions.
- Simulates Stow for all nine packages before applying links.
- Generates Atuin's native Nushell autoload integration, without replacing Nu's
  configuration or changing the default shell.
- Installs [psmux plugins](psmux.md#plugins) and [Vim plugins](vim.md).

The archive and checkout revisions must match. A branch moving during download
stops setup rather than resetting the checkout. Existing checkouts keep their
changes: bootstrap does not pull, reset, stash, clean or switch them. Their
`origin` must be this repository, using a standard GitHub HTTPS or SSH address.
Lookalike hosts, other repositories and URL suffixes are rejected.

To use an existing prepared checkout, run its local
`bootstrap.ps1 -RepositoryPath <checkout>`.

File conflicts stop linking; files are not adopted or overwritten. Installed
tools and a new checkout can remain after a later conflict. Resolve it and rerun.
No checkpoint files or automatic elevation are involved.

## Packages

| Stow package | Managed paths |
| --- | --- |
| `powershell` | `.config/powershell`, individual profile files at locations reported by `$PROFILE` |
| `wezterm` | `.wezterm.lua`, `.config/wezterm` |
| `tmux` | `.tmux.conf`, `.tmux` modules, theme and native psmux helpers |
| `starship` | `.config/starship.toml` |
| `yazi` | `.config/yazi/yazi.toml` |
| `vim` | `.vimrc`, `_vimrc`, `vimfiles/autoload/plug.vim` |
| `common` | `.editorconfig` (LF) |
| `opencode` | `.config/opencode/cli.json`, personal UI plugin and integrated Vim runtime |
| `atuin` | `.config/atuin/config.toml` (local history, automatic sync disabled) |

## Tools and MSYS2 updates

- Scoop main: Git, pwsh, MSYS2, Vim, Starship, Yazi, eza, skim, fd, bat,
  ripgrep, ffmpeg, 7zip, jq, poppler, psmux, OpenCode v2, Atuin and Nushell (`nu`).
- Scoop extras: WezTerm.
- Missing Scoop packages are installed; existing packages are updated. Already
  current packages need no action and setup continues.
- CompletionPredictor uses PowerShell 7's PSResourceGet with `CurrentUser` scope,
  not Scoop. Repository trust is accepted for this operation only; no permanent
  repository-policy change or administrator shell is required.
- If Stow is absent, MSYS2 performs full `pacman -Syu` updates before installing
  it. A core update may require rerunning bootstrap after the shell exits.
- Do not continue after a failed update or use `pacman -Sy` as a partial-upgrade
  shortcut. Scoop base upgrades and pacman updates are separate operations.
- Already installed Vim/psmux plugins are not updated or overwritten by bootstrap.
- Atuin and Nushell are updated through Scoop. Bootstrap refreshes only its own
  generated `dotfiles-atuin.nu` in Nu's user-data `vendor/autoload` directory.
  Existing Nu configuration, other autoload files and history remain untouched;
  a file at that generated path without the dotfiles marker stops setup.

## Profile destinations

- PowerShell 7 uses the directory of `$PROFILE.CurrentUserAllHosts`.
- Windows PowerShell reports its own `$PROFILE.CurrentUserAllHosts` through a
  `powershell.exe -NoProfile` invocation.
- Stow links the individual profile entry points into these directories, including
  redirected Documents in OneDrive and paths containing spaces.
- Other configuration still targets `$HOME`. No Documents directory is replaced
  or redirected; existing unrelated files remain untouched.
- All Stow targets are simulated before any links are applied. Existing profile
  files that conflict with the links stop setup rather than being overwritten.

## Availability checks

From PowerShell:

```powershell
pwsh -NoProfile -File scripts/check-tools.ps1
```

From MSYS2:

```bash
bash scripts/check-tools.sh
```

Both only look up commands, print `OK` / `MISSING`, and return `0` / `1`.
They do not execute applications, test configuration or install tools.

## References

- [MSYS2 native symlinks](https://www.msys2.org/docs/symlinks/)
- [MSYS2 updates](https://www.msys2.org/docs/updating/)
