# Global OpenCode UI on WSL

The `opencode` Stow package shares the Mac's personal UI sources and targets
OpenCode **2.2.7**. It loads globally from `~/.config/opencode/cli.json` (or
`$XDG_CONFIG_HOME/opencode/cli.json` when set), in any project. Stow commands
below assume the default configuration directory. The UI does not need a
`kei` function, a Kei instance, project instructions, activation flags, or a
remote-ssh runtime. See [repository and worktree organization](worktrees.md).

## Managed files

```text
opencode/.config/opencode/
├── cli.json
└── plugins/personal-ui/
    ├── package.json
    ├── state.mjs
    ├── tui.tsx
    └── vendor/             # integrated Vim runtime, license, and provenance
```

Transfer this package as a unit, including `vendor/`, together with its shared
tests in `tests/opencode/`. Copying only `tui.tsx` would leave a missing local
import. Do not transfer the Mac's Zsh `kei` entry point or its shell tests.

The historical package name `kei-terminal-ui`, plugin ID `kei.terminal-ui`, and
per-directory `tabs-<hash>` keys remain stable. They do not activate Kei features.
The native session title is the only naming source; the bar shows its first
word and the sidebar keeps the full title. Old separate aliases are ignored,
not deleted. Closing a tab does not delete its session.

## Interface and Vim editing

The bottom bar has a fixed-width Vim mode field, aligned uppercase activity
states, and compact numbered tabs. It temporarily shows `LEADER` while the
Ctrl+B prefix is pending. Native rename commands update the full session title.
The sidebar shows model, variant, session agent, last reported context sample,
usage, and reported cost; the context sample is not a live estimate.

The integrated Vim engine starts in insert mode. Escape enters normal mode;
`i` returns to insert, `v` / `V` starts selection, and `/vim` toggles Vim editing.
Enter adds a newline in insert mode and submits in normal mode. The automatic
system clipboard register is disabled. Do not enable a second standalone Vim
plugin alongside it. Version, license, and provenance are in
`../opencode/.config/opencode/plugins/personal-ui/vendor/README.md`.

Leader is Ctrl+B: `c` creates a session, `,` renames, `x` closes a tab, and
`0`–`9` select tabs. Alt+Up/Down cycles tabs, Ctrl+P opens the palette, and Ctrl+R
renames. Ctrl+A remains the tmux prefix. The native footer and tab strip are
hidden in favor of the personal UI.

`plugins[].options.animations` controls the custom spinners; top-level
`animations` controls native UI motion. Both are initially enabled.

## Checks

From the repository root, run the shared tests without a model:

```sh
node --test tests/opencode/*.test.mjs
```

These cover configuration, state/layout, and the vendored Vim runtime. They do
not start OpenCode or inspect private sessions. The sources have previously
been typechecked and exercised with isolated synthetic sessions on macOS;
Mac-hosted tests are not proof of native Linux terminal behavior.

## Deploy on the actual WSL host

1. Confirm the installed OpenCode version and run the shared tests on WSL.
2. Review existing global CLI preferences and preserve host-specific settings.
   Credentials, global server configuration, dependencies, service data, logs,
   and session databases are not managed by this package and must stay untouched.
3. Choose the actual WSL checkout/worktree, then inspect a dry-run:

   ```sh
   repo="$HOME/.dotfiles" # adjust if this host uses a different worktree
   stow --dir="$repo" --target="$HOME" --no-folding \
     --simulate --verbose --restow opencode
   ```

4. Resolve conflicts and back up existing files before changing links. After
   reviewing the dry-run, apply the same command without `--simulate` on WSL,
   not against the Mac's home. Do not use `--adopt` to overwrite conflicts.
5. Check plugin loading, tabs, native rename, the status bar, Ctrl+B shortcuts,
   and Vim modes. Use synthetic sessions without sending a model request;
   normal-mode Enter submits, so leave the prompt empty when testing navigation.

New vendor files require refreshing Stow links; edits to already linked files
are visible through their existing links. Valid CLI edits reload automatically;
use `/reload` if needed. No actual WSL deployment or native terminal smoke test
is claimed by the repository synchronization itself.

For rollback, restore the pre-update configuration, plugin, and shared tests
together from a reviewed Git revision or backup, then preview and refresh Stow
links on WSL. Do not reset unrelated configuration or private runtime state.
