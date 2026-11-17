# Dotfiles — WSL / Void Linux

Developer-oriented WSL configuration derived from the `mac` branch. The target
checkout on WSL is `~/.dotfiles`; the preparation worktree on the Mac is separate
and must never be Stow-installed into the Mac's real home directory.

## Included

| Package | Purpose |
| --- | --- |
| `bash` | Bash startup, vi editing, skim, zoxide, Atuin/Starship init, `dot`, `y`, `wsl-open` |
| `starship` | Prompt adopted from `remote-ssh/dots/starship.toml` |
| `atuin` | Local history preferences adapted from `remote-ssh`; automatic sync disabled |
| `tmux` | Existing theme/navigation, Bash, optional Windows clipboard copy, no TPM dependency |
| `vim` | Existing editing configuration and vim-plug bootstrap |
| `yazi` | File manager with editor and Windows-opening integration |
| `opencode` | The same global personal UI as the Mac, independent of Kei |
| `common` | EditorConfig |

There is no Zsh, Homebrew, WezTerm host configuration, multimedia setup, rTorrent,
or `kei` function. WezTerm belongs to Windows. There is no dependency on an
installed `remote-ssh` checkout, updater, installer, or host identity setup.
Navi, Zellij, Nushell, and other optional tools are not part of this first WSL set.

## Check and install

Install the commands separately using an appropriate package manager or your
chosen binary installer. Stow only links configuration; it installs no programs:

```sh
~/.dotfiles/check-tools-wsl.sh
```

The script has one manually maintained command array and checks `PATH` only.
It does not validate versions, optional preview dependencies, Windows interop,
or libraries. This configuration follows the current remote-ssh integrations
(Atuin 18.24.6) and Yazi 26.9.1's `%s` opener format. Older versions require
verification; installing an executable alone does not prove compatibility.

Preview the links on the actual WSL machine:

```sh
stow --dir="$HOME/.dotfiles" --target="$HOME" --no-folding \
  --simulate --verbose --restow bash starship atuin tmux vim yazi opencode common
```

Review any existing files before proceeding. Back up conflicting regular files;
do not use `--adopt` or overwrite unrelated configuration. Then remove
`--simulate` to apply the links. Start a new Bash to select the integrations.
This does not change your login shell automatically.

`--no-folding` keeps real directories so existing local state can coexist with
managed files. Credentials, Atuin databases/keys, OpenCode sessions, and other
runtime data are neither copied from the Mac nor stored in this repository.
Existing OpenCode configuration must be merged, not blindly replaced. If OC is
running during installation, replace an existing `cli.json` atomically rather
than leaving it absent while preparing its Stow link.

## Shell behavior

- `dot ...` runs Git from `~/.dotfiles`, from any current directory.
- `y [args]` starts Yazi and changes the calling shell's directory after a
  successful exit. The temporary cwd file is removed afterward.
- `z ...` queries zoxide; `zi ...` selects its ranked results with skim, not fzf.
- Atuin owns history after successful initialization. Its Ctrl-R binding is
  limited to Emacs/vi insert mode; vi command-mode redo and ordinary Up/k remain.
- Without Atuin, Bash history remains enabled and skim provides Ctrl-R if present.
- Starship initializes last. Optional missing programs do not prevent startup.
- `rc` refreshes functions/settings, without selecting a new history backend or
  duplicating init hooks. Start a new Bash after installing/changing integrations.

Inspect the selected editor and history backend in the current Bash:

```sh
printf 'editor=%s history=%s\n' "$_DOTFILES_LINE_EDITOR" "$_DOTFILES_HISTORY_BACKEND"
```

The `.bash_profile` retains an existing `.profile`, then loads `.bashrc` only
for interactive login shells. Noninteractive `.bashrc` sourcing does nothing.
Atuin 18.18+ can use built-in bash-preexec support; no extra hook library is
vendored. Without an active preexec backend, Bash history remains enabled even
if the Atuin initializer itself returns success.
There is no automatic history import, account login, synchronization, update
check, or network request in this setup.

Command-specific completion uses the distribution's optional `bash-completion`
files when installed; ordinary Bash file completion remains available without
them. If Atuin stops working during an existing session, start a new Bash to
select the fallback rather than relying on `rc` to change history ownership.

## Windows integration

`wsl-open PATH` uses `wslview` if available, otherwise `wslpath` with
`explorer.exe`. Without either route it reports an error instead of assuming
that a Linux GUI desktop exists. Yazi edits text in `$EDITOR` and delegates
other files to this helper. Optional archive/PDF/JSON previews need their usual
external tools (for example 7-Zip, Poppler, or jq); install only what you use.

tmux copy-mode `y` uses `clip.exe` when available; otherwise it keeps an ordinary
tmux copy buffer. `P` pastes that tmux buffer. Paste the Windows clipboard using
the terminal's normal paste shortcut. No `pbcopy` or `pbpaste` is required.
The Windows VS Code CLI can be used as `code .` if its WSL integration is installed.

## Flyline: pinned binary release and opt-in Vim editor

See [Flyline on WSL](docs/flyline.md) for `scripts/install-flyline.sh`: it downloads
one exact release from the Vim fork and checks its embedded SHA-256. WSL needs
no Rust, Python or compiler. The target is x86_64/glibc Linux with Bash 5.3.
The Bash package includes guarded activation with `DOTFILES_ENABLE_FLYLINE=1`;
the default remains Readline until the actual Linux build passes WSL tests.

Publication is manual; prepared release assets live under ignored `dist/flyline/`.
Do not check Flyline with `command -v`: it is a Bash loadable library, not a PATH executable.

## Development checks

```sh
node --test tests/opencode/*.test.mjs
python3 -B -m unittest discover -s tests/bash -p 'test_*.py' -v
bash -n bash/.bashrc
bash -n bash/.bash_profile
bash -n bash/.local/bin/wsl-open
bash -n bash/.config/bash/flyline.bash
```

Tests use isolated homes and mock commands; they never link into the Mac's
real home or contact a model. Real WSL/Void, Windows clipboard/opening, and
Flyline qualification still require on-target verification.

### Preparation checks — 2026-11-12

On the macOS preparation host: 14 hermetic shell/config tests, 28 OpenCode
state/config tests, Bash syntax, ShellCheck, and isolated Stow installation
passed. Yazi 26.9.1 loaded this configuration in a real PTY. An isolated tmux
server loaded the profile with both buffer-only and mocked Windows clipboard
bindings. System Bash and Homebrew Bash initialized real Starship/zoxide;
the host's older Atuin 18.14 correctly retained Bash history rather than
pretending a preexec backend was active.

Successful Atuin-backend selection and Windows-opening routes were mock-tested;
the intended Atuin 18.24 integration and actual Windows interop still need WSL
tests. Flyline has not been activated. These checks are not a claim of a fully
qualified Void Linux installation.

The earlier source-build helpers have been replaced by a pinned binary-release
installer. See [the current WSL install/test instructions](docs/flyline.md);
historical checks above do not qualify that Linux library or the actual WSL host.

On 2026-11-13 the release path was prepared: a Linux amd64 build passed real
Bash 5.3.0 PTY checks on glibc 2.41 inside Docker emulation. The pinned installer
and 35 shell/installer/loader fixture tests passed on Mac and Linux. The binary,
source/dependency bundle and manual publication instructions are in ignored
`dist/flyline/`. Actual WSL testing and publication remain pending.
