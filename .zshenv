# --- ~/.zshenv ---  (ładuje się zawsze)
# Używamy zshowej tablicy PATH (path) + deduplikacja
typeset -U path PATH

# Najpierw lokalne narzędzia użytkownika (uv/ty, pipx itd.)
path=("$HOME/.local/bin" $path)

# Homebrew (Apple Silicon)
path=("/opt/homebrew/bin" "/opt/homebrew/sbin" $path)

# TeX, VSCode CLI
path=("/Library/TeX/texbin" "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" $path)

# Cargo (jeśli używasz)
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
path=("$HOME/.cargo/bin" $path)

# Nagłówki/liby dla kompilatorów (tylko gdy faktycznie potrzebujesz)
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export LIBRARY_PATH="/opt/homebrew/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
export CPATH="/opt/homebrew/include${CPATH+:$CPATH}"

# Narzędzia CLI
export EDITOR="vim"
export TERMINAL="iTerm"
export BROWSER="Safari"

# Java (bez błędów gdy brak JDK)
export JAVA_HOME="$(
  /usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || printf ''
)"

# Preferowane locale (jeśli potrzebne)
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

