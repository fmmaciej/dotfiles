$env:EDITOR = 'vim'
$env:TERMINAL = 'wezterm'
$env:STARSHIP_CONFIG = Join-Path $HOME '.config/starship.toml'
$env:YAZI_CONFIG_HOME = Join-Path $HOME '.config/yazi'

# Scoop Git ships file.exe without exposing it as a native command shim.
if (-not $env:YAZI_FILE_ONE -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
    $GitPrefix = & scoop prefix git 2>$null
    if ($LASTEXITCODE -eq 0 -and $GitPrefix) {
        $FileOne = Join-Path ($GitPrefix | Select-Object -Last 1) 'usr/bin/file.exe'
        if (Test-Path -LiteralPath $FileOne) { $env:YAZI_FILE_ONE = $FileOne }
    }
}
