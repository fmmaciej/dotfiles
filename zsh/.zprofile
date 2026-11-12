# ~/.zprofile — inicjalizacja środowiska przy logowaniu.
# Zwykłe powłoki potomne dziedziczą przygotowane tutaj środowisko.

if [[ -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Preferuj odziedziczone JAVA_HOME; w nowej sesji wybierz Javę 21 lub domyślną.
if [[ -z "${JAVA_HOME:-}" && -x /usr/libexec/java_home ]]; then
  export JAVA_HOME="$(
    /usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || printf ''
  )"
fi
