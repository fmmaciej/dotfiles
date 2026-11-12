# ~/.zshenv — wspólne środowisko dla każdej powłoki Zsh, także skryptów.
# Bez uruchamiania zewnętrznych programów; inicjalizacja loginowa w .zprofile.

export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# Unikalne wpisy, także po ponownym załadowaniu konfiguracji.
typeset -U path PATH
path=(
  "$CARGO_HOME/bin"
  "/Library/TeX/texbin"
  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  "$HOME/.local/bin"
  $path
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/cmdline-tools/latest/bin"
)

# Zachowaj istniejące ścieżki kompilatora bez dokładania duplikatów.
if [[ ":${PKG_CONFIG_PATH-}:" != *:/opt/homebrew/lib/pkgconfig:* ]]; then
  PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
fi
if [[ ":${LIBRARY_PATH-}:" != *:/opt/homebrew/lib:* ]]; then
  LIBRARY_PATH="/opt/homebrew/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
fi
if [[ ":${CPATH-}:" != *:/opt/homebrew/include:* ]]; then
  CPATH="/opt/homebrew/include${CPATH+:$CPATH}"
fi
export PKG_CONFIG_PATH LIBRARY_PATH CPATH

export EDITOR="vim"
export TERMINAL="wezterm"
export BROWSER="Safari"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
