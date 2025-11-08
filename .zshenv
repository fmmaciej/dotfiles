# --- ~/.zshenv ---  (ładuje się zawsze)
typeset -U path PATH

path=("$HOME/.local/bin" $path)

# Homebrew
path=("/opt/homebrew/bin" "/opt/homebrew/sbin" $path)

# LaTeX
path=("/Library/TeX/texbin" "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $path)

# Rust
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
path=("$HOME/.cargo/bin" $path)

# Nagłówki/liby dla kompilatorów
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export LIBRARY_PATH="/opt/homebrew/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
export CPATH="/opt/homebrew/include${CPATH+:$CPATH}"

# Tools
export EDITOR="vim"
export TERMINAL="wezterm"
export BROWSER="Safari"

# Java
export JAVA_HOME="$(
  /usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || printf ''
)"

# Preferowane locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

