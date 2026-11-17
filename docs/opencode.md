# Global OpenCode UI on WSL

The `opencode` Stow package is unchanged from the Mac's personal UI and targets
OpenCode **2.2.7**. It loads globally from `~/.config/opencode/cli.json`, in any
project. It does not need a `kei` function, a Kei instance, project instructions,
activation flags, or a remote-ssh runtime.

The historical `Kei:` label, package name `kei-terminal-ui`, plugin ID
`kei.terminal-ui`, and per-directory `tabs-<hash>` keys are preserved to avoid
an unrelated rebranding or storage migration. They do not activate Kei features.
Private sessions, authentication, and saved tab data are not in the repository.

The plugin provides the bottom tab/status bar and sidebar with model, variant,
session agent, last context sample, usage, cost, and key hints. The context value
is the last OC-reported sample, not a live estimate. Native prompt model/agent
metadata remains visible because the public API does not provide a removal slot.

Leader is Ctrl+B; `c` creates a session, `,` renames it, `x` closes its tab without
deleting the session, and `0`-`9` select tabs. Alt+Up/Down cycles tabs, Ctrl+P opens
the palette, and Ctrl+R renames. Ctrl+A remains the tmux prefix.

`plugins[].options.animations` controls the custom scanner/spinners; top-level
`animations` controls native UI motion. These are separate settings because the
OC 2.2.7 plugin context does not expose the native animation setting. Both are
initially enabled. Existing global CLI preferences must be reviewed/merged
before replacing a host's file; this repository must not replace credentials,
server configuration, dependencies, service data, or session databases.

Run the state/config checks without a model:

```sh
node --test tests/opencode/*.test.mjs
```

The source was previously typechecked and exercised in real OC 2.2.7 with isolated
synthetic sessions on macOS. That is not proof of behavior on WSL/Void; actual
Linux terminal and installed-version checks remain required. No Kei command
implementation or Kei-specific wrapper tests are included in this branch.
