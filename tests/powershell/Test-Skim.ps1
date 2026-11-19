# Exercise the real Ctrl+T body with fake process/ReadLine endpoints only.
# No terminal application, private history, user profile or command is executed.
$ErrorActionPreference = 'Stop'
$Repository = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

Add-Type @'
using System.Collections.Generic;
public static class DotfilesSkimTestReadLine {
    public static string Buffer;
    public static int Cursor;
    public static int Prompts;
    public static readonly List<string> Insertions = new List<string>();
    public static void Reset() {
        Buffer = "vim  --readonly";
        Cursor = 4;
        Prompts = 0;
        Insertions.Clear();
    }
    public static void Insert(string value) {
        Insertions.Add(value);
        Buffer = Buffer.Insert(Cursor, value);
        Cursor += value.Length;
    }
    public static void InvokePrompt() { Prompts++; }
}
'@

$Fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-skim-test-' + [guid]::NewGuid().ToString('N'))
$SavedLocation = Get-Location
$SavedCommand = $env:SKIM_DEFAULT_COMMAND
$SavedOptions = $env:SKIM_DEFAULT_OPTIONS
$script:BatAvailable = $true
$script:Handler = $null

function Get-Command {
    param([string] $Name, [object] $CommandType, [object] $ErrorAction)
    if ($Name -eq 'sk') { return [pscustomobject]@{ Source = (Join-Path $Fixture 'tools with spaces/sk.exe') } }
    if ($Name -eq 'bat' -and $script:BatAvailable) { return [pscustomobject]@{ Name = 'bat' } }
}
function Get-Module {
    param([string] $Name, [switch] $ListAvailable)
    if ($Name -eq 'PSReadLine') { [pscustomobject]@{ Name = $Name } }
}
function Import-Module { param([string] $Name) }
function Set-PSReadLineKeyHandler {
    param([string] $Chord, [string] $BriefDescription, [string] $LongDescription, [scriptblock] $ScriptBlock)
    if ($Chord -eq 'Ctrl+t') { $script:Handler = $ScriptBlock }
}

function New-SkimProcessMock {
    param([string] $Output, [int] $ExitCode = 0, [switch] $StartFails)
    $Reader = [pscustomobject]@{ Output = $Output }
    $Reader | Add-Member -MemberType ScriptMethod -Name ReadToEnd -Value { return $this.Output }
    $Mock = [pscustomobject]@{
        StartInfo = [Diagnostics.ProcessStartInfo]::new()
        StandardOutput = $Reader
        ExitCode = $ExitCode
        StartFails = [bool] $StartFails
        Started = $false
        Waited = $false
        Disposed = $false
    }
    $Mock | Add-Member -MemberType ScriptMethod -Name Start -Value {
        if ($this.StartFails) { throw 'synthetic skim startup failure' }
        $this.Started = $true
        return $true
    }
    $Mock | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { $this.Waited = $true }
    $Mock | Add-Member -MemberType ScriptMethod -Name Dispose -Value { $this.Disposed = $true }
    return $Mock
}

