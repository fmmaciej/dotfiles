# Dotfiles — WSL / Void Linux

Bash-based development environment for WSL / Void Linux, with Flyline Vim editing
and configuration managed by GNU Stow.

## Configuration

| Package | Purpose |
| --- | --- |
| `bash` | Shell startup, Flyline Vim editing, completion, skim and zoxide integration |
| `starship` | Shell prompt |
| `atuin` | Command history and interactive search |
| `tmux` | Terminal sessions, navigation, theme and clipboard integration |
| `vim` | Editor configuration and vim-plug |
| `yazi` | File manager with editor and Windows application integration |
| `opencode` | [Personal terminal UI](docs/opencode.md) |
| `common` | EditorConfig |

## Repository layout

Application directories at the root are GNU Stow packages and mirror paths
under `$HOME`. Documentation lives in `docs/`, setup and diagnostic scripts in
`scripts/`, and tests in `tests/<area>/`, matching the `mac` branch.
These support directories are not Stow packages: use explicit package names,
not `stow *`.

## Quick start

Run these steps inside WSL: clone → install tools and Flyline → link with Stow → start Bash.

### 1. Clone the WSL branch

With Git installed, replace `REPOSITORY_URL` with this repository's clone URL:

```sh
git clone --branch wsl REPOSITORY_URL "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
```

### 2. Install tools

Install GNU Stow and the tools listed in `scripts/check-tools.sh` using your package
manager or preferred binary installer, then check command availability:

```sh
./scripts/check-tools.sh
```

Install the distribution's `bash-completion` package for command-specific Tab
completion.

### 3. Install Flyline

Install the pinned Vim-enabled release for x86_64 Linux, glibc 2.39+ and Bash 5.3:

```sh
bash "$HOME/.dotfiles/scripts/install-flyline.sh"
```

### 4. Link the configuration

The package layout is ready for Stow. Preview the links it will create in your
home directory:

```sh
stow --dir="$HOME/.dotfiles" --target="$HOME" --no-folding \
  --simulate --verbose --restow bash starship atuin tmux vim yazi opencode common
```

Review conflicts and back up existing files. Merge existing OpenCode preferences
before replacing `cli.json`. Once the preview looks right, apply the links:

```sh
stow --dir="$HOME/.dotfiles" --target="$HOME" --no-folding \
  --verbose --restow bash starship atuin tmux vim yazi opencode common
```

### 5. Start a new Bash

Open a new Bash session or replace the current shell with a fresh login Bash:

```sh
exec bash -l
```

Flyline starts automatically in supported interactive sessions. Readline provides
the fallback if Flyline cannot load. See [Flyline on WSL](docs/flyline.md) for
keybindings, diagnostics and recovery.

### 6. Install Vim plugins

Open Vim and run `:PlugInstall` to install its plugins, then restart Vim.

## Everyday use

| Command | Action |
| --- | --- |
| `dot ...` | Run Git in `~/.dotfiles` |
| `y [args]` | Open Yazi and continue in its last directory |
| `z ...` | Jump to a directory using zoxide |
| `zi ...` | Select a directory with skim |
| `rc` | Reload shell functions and settings |
| `wsl-open PATH` | Open a file in a Windows application |

Ctrl-R searches history through Atuin or skim in insert mode. Start a new Bash
after changing the enabled integrations.

Yazi edits text with `$EDITOR` and opens other files through `wsl-open`, using
`wslview` or `wslpath` with `explorer.exe`. In tmux copy mode, `y` copies to the
Windows clipboard when `clip.exe` is available; `P` pastes the tmux buffer.

To start a session with Flyline disabled, use `DOTFILES_ENABLE_FLYLINE=0 bash`.

## Development checks

```sh
node --test tests/opencode/*.test.mjs
python3 -B -m unittest discover -s tests/bash -p 'test_*.py' -v
```
