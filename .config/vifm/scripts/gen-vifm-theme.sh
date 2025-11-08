#!/usr/bin/env bash
set -euo pipefail

OUT="${HOME}/.config/vifm/colors/wezterm-theme.vifm"

BG="${THEME_BG:-#1e1e1e}"
FG="${THEME_FG:-#d4d4d4}"
ACC="${THEME_ACCENT:-#007acc}"
DIM="${THEME_DIM_FG:-#858585}"
BORDER="${THEME_BORDER:-#3c3c3c}"

cat >"$OUT" <<EOF
highlight Win         guifg=${FG} guibg=${BG}
highlight TopLine     guifg=${DIM} guibg=${BG}
highlight StatusLine  guifg=${FG} guibg=${BG} cterm=bold
highlight Border      guifg=${BORDER} guibg=${BG}
highlight Directory   guifg=${ACC} guibg=${BG} cterm=bold
highlight Link        guifg=${ACC} guibg=${BG}
highlight Selected    guifg=${BG} guibg=${ACC} cterm=bold
highlight Executable  guifg=#b5cea8 guibg=${BG}
highlight BrokenLink  guifg=#f44747 guibg=${BG}
EOF

