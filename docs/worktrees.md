# Repository layout, branches, and worktrees

Dotfiles is one project and one Git repository. Branches such as `mac` and
`wsl` are environment variants, not independent projects. A primary checkout
is an entry point, not an automatically authoritative base for every branch.

## Shared layout

```text
repository/
├── README.md
├── docs/                    # documentation
├── scripts/                 # setup and diagnostic scripts
│   └── check-tools.sh       # native tool list for this branch
├── tests/
│   ├── opencode/            # shared OpenCode JS tests
│   └── <shell>/             # zsh on mac; bash on wsl
├── common/                  # Stow package
├── opencode/                # Stow package
│   └── .config/opencode/
├── tmux/                    # Stow package
├── vim/                     # Stow package
├── yazi/                    # Stow package
└── ...                      # environment-specific Stow packages
```

`mac` additionally has `zsh`, `wezterm`, and `rtorrent`; `wsl` has `bash`,
`starship`, and `atuin`. Do not create empty packages just for symmetry.
The Mac branch also keeps `scripts/check-tools-wsl.sh` as a reference list.

Matching paths do not require matching contents: shell selection, clipboard
commands, application openers, and other platform settings can differ.
Use the explicit Stow package list in this branch's README, never `stow *`.
Support directories and runtime data are not configuration packages.

## Working on a branch

Git is the source of truth for branch and worktree locations:

```sh
git -C "$HOME/.dotfiles" branch
git -C "$HOME/.dotfiles" worktree list
```

A worktree has a full set of working files and its own staging area, while
sharing Git history and refs. Commits go to the branch checked out there.
Uncommitted edits and ignored files are not synchronized between worktrees.

Keep permanent environment worktrees separate from temporary task worktrees.
For example, after checking the branch and choosing an unused destination:

```sh
git -C "$HOME/.dotfiles" worktree add -b chore/wsl-change \
  "$HOME/.dotfiles-work-wsl" wsl
```

This starts from `wsl`, not from whichever branch the primary checkout uses.
The task worktree can be removed after its changes are safely integrated;
do not force removal of uncommitted work. Worktree paths are chosen per task,
not maintained as a second registry in documentation.

## Transferring and deploying changes

- Keep structural moves separate from functional and platform-specific edits.
- Transfer a clean shared commit with `cherry-pick`; for a mixed commit, review
  selected files or hunks instead. A whole-branch merge also brings unrelated
  changes and is not the default for environment synchronization.
- `git restore --source <branch> -- <path>` replaces the destination's tracked
  files with committed source versions; it can overwrite edits and remove
  tracked files missing from the source. Review the destination status and diff.
- Move a plugin together with its local dependencies, licenses, and tests.
- A worktree may supply live Stow links. Use a temporary task worktree when
  changes must not immediately affect the running environment.
- New, removed, or moved configuration files require reviewing a Stow dry-run
  and refreshing links on the intended host. Content edits follow existing
  links; do not point the Mac's home at WSL packages for a test.
- Mac-hosted tests of WSL files are not a native WSL deployment test. Verify
  the target application's version, terminal behavior, and integration on WSL.

See [OpenCode](opencode.md) for the platform-specific checks and deployment
notes, and the root README for installation commands.
