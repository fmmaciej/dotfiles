# Flyline Vim fork on WSL

Flyline is the environment's default command-line editor. WSL installs a prebuilt
library from a **pinned release of your fork**. The supported profile is
limited to **x86_64 Linux, glibc 2.39+ and Bash 5.3** (tested on glibc 2.41).

- Source: <https://github.com/fmmaciej/flyline/tree/remote-ssh-vim>
- Commit: `d037c075ed30a61080873985ea2621d743ddfc64`
- Release: `remote-ssh-v1.10.0-pr974.aae68bb4.r5-linux.1`
- Artifact: `flyline-1.10.0-pr974.aae68bb4.r5-x86_64-unknown-linux-gnu.tar.gz`

## Install on WSL

Install the published release:

```bash
bash "$HOME/.dotfiles/scripts/install-flyline.sh"
```

The installer downloads that exact asset over HTTPS and verifies a SHA-256
embedded in the script. It needs ordinary Linux core utilities, `tar`, `sha256sum`,
and `curl`. Flyline activates when a new interactive Bash loads the configuration.

For an offline install or testing **before publication**, transfer the prepared
archive to WSL and pass its path. The same hardcoded checksum is still required:

```bash
bash "$HOME/.dotfiles/scripts/install-flyline.sh" /path/to/flyline-1.10.0-pr974.aae68bb4.r5-x86_64-unknown-linux-gnu.tar.gz
```

Installation uses `${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/flyline/`: a
directory named by the archive SHA-256 and an atomically switched `current`
symlink. Existing library bytes are never overwritten, even on reinstall.
Unrelated files and unmanaged links are refused. Use the same `XDG_DATA_HOME`
for installation and shell startup. No PATH executable is installed.

## Start and verify

Ensure the `bash` Stow package is linked, including `.config/bash/flyline.bash`.
Preview its links before applying changes; never deploy the WSL profile into
the Mac's real home. Start a **new interactive Bash in a disposable WSL terminal**:

```bash
bash
printf 'editor=%s history=%s flyline=%s\n' \
  "$_DOTFILES_LINE_EDITOR" "$_DOTFILES_HISTORY_BACKEND" "$_DOTFILES_FLYLINE_STATE"
```

Expect `editor=flyline` and `flyline=active`. Test Escape, insert/Normal mode,
motions/counts, `dw`/`cw`, yank/paste, undo, Normal-mode Ctrl-R redo, dot-repeat,
`k`/`j` history, `/`/`?`, Tab completion, Ctrl-C, empty Ctrl-D and prompt redraw.
Repeat inside tmux. This is an experimental Vim PR port, not full Vim emulation.

Atuin retains history storage/hooks when its preexec backend is available;
otherwise Bash history remains active. Insert-mode Ctrl-R uses Atuin (unless
`ATUIN_NOBIND`) or skim when available. It edits rather than immediately executes
the selection. Normal-mode Ctrl-R remains redo. Flyline's own JSONL history,
tutorial, automatic suggestions, flycomp, animations and mouse capture are off.
Starship remains the prompt owner. Nothing imports or syncs history.

Flyline loads by default in supported interactive sessions. Missing libraries or
unsupported terminals/hosts retain Readline; existing editors are left in control.
Ordinary load/settings errors restore Readline; a failed unload reports `rollback-failed`.
A native crash cannot be caught by shell fallback.

```bash
DOTFILES_ENABLE_FLYLINE=0 bash
# Emergency bypass of all startup files:
bash --noprofile --norc -i
```

To keep Flyline disabled, set `export DOTFILES_ENABLE_FLYLINE=0` before `.bashrc`,
for example in your existing `.profile`. `rc` does not change
the selected editor/backend or load twice. New releases affect new shells only.

## Publish the prepared release yourself

The locally prepared assets and publication instructions are in the ignored
`dist/flyline/` directory, including `RELEASE.md`, `SHA256SUMS`, license notices,
and a source snapshot. Nothing is uploaded automatically. Use the exact tag,
asset name and bytes above: changing the archive requires updating the installer's
SHA-256. Do not replace an already published asset or rewrite an existing tag.

The fork distinguishes MIT source and GPLv3 distributed binaries/combined Bash
works. The prepared binary archive includes both license texts; source and build
details accompany the release. Keep those files and notices when distributing.
Container results do not qualify Windows interoperability or the actual WSL host.

## Prepared build — 2026-11-13

The Linux library was built with Rust 1.99.1 and tested in a Linux amd64 container
(emulated on ARM), with glibc 2.41 and Bash 5.3.0. Actual library loading, command
execution, Vim change/undo/redo, `rc`, exit status and unload-to-Readline checks
passed in a PTY. The binary archive's SHA-256 is
`4c671e22ed701893163f9cbd3a7d2f54d7e3584f23b8d83825e06d7750be131e`.

35 fixture tests passed on both hosts and 28 WSL OpenCode tests passed. The
source archive includes locked dependency sources/notices; offline Cargo metadata
resolved all 279 packages without network access. See `VERIFICATION.md` in the
[published release](https://github.com/fmmaciej/flyline/releases/tag/remote-ssh-v1.10.0-pr974.aae68bb4.r5-linux.1)
for limits. Actual WSL/Atuin/Starship/tmux testing remains pending.
