# Bootstrap

## Scripts

- `bootstrap.ps1` obtains helpers and coordinates setup in PowerShell 7.
- `scripts/windows/tools.ps1` installs tools with Scoop and MSYS2/pacman.
- `scripts/windows/dotfiles.ps1` prepares the checkout, Stow links and plugins.

## Installation flow

- Downloads the `windows-next` archive directly, without Git or GitHub API calls.
- Reads its commit SHA from the ZIP metadata to check the checkout revision.
- Installs Scoop, Git and PowerShell 7; re-enters PowerShell 7 when necessary.
- Creates a normal `windows-next` checkout at `$HOME\.dotfiles`.
- Checks profile destinations, competing psmux configs and native symlink permissions.
- Simulates Stow for all seven packages before applying links.
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

| Stow package | Managed paths under `$HOME` |
| --- | --- |
| `powershell` | `.config/powershell`, individual profile files in `Documents` |
| `wezterm` | `.wezterm.lua`, `.config/wezterm` |
| `tmux` | `.tmux.conf`, `.tmux` modules, theme and native psmux helpers |
| `starship` | `.config/starship.toml` |
| `yazi` | `.config/yazi/yazi.toml` |
| `vim` | `.vimrc`, `_vimrc`, `vimfiles/autoload/plug.vim` |
| `common` | `.editorconfig` (LF) |

The Windows packages do not include OpenCode.

## Tools and MSYS2 updates

- Scoop main: Git, pwsh, MSYS2, Vim, Starship, Yazi, eza, skim, fd, bat,
  ripgrep, ffmpeg, 7zip, jq, poppler and psmux.
- Scoop extras: WezTerm.
- Missing Scoop packages are installed; existing packages are updated. Already
  current packages need no action and setup continues.
- If Stow is absent, MSYS2 performs full `pacman -Syu` updates before installing
  it. A core update may require rerunning bootstrap after the shell exits.
- Do not continue after a failed update or use `pacman -Sy` as a partial-upgrade
  shortcut. Scoop base upgrades and pacman updates are separate operations.
- Already installed Vim/psmux plugins are not updated or overwritten by bootstrap.

## Profile destinations

The layout targets `$HOME\Documents`. Bootstrap stops if Documents is redirected,
for example by OneDrive. That host needs a reviewed adaptation of the profile
destinations and bootstrap check before deployment.

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
