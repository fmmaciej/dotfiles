# Existing Windows bare-repo migration

This is separate from fresh-machine bootstrap. The old `$HOME\.dotfiles` is a
bare repository whose work tree covers `$HOME`; the new one is an ordinary
checkout with Stow packages. Never check out the new layout over HOME.

## Before changing anything

1. Inspect the old bare repo's HEAD, branch, status and remotes. A clean status
   does not include ignored local modules or private settings.
2. Inventory the names of local `.config/powershell` files and compare them with
   the tracked modules. Do not publish proxy secrets or shell history.
3. Back up Git metadata and affected files outside the new packages, using an
   explicit, reviewed list. Keep private `proxy.local.psd1` outside Git.
4. Obtain the prepared Windows revision in a **new ordinary checkout**, for
   example `$HOME\.dotfiles-next`, once it has been published. Do not overwrite
   the old `.dotfiles` directory. A local uncommitted preparation worktree is
   not yet available by cloning GitHub's `windows` branch.
5. Choose a stable source path before linking. Do not move a checkout that
   supplies live links without planning a Stow refresh.

The old modules have numbered replacements. In particular, `aliases.ps1`,
`dotfiles.ps1`, `fzf.ps1` and `proxy.ps1` must not remain as competing active
initializers. Back them up and resolve their destinations individually.
The new loader sources only numbered modules, never every `.ps1` file.

## Review the actual host

Use PowerShell 7 with `-NoProfile`. Inspect `$PROFILE.CurrentUserAllHosts` and
`[Environment]::GetFolderPath('MyDocuments')`. Packages currently target
`$HOME\Documents`; redirected Documents/OneDrive requires a separate reviewed
mapping. Do not replace an entire Documents directory.

Also review existing `.psmux.conf` and `.psmuxrc`: they take precedence over
`.tmux.conf`. WezTerm uses explicit `-f`, but a direct `psmux` invocation and
PPM must resolve the same configuration.

## Preview Stow

From **MSYS2**, with Stow installed:

```bash
win_home="$(cygpath -u "$USERPROFILE")"
repo="$win_home/.dotfiles-next" # adjust to your reviewed stable checkout
bash "$repo/scripts/check-tools.sh"
MSYS=winsymlinks:nativestrict stow \
  --dir="$repo" --target="$win_home" --no-folding --simulate --verbose \
  --restow common powershell starship tmux vim wezterm yazi
```

Conflicts with old real files are expected. Review and back up each conflicting
file before moving it aside. Never use `--adopt`, forced overwrite, broad HOME
cleanup, or copies/hard links in place of native symlinks.

Keep `proxy.local.psd1` as an unmanaged local file beside the managed links.
Git ignore rules do not stop Stow from deploying files inside packages, so
never put private files, logs or downloaded plugins inside a package.

## Deploy only after review

Once the dry-run is clean and deployment is explicitly approved, run the local
bootstrap against that checkout:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME\.dotfiles-next\bootstrap.ps1" -RepositoryPath "$HOME\.dotfiles-next"
```

It installs missing tools/plugins and performs another dry-run before linking.
It does not migrate or delete the old bare repo. Start a fresh shell afterward
to discard old functions, then verify `dot rev-parse --show-toplevel`, Starship,
Yazi, skim, psmux and the Windows clipboard. See [Windows details](windows.md).

## Rollback

From the same MSYS2 source and target, preview unlinking only these packages:

```bash
MSYS=winsymlinks:nativestrict stow \
  --dir="$repo" --target="$win_home" --no-folding --simulate --verbose \
  --delete common powershell starship tmux vim wezterm yazi
```

Review before repeating without `--simulate`. Restore only the original files
from the reviewed backups; leave unrelated files untouched. Installed tools
and plugins are not removed automatically. The old Git metadata remains
available because neither bootstrap nor this procedure deletes it.
