# OpenCode terminal UI and Kei entry point

The `opencode` Stow package provides a global TUI-only plugin for OpenCode
**2.2.7**. It is independent of Kei: running `opencode` in any project uses the
same interface. It does not load Kei instructions or change server permissions,
providers, models, accounts, or authentication.

## Configuration

`opencode/.config/opencode/cli.json` preserves the existing theme, diff,
notification, and session preferences and enables `./plugins/personal-ui`.
It also defines the keybinds and disables the native tab strip replaced by
the plugin. Unrelated plugins should remain in the list when editing it.

The plugin keeps its historical package name `kei-terminal-ui`, TUI ID
`kei.terminal-ui`, and per-directory `tabs-<hash>` storage keys. This avoids an
unnecessary identity change. Session data and saved tab state stay in OpenCode's
runtime storage, never in this repository. The visible `Kei:` label and existing
layout are retained; this migration is not a UI redesign.

The plugin's `options.animations` controls its scanner and tab spinners. Set it
to `false` for static activity indicators. Native UI motion is separately
controlled by the top-level `animations` setting: OpenCode 2.2.7's public plugin
context does not expose that setting, so no private API or launcher is used.
Both are initially enabled, matching the previous configuration.

There are no activation environment variables or project-local discovery
adapters. Global `opencode.jsonc`, service configuration, credentials,
dependencies, databases, and logs are not managed by this package.

## Interface

The bottom bar contains the six activity states and compact numbered tabs.
Closing a tab does not delete its session. Restored tabs synchronize metadata
and pending questions/permissions, including child sessions, without calling
a model. Tabs are stored separately for each launch directory.

The sidebar shows the selected model and variant, the agent recorded in the
session, the last reported context sample, total usage, and OC-reported cost.
The context sample is not a live estimate. A zero reported cost does not prove
that usage was free. Native prompt model/agent information remains visible
because OC 2.2.7 does not provide a public removal slot.

Leader is **Ctrl+B**, leaving Ctrl+A for tmux:

| Key after leader | Action |
| --- | --- |
| `c` | New session |
| `,` | Rename active session |
| `x` | Close tab without deleting its session |
| `0`–`9` | Select numbered tab |
| `l` | Session list |
| `e` | External prompt editor |
| `b` | Toggle sidebar |

Alt+Up/Down changes tabs, Ctrl+P opens the command palette, and Ctrl+R renames
the session. The comma binding uses the existing public key event workaround
for OC 2.2.7. All owned listeners, timers, and slots are cleaned up on reload.

## Kei entry point

`zsh/.config/zsh/80-kei.zsh` defines one shell function with one instance path:

```text
kei / kei help  show help
kei open        change the current shell directory to the instance
kei run [args]  run OpenCode there; preserve the caller's directory afterward
kei edit        open the instance in VS Code
```

It uses simple Bash-compatible syntax but is loaded by Zsh. A standalone
executable cannot implement `kei open` for the calling terminal. After installing
or changing the function, open a fresh shell or run `exec zsh -l`.

This function is unrelated to the instance's `./00-system/bin/kei`, which still
provides `doctor`, `validate`, and other system operations.

## Checks

From the repository root:

```sh
node --test tests/opencode/*.test.mjs
python3 -B -m unittest discover -s tests/opencode -p 'test_*.py' -v
bash -n zsh/.config/zsh/80-kei.zsh
zsh -f -n zsh/.config/zsh/80-kei.zsh
```

Wrapper tests use synthetic paths and mock executables; they do not start an
editor or model. Typecheck and real TUI smoke tests use isolated runtime copies,
XDG directories, and synthetic sessions. Do not install test dependencies or
write test state inside the Stow packages.

### Verified on 2026-11-12

On OpenCode 2.2.7: 28 JS tests, 7 wrapper tests (each using Bash and Zsh), and
the strict plugin typecheck passed. Isolated real-TUI checks passed with
animations on at 160×42, off at 72×18, and after restoring saved synthetic tabs.
The deployed plugin also loaded normally in the actual Kei directory and an
unrelated directory, without activation flags, inline CLI config, duplicate UI,
or model requests. Real private sessions and saved tabs were not inspected.

The existing global theme, notifications, diff preferences, and session settings
were preserved. An initial Stow attempt refused a CLI file recreated while its
path was temporarily absent; the successful retry replaced the CLI path
atomically. Backups and detailed technical results are retained privately in
the migration runtime, not committed with the configuration.
