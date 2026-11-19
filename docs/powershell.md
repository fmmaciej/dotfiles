# PowerShell

## Profiles

- PowerShell 7 is required. Windows PowerShell 5.1 profile entry points only
  report that requirement.
- CurrentUserAllHosts loads `.config/powershell/profile.ps1`; CurrentHost does
  not load it again.
- The shared loader runs once per process and sources only numbered modules:
  environment, skim, proxy, aliases, Git helper and prompt.

## Skim

- `Ctrl+R` recalls history without executing the selected command.
- `Ctrl+T` inserts a quoted file path selected with skim and a bat preview.
- Neither uses PSFzf or an `fzf=sk` alias.

## Proxy

Private configuration stays at `.config/powershell/proxy.local.psd1`, outside
Git. Loading the module defines functions only; proxy is not automatically enabled.

## Starship

Configuration: `.config/starship.toml`.

The existing prompt format is preserved, with the stash symbol escaped correctly.
The previously unused ahead/behind counters remain unused.
