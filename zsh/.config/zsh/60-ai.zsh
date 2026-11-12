typeset -gA CC_MODELS

CC_MODELS=(
  main       "anthropic/claude-sonnet-4.6"
  deep       "anthropic/claude-opus-4.6"
  cheap      "anthropic/claude-haiku-4.5"
  cheap-qwen "qwen/qwen3-coder-next"
)

cc() {
  local profile="${1:-main}"

  if [[ "$profile" == "list" ]]; then
    echo "Available profiles:"
    local name
    for name in ${(ok)CC_MODELS}; do
      printf "  %-12s %s\n" "$name" "${CC_MODELS[$name]}"
    done
    return 0
  fi

  shift || true

  if [[ -z "${CC_MODELS[$profile]}" ]]; then
    echo "Unknown profile: $profile" >&2
    echo "Use one of:" >&2
    local name
    for name in ${(ok)CC_MODELS}; do
      printf "  %s\n" "$name" >&2
    done
    echo "  list" >&2
    return 1
  fi

  ANTHROPIC_MODEL="${CC_MODELS[$profile]}" claude "$@"
}