try {
    $Directory = Join-Path $Fixture 'caller directory with spaces'
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    Set-Location -LiteralPath $Directory
    . (Join-Path $Repository 'powershell/.config/powershell/20-skim.ps1')
    Assert-True ($null -ne $script:Handler) 'Ctrl+T was not registered'
    $Body = $script:Handler.ToString()
    Assert-True ($Body.Contains('[Diagnostics.Process]::new()')) 'Ctrl+T must use a direct process'
    Assert-True ($Body -notmatch '&\s+(fd|sk)\b|AcceptLine\(') 'Do not execute a native pipeline or accept the edited command'
    # Test substitutions only: all argument, result and cleanup logic is unchanged.
    $Body = $Body.Replace('[Diagnostics.Process]::new()', '$script:FakeProcess')
    $Body = $Body.Replace('[Microsoft.PowerShell.PSConsoleReadLine]', '[DotfilesSkimTestReadLine]')
    $Handler = [scriptblock]::Create($Body)

    [DotfilesSkimTestReadLine]::Reset()
    $script:FakeProcess = New-SkimProcessMock -Output "C:\files with spaces\it's-żółć.txt`r`n"
    $global:LASTEXITCODE = 42
    & $Handler
    Assert-True ([DotfilesSkimTestReadLine]::Buffer -eq "vim 'C:\files with spaces\it''s-żółć.txt' --readonly") 'Insert a safely quoted UTF-8 path at the cursor, preserving existing text'
    Assert-True ([DotfilesSkimTestReadLine]::Insertions.Count -eq 1) 'Insert the selected path exactly once'
    Assert-True ([DotfilesSkimTestReadLine]::Prompts -eq 1 -and $script:FakeProcess.Disposed) 'Dispose and redraw after selection'
    Assert-True ($script:FakeProcess.Started -and $script:FakeProcess.Waited) 'Start the process and wait for completion'
    $Info = $script:FakeProcess.StartInfo
    Assert-True ($Info.FileName -eq (Join-Path $Fixture 'tools with spaces/sk.exe') -and $Info.WorkingDirectory -eq $Directory) 'Resolve the executable and preserve the caller directory'
    Assert-True (-not $Info.UseShellExecute -and $Info.RedirectStandardOutput) 'Only capture the selection output'
    Assert-True (-not $Info.RedirectStandardInput -and -not $Info.RedirectStandardError) 'Keep console input and UI attached'
    Assert-True ($Info.StandardOutputEncoding.WebName -eq 'utf-8') 'Decode native file names as UTF-8'
    Assert-True (($Info.ArgumentList -join '|') -eq "--prompt|file> |--cmd|$env:SKIM_DEFAULT_COMMAND|--preview|bat --color=always --style=numbers -- {}") 'Pass each argument separately, with skim owning the file command'
    Assert-True ($LASTEXITCODE -eq 42 -and (Get-Location).Path -eq $Directory) 'Do not change the previous native exit code or caller directory'

    foreach ($Case in @(
        @{ Output = "ignored.txt`n"; ExitCode = 130 },
        @{ Output = "ignored.txt`n"; ExitCode = 1 },
        @{ Output = ''; ExitCode = 0 }
    )) {
        [DotfilesSkimTestReadLine]::Reset()
        $script:FakeProcess = New-SkimProcessMock @Case
        & $Handler
        Assert-True ([DotfilesSkimTestReadLine]::Buffer -eq 'vim  --readonly' -and [DotfilesSkimTestReadLine]::Cursor -eq 4) 'Cancellation/failure/empty selection must leave the buffer and cursor unchanged'
        Assert-True ([DotfilesSkimTestReadLine]::Insertions.Count -eq 0) 'Do not insert unsuccessful output'
        Assert-True ([DotfilesSkimTestReadLine]::Prompts -eq 1 -and $script:FakeProcess.Disposed) 'Dispose and redraw after cancellation or failure'
    }

    [DotfilesSkimTestReadLine]::Reset()
    $script:FakeProcess = New-SkimProcessMock -StartFails
    $Rejected = $false
    try { & $Handler } catch { $Rejected = $_.Exception.Message -like '*synthetic skim startup failure*' }
    Assert-True ($Rejected -and $script:FakeProcess.Disposed -and [DotfilesSkimTestReadLine]::Prompts -eq 1) 'Startup errors must still dispose and redraw'
    Assert-True ([DotfilesSkimTestReadLine]::Buffer -eq 'vim  --readonly') 'Startup errors must leave the input untouched'

    [DotfilesSkimTestReadLine]::Reset()
    $script:BatAvailable = $false
    $script:FakeProcess = New-SkimProcessMock -Output " leading and trailing spaces `n"
    & $Handler
    Assert-True (-not ($script:FakeProcess.StartInfo.ArgumentList -contains '--preview')) 'Missing bat must not prevent selection'
    Assert-True ([DotfilesSkimTestReadLine]::Buffer -eq "vim ' leading and trailing spaces ' --readonly") 'Strip newlines only, not spaces in file names'
    Write-Output 'PASS: direct skim process, console handles, arguments, UTF-8/quoting, cursor insertion, cancellation, startup failure, cleanup and prompt redraw'
} finally {
    Set-Location -LiteralPath $SavedLocation.Path
    $env:SKIM_DEFAULT_COMMAND = $SavedCommand
    $env:SKIM_DEFAULT_OPTIONS = $SavedOptions
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -LiteralPath $Fixture -Recurse -Force }
}
