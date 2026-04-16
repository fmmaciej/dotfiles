# fzf defaults

$env:FZF_DEFAULT_OPTS = "--layout=reverse --inline-info"

if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    $env:FZF_CTRL_T_OPTS = '--preview "bat --color=always --style=numbers {}"'
}
