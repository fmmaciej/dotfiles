# Windows implementation and validation status

## Scope and publication

Prepared on `chore/windows-stow-20261119` from Windows commit
`6d2b5bb15e53ffe8333b976f21adba2b539339f6`.
Changes are local, uncommitted and unstaged. No production Stow deployment,
bare-repo migration, commit, push or branch integration has been performed.
The existing Mac/WSL configurations were not changed.

The README's remote bootstrap command becomes usable only after this revision
is integrated and published on `windows`. Until then the remote branch does
not contain this implementation; use a reviewed copy of the local worktree for
testing, not an assumption that GitHub already serves the new bootstrap.

Seven packages contain 31 managed files. The native plugin manager/logging
plugin and Vim plugins belong to the user's application data, not to packages.
The proxy module, original vim-plug and historical Yazi backup retain their
original bytes. The backup now lives in `docs/history/` rather than being linked.

## Completed in the macOS preparation environment

- Seven portable layout, Git-ignore, helper-contract, line-ending and Markdown-link
  tests passed.
- A portable, SHA-256-verified PowerShell 7.7.0 was obtained in the disposable
  preparation runtime; no global PowerShell installation was made.
- All PowerShell sources passed the PowerShell parser.
- Git helper fixtures passed for ordinary checkouts, Git worktrees, caller
  directories, spaces, argument forwarding, exit codes, relative/absolute
  symlinks, invalid placement and calls from another script scope.
- Mocked bootstrap checks passed for missing-package installation, no-op reruns,
  checkout/revision/origin guards, dry-run ordering, existing plugins, numbered
  loader ordering/guard, Yazi's cwd wrapper, exported theme colors/fallbacks,
  and availability-only checker success/failure. No network calls, real tools,
  real profile/history or real HOME were used by these mocked checks.
- After the routing audit, psmux fixtures also passed for exact session targets,
  captured paste pane IDs, separate clipboard buffers, failed-paste cleanup,
  rejecting a closed originating server, battery routing and PPM's startup/
  callback environment. These are mocked multi-session scenarios, not a native
  Windows psmux integration test.
- Origin regression fixtures accept the intended HTTPS/SSH forms and reject
  lookalike domains, other repositories and malformed URL suffixes. Half-page
  copy-mode checks cover both psmux bindings and WezTerm key passthrough.
- Lua and TOML syntax passed. A stubbed WezTerm evaluation confirmed font
  fallback, shared palette exports, Windows appearance and psmux startup wiring;
  this is not a live WezTerm rendering test.
- Bash syntax passed for the checker and the embedded Stow deployment script.
- Real Stow fixture tests passed for all 31 file symlinks, real parent
  directories, reruns, conflict refusal, unmanaged-file preservation and rollback.
- The exact Bash dry-run/apply script embedded in bootstrap passed in a fixture,
  with only `cygpath` mocked. A conflicting real file stopped it before apply.
- MSYS2-side checker fixtures confirmed `0`/`1` results and that available
  commands are looked up rather than executed.
- Git whitespace checks passed.

Detailed disposable evidence remains in the preparation run's
`logs/implementation-checks.json` and `logs/implemented-stow.json`.
Neither the worktree supplying the only uncommitted changes nor the entire
preparation run should be deleted before review/integration.

## Still required on native Windows

These local checks do **not** prove a working Windows installation:

1. Fresh Windows x64 cold start from Windows PowerShell 5.1, Scoop installation,
   PowerShell 7 re-entry, MSYS2 initialization/updating and native Stow links.
   Use a disposable host/account, not the existing bare-repo home.
2. Actual profile destinations (including redirected Documents), execution
   policy constraints, native PATH/shims, and Windows symlink permissions.
3. psmux startup and reload, session menu/cancellation, splits/navigation/resize,
   window swapping, status formatting, theme environment inheritance, battery
   worker lifecycle, logging plugin and native clipboard.
4. Interactive skim/PSReadLine behavior and history recall, Starship prompt,
   Yazi discovery/openers/previews/cwd wrapper, Vim plugin installation, and
   SF Mono present/absent fallback in live WezTerm.

The development checks can also be rerun on Windows without loading profiles:

```powershell
pwsh -NoProfile -File tests/powershell/Test-Dotfiles.ps1
pwsh -NoProfile -File tests/powershell/Test-Bootstrap.ps1
pwsh -NoProfile -File tests/powershell/Test-Psmux.ps1
```

They are separate development fixtures, not features of `check-tools.ps1`.
Both tool checkers remain availability-only and are not startup hooks.

Before migrating the existing installation, obtain its HEAD and local module
names and follow the [migration guide](windows-migration.md). The earlier human
confirmation of Developer Mode/native symlinks establishes the basic toolchain,
not successful deployment of these new configurations.

The human declined application version checks after audit: both bootstrap and
tool checkers continue to use presence checks, without automatic upgrades.
The origin-host matching and Mac copy-mode shortcut findings were subsequently
approved and corrected. Native Windows verification remains required.
