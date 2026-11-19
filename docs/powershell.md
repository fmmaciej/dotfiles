# PowerShell

## Profiles

- PowerShell 7 is required. Windows PowerShell 5.1 profile entry points only
  report that requirement.
- CurrentUserAllHosts loads `.config/powershell/profile.ps1`; CurrentHost does
  not load it again.
- Bootstrap reads each PowerShell edition's `$PROFILE.CurrentUserAllHosts` to
  locate its profile directory; `$HOME\Documents` is not assumed.
- The shared loader runs once per process and sources only numbered modules:
  environment, PSReadLine/predictions, skim, proxy, aliases, Git helper and prompt.

## Predictions and completion

- PSReadLine supplies syntax highlighting and history suggestions.
- CompletionPredictor, an experimental module from the PowerShell project, adds
  suggestions from PowerShell's registered tab completers.
- Predictions use `HistoryAndPlugin` with `ListView`; before the module is
  installed, history-only predictions remain available.
- `F2` toggles list/inline suggestions. `Tab` opens the completion menu; Right
  Arrow accepts an inline suggestion at the end of the input line.
- `Ctrl+R` and `Ctrl+T` remain assigned to skim. Predictions also work without skim.
- Bootstrap and `dot update` install/update CompletionPredictor with PSResourceGet
  from PSGallery. PowerShell 7 supplies PSReadLine. No Node.js or AI provider is
  involved, and profile startup never installs modules or accesses the Gallery.
- Start a new PowerShell after installation/update to load the new module.

[PowerShell predictive IntelliSense](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors)

## Skim

- `Ctrl+R` recalls history without executing the selected command.
- `Ctrl+T` inserts a quoted file path selected with skim and a bat preview.
- Neither uses PSFzf or an `fzf=sk` alias.

## Dotfiles

- `dot <git arguments>` runs Git in the checkout that owns the linked profile.
- `dot update` runs `git pull --ff-only`, then that checkout's `bootstrap.ps1`
  in PowerShell 7 without loading profiles. It passes the checkout path explicitly,
  so a worktree outside `$HOME\.dotfiles` is also supported.
- If Git fails, bootstrap does not run. Neither command changes the caller's
  directory, resets/stashes local changes or automatically resolves conflicts.

## Proxy

Private configuration stays at `.config/powershell/proxy.local.psd1`, outside
Git. Loading the module defines functions only; proxy is not automatically enabled.

## Starship

Configuration: `.config/starship.toml`.

The existing prompt format is preserved, with the stash symbol escaped correctly.
The previously unused ahead/behind counters remain unused.
