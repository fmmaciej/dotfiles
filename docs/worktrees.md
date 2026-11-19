# Dotfiles project, branches, and worktrees

Dotfiles is one repository and one project. `mac`, `wsl`, and `windows` are
environment variants, not separate projects. The primary checkout is an entry
point, not an automatically authoritative base for every branch.

The common organization is:

```text
repository/
├── docs/
├── scripts/
├── tests/<area>/
├── common/
├── vim/
├── wezterm/                 # on branches that use it
├── yazi/
└── ...                     # environment-specific packages
```

Package directories mirror the expected destination paths. Matching package
names do not require identical settings. Windows keeps PowerShell, native
application openers, and explicit Windows configuration discovery; WSL keeps
Bash and Linux/Windows integration. Do not copy entire branches to synchronize
one application. Keep structural moves separate from functional updates.

Git is the source of truth for branch and worktree locations:

```powershell
git -C <checkout> branch
git -C <checkout> worktree list
```

Additional worktrees are selected per task; there is no second directory
registry in this document. Each has full working files, an independent staging
area, and its checked-out branch, while history and refs are shared.

Prepare changes in a temporary task worktree based on the intended environment
branch. Do not automatically start Windows work from `mac` or `main`. Use the
chosen checkout as Stow's explicit source only when it is ready to supply live
configuration. A source worktree with active links must not be removed or moved
without first planning link replacement.

Stow under MSYS2 must use `MSYS=winsymlinks:nativestrict` and the actual Windows
user profile as its explicit destination. MSYS2's own HOME can be different.
Use individual file links (`--no-folding`) so unmanaged local settings can stay
beside managed files. A Windows folder junction or hard link is not a silent
replacement for this deployment contract.

See the [migration guide](windows-migration.md) before using the package layout
on a machine that still has the old bare repository and HOME-wide work tree.
