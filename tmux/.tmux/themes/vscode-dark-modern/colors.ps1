# WezTerm is the palette owner. Defaults allow psmux to run outside WezTerm.
$ErrorActionPreference = 'Stop'
$Session = $env:PSMUX_TARGET_SESSION
if ([string]::IsNullOrWhiteSpace($Session)) { throw 'psmux theme: missing server session context.' }
$SessionTarget = '=' + $Session
function Get-ThemeColor {
    param([string] $Name, [string] $Fallback)
    $Value = [Environment]::GetEnvironmentVariable($Name)
    if ($Value -match '^#[0-9a-fA-F]{6}$') { return $Value }
    return $Fallback
}

$Bg = Get-ThemeColor THEME_BG '#1e1e1e'
$Fg = Get-ThemeColor THEME_FG '#d4d4d4'
$Accent = Get-ThemeColor THEME_ACCENT '#007acc'
$Dim = Get-ThemeColor THEME_DIM_FG '#858585'
$Border = Get-ThemeColor THEME_BORDER '#3c3c3c'
$Surface = Get-ThemeColor THEME_SURFACE_BG '#252526'
$ActiveFg = Get-ThemeColor THEME_ACTIVE_FG '#ffffff'

$Options = [ordered]@{
    '@bg' = $Bg
    '@fg' = $Fg
    '@accent' = $Accent
    '@dimfg' = $Dim
    'status-style' = "fg=$Fg,bg=$Bg"
    'window-status-style' = "fg=$Dim,bg=$Bg"
    'window-status-current-style' = "fg=$ActiveFg,bg=$Accent,bold"
    'pane-border-style' = "fg=$Border"
    'pane-active-border-style' = "fg=$Accent"
    'message-style' = "fg=$Fg,bg=$Surface"
    'mode-style' = "fg=$Fg,bg=$Surface"
    'clock-mode-colour' = $Accent
}
foreach ($Option in $Options.GetEnumerator()) {
    & psmux -t $SessionTarget set-option -g $Option.Key $Option.Value
    if ($LASTEXITCODE -ne 0) { throw "psmux: could not apply theme option $($Option.Key)" }
}
