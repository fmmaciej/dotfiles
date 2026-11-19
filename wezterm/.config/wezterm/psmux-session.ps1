# WezTerm startup: choose/attach/create, without depending on the shell profile.
$ErrorActionPreference = 'Stop'
$Config = Join-Path $HOME '.tmux.conf'
if ($env:PSMUX_ACTIVE -eq '1' -or -not (Get-Command psmux -ErrorAction SilentlyContinue)) {
    Write-Warning 'psmux is unavailable or already active; starting a plain PowerShell.'
    & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -Command ". (Join-Path `$HOME '.config/powershell/profile.ps1')"
    exit $LASTEXITCODE
}

$Sessions = @(& psmux -f $Config list-sessions -F '#{session_name}' 2>$null)
if ($LASTEXITCODE -ne 0) { $Sessions = @() }
if ($Sessions.Count -eq 0 -or -not (Get-Command sk -ErrorAction SilentlyContinue)) {
    & psmux -f $Config new-session -A -s main
    exit $LASTEXITCODE
}

$Choices = @('0  [NEW] Create new session')
for ($Index = 0; $Index -lt $Sessions.Count; $Index++) {
    $Choices += '{0}  {1}' -f ($Index + 1), $Sessions[$Index]
}
$Selected = $Choices | & sk --layout=reverse --height=40% --border --delimiter '  ' --with-nth '2..' --prompt 'psmux session> '
if ($LASTEXITCODE -ne 0 -or $Selected -notmatch '^(\d+)  ') {
    # Cancellation must not try to create a second session named main.
    & psmux -f $Config new-session -A -s main
} elseif ([int]$Matches[1] -eq 0) {
    $Name = Read-Host 'New session name [main]'
    if ([string]::IsNullOrWhiteSpace($Name)) { $Name = 'main' }
    if ($Name -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use letters, numbers, hyphens or underscores in a session name.' }
    & psmux -f $Config new-session -A -s $Name
} else {
    $Name = $Sessions[[int]$Matches[1] - 1]
    & psmux -f $Config attach-session -t $Name
}
exit $LASTEXITCODE
