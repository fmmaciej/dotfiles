# Dotfiles

Personal dotfiles stored in a normal Git repository at `~/.dotfiles` and linked
into `$HOME` with GNU Stow. Edit the files in this repository, not a generated
view. Changes to an existing file are immediately visible through its symlink;
the application may still need to reload its configuration.

## Edit and use Git

Open the actual repository in VS Code:

```sh
code ~/.dotfiles
```

The Zsh function `dot` runs Git from the repository root, regardless of the
current directory:

```sh
dot status
dot diff
dot add zsh/.zshrc
dot commit
```

Paths passed to `dot` are repository-relative. Outside Zsh, use
`git -C "$HOME/.dotfiles" ...`. There are no `dot-code`, `dot-sync`, or `dot-help`
helpers, and no generated editing view is needed.

## Packages

| Package | Configuration |
| --- | --- |
| `zsh` | Zsh startup files and numbered modules |
| `tmux` | tmux configuration, modules, and themes |
| `wezterm` | WezTerm configuration, palette, and session launcher |
| `vim` | Vim configuration and vim-plug bootstrap |
| `yazi` | Yazi configuration |
| `rtorrent` | rTorrent configuration |
| `common` | Home-level EditorConfig and urlview configuration |
| `opencode` | Global OpenCode CLI preferences and personal terminal UI |

Each package contains the directory layout expected under `$HOME`. README,
LICENSE, and this repository's `.gitignore` are not Stow packages.

## Check tools

Before installing links, check the commands used by the macOS configuration:

```sh
~/.dotfiles/check-tools.sh
```

For the planned WSL/Void configuration, use the separate list:

```sh
~/.dotfiles/check-tools-wsl.sh
```

Edit the `programs` array in each script to maintain its list. Each only checks
availability in `PATH`: it does not run or install the programs, check versions,
or detect GUI applications whose command-line tools are not in `PATH`.
Exit status is `0` when all commands are found, or `1` when any are missing.
This is a manual check, not a shell startup hook.

## Install or refresh links

Install GNU Stow first. On macOS, it is available through Homebrew. Before
changing links, inspect a dry-run:

```sh
stow --dir="$HOME/.dotfiles" --target="$HOME" --no-folding \
  --simulate --verbose --restow zsh tmux wezterm vim yazi rtorrent common opencode
```

After reviewing the proposed operations, run the same command without
`--simulate`:

```sh
stow --dir="$HOME/.dotfiles" --target="$HOME" --no-folding \
  --restow zsh tmux wezterm vim yazi rtorrent common opencode
```

Run Stow after adding, removing, or moving configuration files. Editing the
contents of an existing linked file does not require running Stow again.
Git staging and committing are separate from link management.

`--no-folding` keeps directories real and links individual files. In particular,
`~/.config/zsh/env.local` can remain a local file alongside the managed links.
Do not put that file in the repository or use `--adopt` to resolve conflicts.
Review and back up conflicting files before replacing them; do not overwrite
unrelated configuration.

To disconnect packages, inspect the equivalent `--simulate --delete` command
first, then use `--delete` instead of `--restow`. Restore original files from
the migration backup if rolling back; never use a checkout over all of `$HOME`.

## Zsh startup

| File | Responsibility |
| --- | --- |
| `~/.zshenv` | Shared paths and environment; no external program calls |
| `~/.zprofile` | Login initialization: optional Cargo environment, Homebrew, Java |
| `~/.zshrc` | History, Oh My Zsh, private local settings, numbered modules |
| `~/.config/zsh/[0-9][0-9]-*.zsh` | Interactive integrations and helpers |

There are no intermediate `env.zsh` or `login.zsh` loaders. The private
`~/.config/zsh/env.local` is loaded before numbered modules and remains outside
the repository. `env.example` documents the expected local settings.

`rc` reloads interactive settings only. After changing the shared or login
environment, open a new login shell, for example with `exec zsh -l`.

## OpenCode and the Kei entry point

OpenCode uses the personal terminal UI globally, regardless of the current
project. Its configuration and plugin are in the `opencode` package, separate
from Kei's instructions, tools, and project configuration.

The Zsh function `kei` is a small entry point to the instance:

```text
kei / kei help  show help
kei open        change the current terminal directory to the instance
kei run [args]  run OpenCode there, preserving the caller's directory on exit
kei edit        open the instance in VS Code
```

The instance path is set once in `zsh/.config/zsh/80-kei.zsh`. There is no
separate executable launcher or UI activation flag. See [OpenCode details and
tests](docs/opencode.md). The instance's `./00-system/bin/kei` remains its
separate administrative command.

## Branches and live configuration

Only `mac` currently has the Stow package layout. The preserved branches
`anyon`, `phonon`, `soliton`, and `windows` still use their original layouts.
Do not switch this live checkout to an unmigrated branch: the links would point
at paths that no longer exist. Adapt other branches in separate Git worktrees
before using them with Stow. Native Windows deployment needs its own decision.

Even between compatible branches, switching changes the files used by the live
configuration. Use a separate worktree for development that should not affect
this machine yet. After merging changes that alter file paths, refresh Stow
links. No new base branch is imposed by this migration.

The old bare repository `~/.dotfiles-backup` and editing view `~/.vscode-dotfiles`
are retained for recovery, but are no longer used by `dot` or the editing workflow.
Old home-level README, LICENSE, and `.gitignore` copies are also left untouched.
