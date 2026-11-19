# WezTerm

## Startup

WezTerm runs `.config/wezterm/psmux-session.ps1`:

- With no sessions, creates `main`.
- Otherwise, skim offers existing sessions and `[NEW]`.
- Cancelling creates or attaches `main`, without creating a duplicate.
- The launch menu also offers plain PowerShell 7 without psmux.

See [psmux](psmux.md) for sessions, panes and copy-mode keys.

## Appearance

- VS Code Dark Modern.
- System-installed SF Mono 11; bundled JetBrains Mono fallback.
- Line height 1.05, WebGPU, 120 FPS, hidden tabs, 100000-line scrollback.
- No font binaries are included or downloaded by bootstrap.

## Keys

| Keys | Action |
| --- | --- |
| `Ctrl+Shift+C/V` | Clipboard copy/paste |
| `Alt+Enter` | Fullscreen |

Ctrl+A and the pane/window bindings belong to psmux. Shift+PageUp/PageDown are
passed through for psmux copy mode instead of scrolling the outer terminal.

## Shared palette

`.config/wezterm/colors/vscode_dark_modern.lua` owns the palette and exports
`THEME_*` environment variables. The psmux theme reads them through native
PowerShell, without Bash. Fallback values allow psmux to run outside WezTerm.

Changing the palette file does not rewrite an existing psmux server's environment.
A newly started server picks up the new palette; do not kill sessions with active
work just to refresh colors. Starship and Yazi are not generated from this palette.

[WezTerm fonts](https://wezterm.org/config/fonts.html)
