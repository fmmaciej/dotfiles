# Development fixtures only: no real psmux, CIM, clipboard or plugin is executed.
$ErrorActionPreference = 'Stop'
$Repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Scripts = Join-Path $Repository 'tmux/.tmux/scripts'
$Fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-psmux-test-' + [guid]::NewGuid().ToString('N'))
$OriginalHome = $HOME
$SavedEnvironment = @{}
foreach ($Name in @('PSMUX_TARGET_SESSION', 'PSMUX_DATA_DIR', 'TMUX')) {
    $SavedEnvironment[$Name] = [Environment]::GetEnvironmentVariable($Name)
}

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$global:DotfilesPsmuxTest = @{
    Calls = [Collections.Generic.List[object]]::new()
    Alive = $true
    FailPaste = $false
    EmptySocket = $false
    Clipboard = "synthetic 'quotes'; not a command`nsecond line"
    BufferFiles = [Collections.Generic.List[string]]::new()
}
try {
    New-Item -ItemType Directory -Path $Fixture | Out-Null
    Set-Variable -Name HOME -Value $Fixture -Force
    $env:PSMUX_DATA_DIR = Join-Path $Fixture 'registry with spaces'
    New-Item -ItemType Directory -Path $env:PSMUX_DATA_DIR | Out-Null
    Set-Content -LiteralPath (Join-Path $env:PSMUX_DATA_DIR 'session-a.port') -Value '31001'
    Set-Content -LiteralPath (Join-Path $env:PSMUX_DATA_DIR 'session-b.port') -Value '31002'
    $env:PSMUX_TARGET_SESSION = 'session-a'
    $env:TMUX = 'synthetic/other,31002,0' # another session was used most recently

    function global:psmux {
        $State = $global:DotfilesPsmuxTest
        $State.Calls.Add(@($args))
        $global:LASTEXITCODE = 0
        if ($args[0] -ne '-t') {
            # Model PPM's implicit calls: its TMUX must select the originating
            # server rather than the unrelated most-recent session B.
            Assert-True (($env:TMUX -split ',')[1] -eq '31001') 'Plugin call would reach the wrong server'
            $State.PluginSession = 'session-a'
            return
        }
        Assert-True ($args[1] -eq '=session-a') 'Helper escaped the exact session target'
        $Command = $args[2]
        if (-not $State.Alive) { $global:LASTEXITCODE = 1; return }
        switch ($Command) {
            'display-message' {
                if (-not $State.EmptySocket) { Join-Path $env:PSMUX_DATA_DIR 'default' }
            }
            'set-environment' { $State.CallbackTmux = $args[5] }
            'load-buffer' {
                $Path = $args[5]
                $State.BufferFiles.Add($Path)
                Assert-True ([IO.File]::ReadAllText($Path) -eq $State.Clipboard) 'Clipboard text was changed'
                $State.LoadedBuffer = $args[4]
            }
            'paste-buffer' {
                Assert-True ($args[5] -eq $State.LoadedBuffer) 'Paste used another invocation buffer'
                Assert-True ($args[6] -eq '-t' -and $args[7] -eq '%7') 'Paste did not retain the captured pane'
                if ($State.FailPaste) { $global:LASTEXITCODE = 1 }
            }
            'run-shell' { $State.WorkerTarget = $args[1] }
        }
    }
    function global:Get-Clipboard { param([switch] $Raw) $global:DotfilesPsmuxTest.Clipboard }
    function global:Get-CimInstance {
        param([string] $ClassName, [object] $ErrorAction)
        [pscustomobject]@{ BatteryStatus = 1; EstimatedChargeRemaining = 60; EstimatedRunTime = 125 }
    }
    function global:Start-Sleep {
        param([int] $Seconds)
        $global:DotfilesPsmuxTest.Alive = $false # stop after one iteration; never sleep
    }

    $PpmDirectory = Join-Path $HOME '.psmux/plugins/ppm'
    New-Item -ItemType Directory -Path $PpmDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $PpmDirectory 'ppm.ps1') -Value 'psmux set-option -g @synthetic-plugin yes'
    & (Join-Path $Scripts 'startup.ps1')
    Assert-True ($global:DotfilesPsmuxTest.PluginSession -eq 'session-a') 'PPM startup was not pinned'
    Assert-True (($global:DotfilesPsmuxTest.CallbackTmux -split ',')[1] -eq '31001') 'Later plugin callbacks would not inherit server A'
    Assert-True ($global:DotfilesPsmuxTest.WorkerTarget -eq '=session-a') 'Worker startup was not pinned'

    $global:DotfilesPsmuxTest.EmptySocket = $true
    & (Join-Path $Scripts 'startup.ps1')
    Assert-True (($env:TMUX -split ',')[1] -eq '31001') 'Initial config without a pane lost its server context'

    & (Join-Path $Scripts 'paste.ps1') -Pane '%7'
    $FirstBuffer = $global:DotfilesPsmuxTest.LoadedBuffer
    & (Join-Path $Scripts 'paste.ps1') -Pane '%7'
    Assert-True ($FirstBuffer -ne $global:DotfilesPsmuxTest.LoadedBuffer) 'Concurrent clipboard operations would share a buffer'
    $global:DotfilesPsmuxTest.FailPaste = $true
    $Rejected = $false
    try { & (Join-Path $Scripts 'paste.ps1') -Pane '%7' } catch { $Rejected = $true }
    Assert-True $Rejected 'Paste failure was ignored'
    Assert-True ($global:DotfilesPsmuxTest.Calls[-1][2] -eq 'delete-buffer') 'Failed paste did not clean up its own buffer'
    $global:DotfilesPsmuxTest.FailPaste = $false

    & (Join-Path $Scripts 'battery.ps1')
    Assert-True (@($global:DotfilesPsmuxTest.Calls | Where-Object { $_[2] -eq 'set-option' -and $_[4] -eq '@battery_display' }).Count -eq 1) 'Battery worker did not update exactly its own session'

    # A missing server must fail closed, never use most-recent session B.
    $Before = $global:DotfilesPsmuxTest.Calls.Count
    $Rejected = $false
    try { & (Join-Path $Scripts 'paste.ps1') -Pane '%7' } catch { $Rejected = $true }
    Assert-True $Rejected 'Missing source server should reject paste'
    Assert-True ($global:DotfilesPsmuxTest.Calls.Count -eq $Before + 1) 'Missing server should not reach paste-buffer'
    $Before = $global:DotfilesPsmuxTest.Calls.Count
    & (Join-Path $Scripts 'battery.ps1')
    Assert-True ($global:DotfilesPsmuxTest.Calls.Count -eq $Before + 1 -and $global:DotfilesPsmuxTest.Calls[-1][2] -eq 'has-session') 'Battery should stop with its own server, not follow session B'
    foreach ($Script in @((Join-Path $Scripts 'startup.ps1'), (Join-Path $Repository 'tmux/.tmux/themes/vscode-dark-modern/colors.ps1'))) {
        $Before = $global:DotfilesPsmuxTest.Calls.Count
        $Rejected = $false
        try { & $Script } catch { $Rejected = $true }
        Assert-True ($Rejected -and $global:DotfilesPsmuxTest.Calls.Count -eq $Before + 1) 'A closed server should not be replaced by another target'
    }
    $env:PSMUX_TARGET_SESSION = ''
    $Before = $global:DotfilesPsmuxTest.Calls.Count
    $Rejected = $false
    try { & (Join-Path $Scripts 'paste.ps1') -Pane '%7' } catch { $Rejected = $true }
    Assert-True ($Rejected -and $global:DotfilesPsmuxTest.Calls.Count -eq $Before) 'Missing context should not invoke psmux'
    foreach ($Path in $global:DotfilesPsmuxTest.BufferFiles) {
        Assert-True (-not (Test-Path -LiteralPath $Path)) 'Temporary clipboard file was left behind'
    }
    Write-Output 'PASS: explicit session/pane targets, isolated clipboard buffers, closed-server rejection, battery routing and PPM startup/callback context'
} finally {
    Set-Variable -Name HOME -Value $OriginalHome -Force
    foreach ($Name in $SavedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($Name, $SavedEnvironment[$Name])
    }
    foreach ($Name in @('psmux', 'Get-Clipboard', 'Get-CimInstance', 'Start-Sleep')) {
        Remove-Item -LiteralPath "Function:global:$Name" -ErrorAction SilentlyContinue
    }
    Remove-Variable -Scope Global -Name DotfilesPsmuxTest -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -LiteralPath $Fixture -Recurse -Force }
}
