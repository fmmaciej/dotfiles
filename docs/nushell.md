# Optional Nushell

## Launch

From PowerShell:

```powershell
nu
```

Return to PowerShell with:

```nu
exit
```

- `nu` is Scoop's normal Nushell executable, not an alias or wrapper.
- PowerShell remains the default for WezTerm, psmux sessions and new panes.
- No startup profile automatically enters Nu or changes the Windows default shell.
- Nushell uses its own syntax, prompt and configuration. PowerShell functions such
  as `dot update` and `proxy-on` remain PowerShell commands; Nu inherits environment
  variables, including proxy settings, from its parent process.

## Atuin

- `Ctrl+R` opens [Atuin](atuin.md); Up Arrow remains unchanged.
- Bootstrap asks `nu --no-config-file` for its user-data directory, then generates
  `vendor/autoload/dotfiles-atuin.nu` there with `atuin init nu`.
- Native Nu autoload loads this integration on launch. No edits to an existing
  `config.nu` or `env.nu`, shell replacement, history import or account login occur.
- `dot update`, run from PowerShell, updates Nu and Atuin and refreshes this
  generated file. Other autoload files are preserved.

[Nushell configuration and autoload](https://www.nushell.sh/book/configuration.html)
