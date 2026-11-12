# Prosty punkt wejścia do instancji; funkcja pozwala `kei open` zmienić katalog.

unalias kei 2>/dev/null

kei() {
  local root="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/maciej.haj@icloud.com/Kei/kei-maciej"

  case "${1:-help}" in
    help|-h|--help)
      cat <<'EOF'
 _  _______ ___
| |/ / ____|_ _|
| ' /|  _|  | |
| . \| |___ | |
|_|\_\_____|___|

kei open        Change to the Kei directory
kei run [args]  Run OpenCode in Kei
kei edit        Open Kei in VS Code
kei help        Show this help
EOF
      ;;

    open)
      cd -- "$root"
      ;;

    run)
      shift
      (cd -- "$root" && command opencode "$@")
      ;;

    edit)
      command code "$root"
      ;;

    *)
      printf 'kei: unknown command: %s\n' "$1" >&2
      kei help >&2
      return 2
      ;;

  esac
}
