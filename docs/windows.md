# Windows environment

## Packages and paths

| Stow package | Managed paths under `$HOME` |
| --- | --- |
| `powershell` | `.config/powershell`, individual PowerShell profile files in `Documents` |
| `wezterm` | `.wezterm.lua`, `.config/wezterm` palette and session launcher |
| `tmux` | `.tmux.conf`, `.tmux` modules, theme and native helper scripts for psmux |
| `starship` | `.config/starship.toml` |
| `yazi` | `.config/yazi/yazi.toml` |
| `vim` | `.vimrc`, `_vimrc`, `vimfiles/autoload/plug.vim` |
| `common` | `.editorconfig` (LF) |

The old Yazi backup is preserved under `docs/history/`, not deployed as an
application configuration. No font binaries or OpenCode package are added.

## Bootstrap behavior

`bootstrap.ps1` coordinates two files: `scripts/windows/tools.ps1` installs tools;
`scripts/windows/dotfiles.ps1` handles the checkout, Stow and application setup.
No configuration engine, checkpoint files or automatic elevation are involved.

The remote entry point downloads a commit-pinned repository archive before Git
exists, installs Scoop/Git/PowerShell, and re-enters PowerShell 7 if necessary.
It then obtains an ordinary `windows` checkout at `$HOME\.dotfiles`. Source and
checkout revisions must match; a branch moving during download produces a stop,
not a reset. An existing checkout retains its changes and is never pulled,
reset, stashed, cleaned or switched automatically. To use an existing prepared
checkout deliberately, run its local `bootstrap.ps1 -RepositoryPath <checkout>`.

An existing checkout must have exactly this repository as `origin`, using a
standard GitHub HTTPS or SSH address. Lookalike hosts, other repositories and
URLs with extra path/query/fragment content are rejected without changing it.

Scoop main packages: Git, pwsh, MSYS2, Vim, Starship, Yazi, eza, skim, fd, bat,
ripgrep, ffmpeg, 7zip, jq, poppler and psmux. WezTerm comes from extras. Existing
Scoop packages are not automatically upgraded. Yazi preview dependencies cover
video, archives, JSON and PDF; `rg` provides text search.

MSYS2 initializes on first use. If Stow is absent, bootstrap performs full
`pacman -Syu` updates before installing it; a core update may require rerunning
bootstrap after its shell exits. Never continue after a failed update or use
`pacman -Sy` as a partial-upgrade shortcut. Scoop base upgrades and pacman
package updates remain separate maintenance operations.

Bootstrap checks profile destinations, conflicting psmux entry points and native
symlink permission, then runs a Stow simulation for all seven packages before
applying links. Existing real files stop deployment rather than being adopted or
overwritten. This is not a transaction: installed tools and a new checkout can
remain after a later conflict; fix that conflict deliberately and rerun.

PPM and the native logging plugin are installed from pinned upstream commit
`3e94beff2159ee2c4dbb4180918930c328ab93c9` outside the repository, under
`$HOME/.psmux/plugins`. Existing plugin directories are not overwritten. Vim's
five configured plugins are installed with vim-plug in `$HOME/vimfiles/plugged`;
bootstrap does not update already installed plugins. Plugin-manager updates are
separate explicit actions.

## PowerShell

CurrentUserAllHosts loads the shared profile; CurrentHost does not load it again.
The shared loader is guarded per process and sources only numbered modules:
environment, skim, proxy, aliases, Git helper, prompt. PowerShell 7 is required;
Windows PowerShell 5.1 profile entry points only report that requirement.

`Ctrl+R` recalls history without executing it; `Ctrl+T` inserts a quoted file
path selected with skim. Neither uses PSFzf or an `fzf=sk` alias. Private proxy
configuration stays at `.config/powershell/proxy.local.psd1`. Loading its module
defines functions only: proxy is not automatically enabled.

Starship uses `.config/starship.toml`. Its existing format is preserved, with
the stash symbol escaped correctly. The previously unused ahead/behind counters
remain unused rather than changing the prompt's layout incidentally.

## Yazi and Vim

`YAZI_CONFIG_HOME` points at `.config/yazi`; `YAZI_FILE_ONE` is resolved from
Scoop Git's `usr/bin/file.exe`, unless explicitly set by the user. Text files
open in Vim; images, video and audio open in the Windows-associated application.
`y` leaves the calling shell in Yazi's final directory.

The native opener syntax targets Yazi 26.9+. Standard navigation and previews
work without fzf/zoxide. Yazi's optional built-in fuzzy jump (`z`, fzf) and
zoxide jump (`Z`) are not supplied by installing skim; install their actual
dependencies separately if you choose those features. No fake fzf alias is used.
Image-preview passthrough inside psmux still needs native Windows verification.

