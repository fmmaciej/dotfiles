# Vim

## Files and plugins

- Entry points: `.vimrc` and `_vimrc`.
- vim-plug: `$HOME/vimfiles/autoload/plug.vim`.
- Plugins: `$HOME/vimfiles/plugged`.
- Bootstrap installs the five configured plugins; it does not update existing ones.
- CodeDark, Airline, surround, NERDTree and the existing editing settings are kept.

## Clipboard

Normal yank/paste uses the system clipboard:

```vim
set clipboard=unnamed,unnamedplus
```

No extra leader+p mapping is needed.

## Theme

Vim uses CodeDark when installed. Until the plugin is available, it uses the
default theme instead of reporting a missing-colorscheme error.
