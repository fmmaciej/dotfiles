# psmux

Configuration: `.tmux.conf` and `.tmux/`, managed by the `tmux` Stow package.
[WezTerm](wezterm.md#startup) starts the session picker.

## Layout

- New sessions start with one pane, not an imposed split layout.
- Status shows the session name, window indices/names, prefix/zoom/sync state,
  battery when present, date and time.
- Active windows and pane borders use the [shared WezTerm accent](wezterm.md#shared-palette).

## Keys

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
| Copy mode, `Shift+PageUp/PageDown` | Scroll half a page up/down |
| Prefix, `P` | Paste Windows clipboard into the pane that received the key |

`paste-detection off` preserves Vim's Ctrl+V block selection.
WezTerm passes Shift+PageUp/PageDown through to copy mode.

## Plugins

- PPM replaces TPM; psmux-logging replaces tmux-logging.
- Bootstrap installs both under `$HOME/.psmux/plugins`, from upstream commit
  `3e94beff2159ee2c4dbb4180918930c328ab93c9`.
- Existing plugin directories are not overwritten. Plugin updates are separate,
  explicit actions.
- Native clipboard support replaces tmux-yank.
- Unix urlview is not copied to Windows. Resurrect/continuum stay disabled.

## Battery and helper routing

The battery display uses one native worker per server, polling CIM every 30
seconds without taking keys or changing the one-second clock refresh. Reloads
do not duplicate it; it exits after its server stops. Desktop PCs omit the segment.
This avoids the official battery plugin's collision with prefix+b.

Theme, battery and clipboard helpers explicitly target the originating session.
Paste captures the pane ID and uses a private, temporary buffer, so another
focused pane or concurrent paste cannot redirect it.

PPM receives a server-specific `TMUX` connection from the public `.port` locator;
later callbacks inherit it from the server environment. No authentication `.key`
file is read. A rename hook refreshes the helper context.

## References

- [psmux configuration](https://github.com/psmux/psmux/blob/v3.4.0/docs/configuration.md)
- [psmux plugins](https://github.com/psmux/psmux/blob/v3.4.0/docs/plugins.md)
