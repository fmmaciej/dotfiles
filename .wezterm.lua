-- ~/.wezterm.lua

local wezterm = require 'wezterm'
local act = wezterm.action

-- ======================
-- Motyw / paleta
-- ======================
local ok, theme = pcall(require, 'colors.vscode_dark_modern')
if not ok then
  wezterm.log_error("Brak palety colors/vscode_dark_modern.lua — używam fallbacku Solarized Dark")

  theme = {
    colors = wezterm.color.get_builtin_schemes()["Builtin Solarized Dark"],
    env = function()
      return {
        THEME_BG     = "#002b36",
        THEME_FG     = "#eee8d5",
        THEME_CURSOR = "#93a1a1",
        THEME_ACCENT = "#268bd2",
        THEME_SEL_BG = "#073642",
        THEME_SEL_FG = "#eee8d5",
        THEME_DIM_FG = "#93a1a1",
        THEME_BORDER = "#073642",
      }
    end,
  }
end

-- Moduł motywu nie zdefiniował env()
if type(theme.env) ~= "function" then
  theme.env = function()
    return {}
  end
end

local colors = theme.colors or {}
local bg = colors.background or "#000000"
local window_decorations = "TITLE|RESIZE"

-- ======================
-- Config builder
-- ======================
local config = wezterm.config_builder()

-- paleta + zmienne środowiskowe dla narzędzi terminalowych
config.colors = colors
config.set_environment_variables = theme.env()

-- ======================
-- Focus mode (minimalny tryb)
-- ======================
local focus_on = false

wezterm.on("toggle-focus-mode", function(window, _)
  focus_on = not focus_on

  if focus_on then
    window:set_config_overrides({
      window_background_opacity = 1.0,
      enable_tab_bar = false,
      window_decorations = window_decorations,
      window_padding = { left = 2, right = 2, top = 1, bottom = 1 },
    })
  else
    -- wróć do globalnego configu (czyli tego, co poniżej)
    window:set_config_overrides({})
  end
end)

-- ======================
-- Prawy status (focus + bateria + czas)
-- ======================
wezterm.on("update-right-status", function(window, _)
  local parts = {}

  if focus_on then
    table.insert(parts, wezterm.format({
      { Foreground = { Color = "#87cefa" } }, { Text = " [FOCUS] " },
      { Foreground = { Color = "#808080" } }, { Text = "│" },
    }))
  end

  local bat = wezterm.battery_info()
  if bat and #bat > 0 then
    local b = bat[1]
    local pct = math.floor((b.state_of_charge or 0) * 100 + 0.5)
    local icon = (b.state == "Charging") and "⚡"
      or (pct <= 15 and "🪫" or "🔋")
    local col  = (pct <= 15 and "#ff5555")
      or (pct <= 30 and "#f1fa8c")
      or "#e0e0e0"

    table.insert(parts, wezterm.format({
      { Foreground = { Color = col } }, { Text = (" " .. icon .. " " .. pct .. "% ") },
      { Foreground = { Color = "#808080" } }, { Text = "│" },
    }))
  end

  table.insert(parts, " " .. wezterm.strftime("%d.%m.%Y %H:%M ") .. " ")
  window:set_right_status(table.concat(parts))
end)

-- ======================
-- Wygląd okna
-- ======================
config.window_background_opacity = 1.0
config.text_background_opacity   = 1.0

config.window_decorations = window_decorations
config.enable_tab_bar = false
config.use_fancy_tab_bar = false

config.window_padding = {
  left = 6, right = 6, top = 4, bottom = 4,
}

config.window_frame = {
  font = wezterm.font{ family = "SF Mono", weight = "Regular" },
  font_size = 14.0,
  active_titlebar_bg = bg,
  inactive_titlebar_bg = bg,
}

-- ======================
-- Render / wydajność
-- ======================
config.front_end = "WebGpu"
config.animation_fps = 120
config.max_fps = 120
config.automatically_reload_config = true

-- ======================
-- Font
-- ======================
config.font = wezterm.font_with_fallback({
  { family = "SF Mono",          weight = "Regular" },
  { family = "Cascadia Mono",    weight = "Regular" },
  { family = "Symbols Nerd Font", weight = "Regular" },
})

config.font_size  = 14.0
config.line_height = 1.05

-- ======================
-- Kursor, scrollback
-- ======================
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate    = 500
config.scrollback_lines     = 100000

-- ======================
-- Start
-- ======================
config.default_prog = { "pwsh.exe", "-NoLogo" }

config.launch_menu = {
  {
    label = "Windows PowerShell",
    args = { "powershell.exe", "-NoLogo" },
  },
}

-- ======================
-- Skróty
-- ======================
config.keys = {
  { key = "K",     mods = "CMD", action = act.EmitEvent("toggle-focus-mode") },
  { key = "Enter", mods = "CMD", action = "ToggleFullScreen" },
  { key = "n",     mods = "CMD", action = "SpawnWindow" },
  { key = "w",     mods = "CMD", action = act.CloseCurrentTab { confirm = true } },
}

return config
