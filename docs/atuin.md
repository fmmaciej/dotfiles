# Atuin

## History search

- `Ctrl+R` opens Atuin in PowerShell and Nushell.
- Selecting a command returns it to the prompt for review; it does not immediately
  execute it (`enter_accept = false`).
- Up Arrow keeps the shell's normal behavior; no AI key bindings are enabled.
- PowerShell keeps skim on `Ctrl+T`, plus PSReadLine/CompletionPredictor suggestions.
- If Atuin is missing or its initialization fails, PowerShell retains skim's
  `Ctrl+R` history fallback.

## Data and configuration

- Configuration: `$HOME\.config\atuin\config.toml`, linked with Stow.
- Shell integration sets `ATUIN_CONFIG_DIR` to that directory unless the user has
  already selected another directory.
- New interactive commands are recorded locally with Atuin's standard shell hooks.
  Existing PSReadLine/Nushell history is not deleted or automatically imported.
- Automatic synchronization and Atuin's own update checks are disabled. Bootstrap
  does not register an account, log in, upload history or connect an AI provider.
- History databases and account data stay outside the repository.

To explicitly import old PowerShell history once:

```powershell
atuin import powershell
```

Synchronization, if desired, is a separate user decision; review company policy
before synchronizing work commands.

## Setup and updates

Bootstrap/`dot update` installs or updates native Atuin through Scoop. Start a new
PowerShell after updating. Nushell receives the generated integration on its next
launch; see [Nushell](nushell.md).

[Official shell integration](https://docs.atuin.sh/latest/reference/init/)
