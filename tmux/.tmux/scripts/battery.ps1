# One worker per server; reloading config must not start duplicate polling loops.
# No files, scheduled tasks or boot-time services are created.
$ErrorActionPreference = 'Stop'
$Target = $env:PSMUX_TARGET_SESSION
if (-not $Target) { return }
$SessionTarget = '=' + $Target
$MutexName = 'Local\dotfiles-psmux-battery-' + ($Target -replace '[^a-zA-Z0-9_-]', '_')
$Mutex = [System.Threading.Mutex]::new($false, $MutexName)
$OwnsMutex = $false
try {
    try { $OwnsMutex = $Mutex.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $OwnsMutex = $true }
    if (-not $OwnsMutex) { return }
    while ($true) {
        & psmux -t $SessionTarget has-session 2>$null
        if ($LASTEXITCODE -ne 0) { break }
        $Battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        $Display = ''
        if ($Battery) {
            $State = switch ($Battery.BatteryStatus) {
                2 { '+' }
                3 { '=' }
                default { '-' }
            }
            $Display = '{0}{1}%' -f $State, $Battery.EstimatedChargeRemaining
            if ($Battery.BatteryStatus -eq 1 -and $Battery.EstimatedRunTime -gt 0 -and $Battery.EstimatedRunTime -lt 71582788) {
                $Display += ' {0}h{1:00}m' -f [math]::Floor($Battery.EstimatedRunTime / 60), ($Battery.EstimatedRunTime % 60)
            }
        }
        & psmux -t $SessionTarget set-option -g '@battery_display' $Display
        if ($LASTEXITCODE -ne 0) { break }
        Start-Sleep -Seconds 30
    }
} finally {
    if ($OwnsMutex) { $Mutex.ReleaseMutex() }
    $Mutex.Dispose()
}
