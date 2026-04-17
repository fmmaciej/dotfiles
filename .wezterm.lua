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
  font = wezterm.font{ family = "Cascadia Mono", weight = "Regular" },
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
local powershell_profile = "$p = Join-Path $HOME '.config/powershell/profile.ps1'; if (Test-Path -LiteralPath $p) { . $p }"

local function has_executable(name)
  local ok = wezterm.run_child_process({ "where.exe", name })
  return ok
end

local powershell_exe = has_executable("pwsh.exe") and "pwsh.exe" or "powershell.exe"

config.default_prog = {
  powershell_exe,
  "-NoLogo",
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-NoExit",
  "-Command",
  powershell_profile,
}

config.launch_menu = {
  {
    label = "Windows PowerShell",
    args = {
      "powershell.exe",
      "-NoLogo",
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-NoExit",
      "-Command",
      powershell_profile,
    },
  },
}

-- ======================
-- Skróty
-- ======================
config.leader = {
  key = 'a',
  mods = 'CTRL',
  timeout_milliseconds = 1000,
}

config.keys = {
  -- fullscreen
  { key = 'Enter', mods = 'LEADER', action = act.ToggleFullScreen },

  -- tabs
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'w', mods = 'LEADER', action = act.CloseCurrentTab { confirm = true } },

  -- skok do tabów 1..9
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
  { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
  { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
  { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
  { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },

  -- splity jak w tmux
  { key = '%', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '"', mods = 'LEADER|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- poruszanie się między panelami
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- zmiana rozmiaru paneli
  { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- zoom / zamykanie pane
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- launcher
  { key = 's', mods = 'LEADER', action = act.ShowLauncher },

  -- kopiowanie jak w terminalach
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
}

return config
