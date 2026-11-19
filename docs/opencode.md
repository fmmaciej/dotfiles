# OpenCode

## Setup and launch

- Bootstrap installs or updates native OpenCode v2 with Scoop (`main/opencode`).
- Stow links the `opencode` package into `$HOME\.config\opencode`.
- The CLI configuration, personal UI, integrated Vim and shared tests come from
  the Mac/WSL packages. No WSL, shell wrapper or Kei instance is required.
- Existing conflicting CLI preferences are not overwritten. Model settings,
  logins, service data and session databases are not managed by this package.
- If `XDG_CONFIG_HOME` is set, OpenCode reads configuration there instead; the
  default Stow deployment still targets `$HOME\.config`.

From any project directory in PowerShell:

```powershell
opencode
```

CLI settings reload automatically; use `/reload` if needed.

## Interface

- Carbonfox dark theme, custom bottom bar and sidebar.
- Numbered session tabs, activity indicators, model/variant, reported context
  usage and cost.
- Closing a tab does not delete its session.
- The historical plugin name `kei-terminal-ui` is retained for state compatibility;
  it does not enable Kei workflows or instructions.

## Keys

| Keys | Action |
| --- | --- |
| `Ctrl+B`, then `c` | New session |
| `Ctrl+B`, then `,` or `Ctrl+R` | Rename session |
| `Ctrl+B`, then `x` | Close tab |
| `Ctrl+B`, then `0`-`9` | Select tab |
| `Alt+Up/Down` | Previous/next tab |
| `Ctrl+P` | Command palette |
| `Escape` / `i` | Vim normal / insert mode |
| `v` / `V` in normal mode | Character / line selection |
| `/vim` | Toggle Vim editing |

Enter inserts a newline in insert mode and submits in normal mode. Automatic
system-clipboard register integration is disabled, as on Mac/WSL. Do not add a
second Vim plugin. `Ctrl+A` remains the psmux prefix; `Ctrl+B` reaches OpenCode.

## Developer checks

With Node.js installed, from the repository root:

```powershell
node --test
```

These tests do not start OpenCode, send model requests or inspect private sessions.
Node.js is not required to run Scoop's standalone OpenCode executable. Native
Windows terminal behavior still needs a smoke test in WezTerm/psmux.

[Vim runtime provenance and license](../opencode/.config/opencode/plugins/personal-ui/vendor/README.md)
