local wezterm = require 'wezterm'
local act = wezterm.action

-- === Ładowanie motywu z modułu ===
local ok, theme = pcall(require, 'colors.vscode_dark_modern')
if not ok then
  wezterm.log_error("Brak palety colors/vscode_dark_modern.lua — używam domyślnej")
  theme = { colors = wezterm.color.get_builtin_schemes()["Builtin Solarized Dark"] }
  -- Minimalny fallback env:
  theme.env = function()
    return {
      THEME_BG = "#002b36", THEME_FG = "#eee8d5",
      THEME_CURSOR = "#93a1a1", THEME_ACCENT = "#268bd2",
      THEME_SEL_BG = "#073642", THEME_SEL_FG = "#eee8d5",
      THEME_DIM_FG = "#93a1a1", THEME_BORDER = "#073642",
    }
  end
end

local colors = theme.colors

-- wykrywanie tmuxa
local function in_tmux(pane)
  local p = pane:get_foreground_process_name() or ""
  return p:match("tmux") ~= nil
end

-- Focus mode toggle + wskaźnik
local focus_on = false
wezterm.on("toggle-focus-mode", function(window, _)
  focus_on = not focus_on
  if focus_on then
    window:set_config_overrides({
      window_background_opacity = 1.0,
      enable_tab_bar = false,
      window_decorations = "RESIZE",
      window_padding = { left=2, right=2, top=1, bottom=1 },
    })
  else
    window:set_config_overrides({})
  end
end)

-- Prawy status: [FOCUS] + bateria + data
wezterm.on("update-right-status", function(window, _)
  local parts = {}

  if focus_on then
    table.insert(parts, wezterm.format({
      {Foreground={Color="#87cefa"}}, {Text=" [FOCUS] "},
      {Foreground={Color="#808080"}}, {Text="│"},
    }))
  end

  local bat = wezterm.battery_info()
  if bat and #bat > 0 then
    local b = bat[1]
    local pct = math.floor((b.state_of_charge or 0)*100 + 0.5)
    local icon = (b.state == "Charging") and "⚡" or (pct<=15 and "🪫" or "🔋")
    local col  = (pct<=15 and "#ff5555") or (pct<=30 and "#f1fa8c") or "#e0e0e0"
    table.insert(parts, wezterm.format({
      {Foreground={Color=col}}, {Text=(" "..icon.." "..pct.."% ")},
      {Foreground={Color="#808080"}}, {Text="│"},
    }))
  end

  table.insert(parts, " "..wezterm.strftime("%d.%m.%Y %H:%M ").." ")
  window:set_right_status(table.concat(parts))
end)

return {
  -- paleta + eksport do środowiska (tmux/vifm)
  colors = colors,

  set_environment_variables = theme.env(),

  -- wygląd okna
    window_background_opacity = 1.0,
  text_background_opacity = 1.0,
  window_decorations = "RESIZE",
  enable_tab_bar = false,
  use_fancy_tab_bar = false,
  window_padding = { left=6, right=6, top=4, bottom=4 },
  window_frame = {
    font = wezterm.font{ family="SF Mono", weight="Regular" },
    font_size = 12.0,
    active_titlebar_bg = colors.background,
    inactive_titlebar_bg = colors.background,
  },

  -- render / wydajność
  front_end = "WebGpu",
  animation_fps = 120,
  max_fps = 120,
  automatically_reload_config = true,

  -- font
  font = wezterm.font_with_fallback({
    "SF Mono","SF Mono Regular","SF Mono Medium","Symbols Nerd Font",
  }),
  font_size = 13.5,
  line_height = 1.05,

  -- kursor, scrollback
  default_cursor_style = "SteadyBlock",
  cursor_blink_rate = 0,
  scrollback_lines = 100000,

  -- start przez fzf (wybór/attach/new tmux)
  default_prog = {"/bin/zsh","-lc","~/.config/wezterm/tmux-session.sh"},

  -- skróty
  keys = {
    {key="K", mods="CMD", action=act.EmitEvent("toggle-focus-mode")},
    {key="Enter", mods="CMD", action="ToggleFullScreen"},
    {key="n", mods="CMD", action="SpawnWindow"},
    {key="w", mods="CMD", action=act.CloseCurrentTab{confirm=true}},
  },
}

