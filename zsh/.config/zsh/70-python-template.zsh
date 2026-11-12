# Python project template helper

export PYTHON_TEMPLATE_DIR

pt() {
  if [[ -z "$PYTHON_TEMPLATE_DIR" ]]; then
    print -u2 "python-template: set PYTHON_TEMPLATE_DIR in ~/.config/zsh/env.local"
    return 1
  fi

  if [[ ! -d "$PYTHON_TEMPLATE_DIR" ]]; then
    print -u2 "python-template: template directory not found: $PYTHON_TEMPLATE_DIR"
    return 1
  fi

  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    (
      cd "$PYTHON_TEMPLATE_DIR" || exit 1
      just help |
        sed \
          -e 's/^python-template$/pt/' \
          -e 's/This repository is a Copier template. Use it to generate a new Python project; it is not the generated app itself./This shell helper wraps the local python-template Copier project. Use pt from any directory to generate a new Python project./' \
          -e 's/just copier copy \. /pt /g' \
          -e 's/pt \.\.\//pt /g' \
          -e 's/ --trust//g'
    )
    return
  fi

  local target="$1"
  local caller_dir="$PWD"
  local trust_args=(--trust)
  shift

  if [[ "$target" != /* ]]; then
    target="$caller_dir/$target"
  fi

  local template_source
  template_source="$(mktemp -d "${TMPDIR:-/tmp}/python-template.XXXXXX")" || return 1

  if (( ${@[(Ie)--trust]} || ${@[(Ie)--UNSAFE]} )); then
    trust_args=()
  fi

  (
    trap 'rm -rf "$template_source"' EXIT
    cd "$PYTHON_TEMPLATE_DIR" || exit 1
    rsync -a ./ "$template_source"/ \
      --exclude .git \
      --exclude .venv \
      --exclude .mypy_cache \
      --exclude .pytest_cache \
      --exclude .ruff_cache \
      --exclude __pycache__ \
      --exclude examples
    just copier copy "$template_source" "$target" "${trust_args[@]}" "$@"
  )
}
