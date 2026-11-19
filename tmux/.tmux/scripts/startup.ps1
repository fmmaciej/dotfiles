$ErrorActionPreference = 'Stop'
$Session = $env:PSMUX_TARGET_SESSION
if ([string]::IsNullOrWhiteSpace($Session) -or $Session -match '[\\/:\x00]') {
    throw 'psmux startup: missing or invalid server session context.'
}
$SessionTarget = '=' + $Session

# PPM and its generated callbacks invoke psmux without -t. Supply a TMUX
# connection tied to this server's port, not whichever session was used last.
# Read only the public .port locator; never read the .key authentication file.
$DataRoot = if ($env:PSMUX_DATA_DIR) { $env:PSMUX_DATA_DIR } else { Join-Path $HOME '.psmux' }
$PortText = (Get-Content -LiteralPath (Join-Path $DataRoot "$Session.port") -Raw).Trim()
$Port = 0
if (-not [int]::TryParse($PortText, [ref]$Port) -or $Port -lt 1 -or $Port -gt 65535) {
    throw 'psmux startup: invalid server port locator.'
}
$SocketPath = & psmux -t $SessionTarget display-message -p '#{socket_path}'
if ($LASTEXITCODE -ne 0) { throw 'psmux startup: the originating server is unavailable.' }
if ([string]::IsNullOrWhiteSpace($SocketPath)) {
    # During initial config parsing no pane may exist yet. The native CLI uses
    # the port field for routing; this configuration uses the default namespace.
    $SocketPath = Join-Path $DataRoot 'default'
}
$env:TMUX = '{0},{1},0' -f $SocketPath, $Port
& psmux -t $SessionTarget set-environment -g TMUX $env:TMUX
if ($LASTEXITCODE -ne 0) { throw 'psmux startup: could not pin plugin callback routing.' }

$Ppm = Join-Path $HOME '.psmux/plugins/ppm/ppm.ps1'
if (Test-Path -LiteralPath $Ppm) { & $Ppm | Out-Null }

# A small native battery worker replaces tmux-battery. The official Windows
# plugin overrides prefix+b and status-interval, so do not load it here.
& psmux -t $SessionTarget run-shell -b '~/.tmux/scripts/battery.ps1'
if ($LASTEXITCODE -ne 0) { throw 'psmux startup: could not start the battery worker.' }
