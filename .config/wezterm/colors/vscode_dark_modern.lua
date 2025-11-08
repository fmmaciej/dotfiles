-- VS Code Dark Modern palette
local M = {}

M.colors = {
  foreground = "#d4d4d4",
  background = "#1e1e1e",
  cursor_bg  = "#aeafad",
  cursor_border = "#aeafad",
  cursor_fg  = "#1e1e1e",
  selection_bg = "#264f78",
  selection_fg = "#d4d4d4",
  ansi = {
    "#000000","#f44747","#6a9955","#d7ba7d",
    "#569cd6","#c586c0","#4ec9b0","#d4d4d4",
  },
  brights = {
    "#666666","#f44747","#b5cea8","#dcdcaa",
    "#9cdcfe","#c586c0","#4fc1ff","#ffffff",
  },
  tab_bar = {
    background = "#1e1e1e",
    active_tab = { bg_color="#252526", fg_color="#d4d4d4" },
    inactive_tab = { bg_color="#1e1e1e", fg_color="#858585" },
    inactive_tab_hover = { bg_color="#2a2a2a", fg_color="#d4d4d4" },
    new_tab = { bg_color="#1e1e1e", fg_color="#858585" },
    new_tab_hover = { bg_color="#2a2a2a", fg_color="#d4d4d4" },
  },
}

-- tmux/vifm
function M.env()
  return {
    THEME_BG      = M.colors.background,
    THEME_FG      = M.colors.foreground,
    THEME_CURSOR  = M.colors.cursor_bg,
    THEME_ACCENT  = "#007acc",
    THEME_SEL_BG  = M.colors.selection_bg,
    THEME_SEL_FG  = M.colors.selection_fg,
    THEME_DIM_FG  = "#858585",
    THEME_BORDER  = "#3c3c3c",
  }
end

return M