Vim keeps CodeDark, Airline, surround, NERDTree and its existing editing settings.
Normal yank/paste uses the system clipboard via `clipboard=unnamed,unnamedplus`;
there is no extra leader+p mapping. If CodeDark is not installed yet, Vim uses
the default theme until the plugin becomes available.

## psmux layout and keys

WezTerm starts `.config/wezterm/psmux-session.ps1`. With no sessions it creates
`main`; otherwise skim offers existing sessions and `[NEW]`. Cancelling safely
creates or attaches `main`, never tries to create a duplicate. New sessions have
one pane, not an imposed split layout. The WezTerm launch menu also offers a
plain PowerShell 7 session for recovery.

| Keys | Action |
| --- | --- |
| `Ctrl+A` | Prefix |
| Prefix, `v` / `b` | Split top/bottom / left/right |
| Prefix, `h/j/k/l` | Navigate panes |
| Prefix, `Ctrl+h/j/k/l` | Resize panes |
| `Ctrl+Shift+Left/Right` | Swap windows, no prefix |
| Prefix, `p` | Toggle synchronized input |
| Prefix, `q` | Respawn current pane (kills its process) |
| Prefix, `r` | Reload configuration |
| Copy mode, `v` / `y` | Select / copy to native Windows clipboard |
| Copy mode, `Shift+PageUp/PageDown` | Scroll half a page up/down, matching Mac |
| Prefix, `P` | Paste Windows clipboard into the pane that received the key |
| `Ctrl+Shift+C/V` | WezTerm clipboard copy/paste |
| `Alt+Enter` | WezTerm fullscreen |

psmux owns all prefix-based pane/window actions. `paste-detection off` preserves
Vim's Ctrl+V block selection. Native clipboard support replaces tmux-yank;
TPM is replaced by PPM and tmux-logging by psmux-logging. Unix urlview is not
silently copied to Windows; resurrect/continuum stay disabled, as on Mac.

WezTerm passes Shift+PageUp/PageDown through instead of using those keys to
scroll its outer scrollback; the half-page actions belong to psmux copy mode.

The battery display uses one native worker per server, polling CIM every 30
seconds without taking any keys or changing the one-second clock refresh.
Reloads do not duplicate it; it exits after its server stops. This avoids the
official battery plugin's collision with prefix+b. Desktop PCs omit the segment.

Theme, battery and clipboard helpers explicitly target the originating session.
Clipboard paste also captures the pane ID and uses a private, temporary buffer,
so another focused pane or concurrent paste cannot redirect the operation.
PPM receives a server-specific `TMUX` connection from the public `.port` locator;
its later callbacks inherit that connection from the server environment. No
authentication `.key` file is read. A rename hook refreshes the helper context.

## Shared palette

`.config/wezterm/colors/vscode_dark_modern.lua` owns the palette and exports
`THEME_*` environment variables. The psmux theme reads them through native
PowerShell, preserving the Mac architecture without running Bash daily.
Independent fallback values allow launching psmux outside WezTerm.

Status: session name on the left, window indices/names, then prefix/zoom/sync,
battery when present, date and time on the right. Active windows and pane borders
use the shared accent. WezTerm retains SF Mono 11 (JetBrains Mono fallback),
line height 1.05, WebGPU/120 FPS, hidden tabs and 100000-line scrollback.

Environment variables belong to running processes. Changing a palette file
does not rewrite an existing psmux server's environment; use a newly started
server to pick up a new WezTerm palette. Do not kill sessions with active work
merely to refresh colors. Starship and Yazi are not generated from this palette.

## Availability checks

From PowerShell: `pwsh -NoProfile -File scripts/check-tools.ps1`.
From MSYS2: `bash scripts/check-tools.sh`.
Both only look up commands, print `OK` / `MISSING`, and return `0` / `1`.
They do not execute the checked applications, test configuration or install tools.
Native `file.exe` is deliberately not a global shim; see `YAZI_FILE_ONE` above.

## References

- [psmux configuration](https://github.com/psmux/psmux/blob/v3.4.0/docs/configuration.md)
- [psmux plugins](https://github.com/psmux/psmux/blob/v3.4.0/docs/plugins.md)
- [MSYS2 native symlinks](https://www.msys2.org/docs/symlinks/)
- [MSYS2 updates](https://www.msys2.org/docs/updating/)
- [Yazi configuration](https://yazi-rs.github.io/docs/configuration/yazi/)
- [WezTerm fonts](https://wezterm.org/config/fonts.html)
