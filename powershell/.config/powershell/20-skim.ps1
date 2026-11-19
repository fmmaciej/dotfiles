# Native skim integration. sk --shell-bindings does not provide PSReadLine bindings.
$env:SKIM_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
$env:SKIM_DEFAULT_OPTIONS = '--layout=reverse --inline-info'

if (-not (Get-Command sk -ErrorAction SilentlyContinue)) { return }
if (-not (Get-Module -ListAvailable PSReadLine)) { return }
Import-Module PSReadLine

Set-PSReadLineKeyHandler -Chord Ctrl+t -BriefDescription SkimFiles -LongDescription 'Insert a file selected with skim' -ScriptBlock {
    $SkimArgs = @('--prompt', 'file> ', '--cmd', $env:SKIM_DEFAULT_COMMAND)
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        $SkimArgs += @('--preview', 'bat --color=always --style=numbers -- {}')
    }

    # Avoid the native PowerShell pipeline inside a PSReadLine handler. Skim
    # owns its fd input; only stdout is captured, leaving console input/UI intact.
    $Process = [Diagnostics.Process]::new()
    try {
        $Process.StartInfo.FileName = (Get-Command sk -CommandType Application).Source
        $Process.StartInfo.WorkingDirectory = $PWD.ProviderPath
        $Process.StartInfo.UseShellExecute = $false
        $Process.StartInfo.RedirectStandardOutput = $true
        $Process.StartInfo.StandardOutputEncoding = [Text.Encoding]::UTF8
        foreach ($Argument in $SkimArgs) {
            $Process.StartInfo.ArgumentList.Add($Argument)
        }
        $null = $Process.Start()
        $Selected = $Process.StandardOutput.ReadToEnd()
        $Process.WaitForExit()
        if ($Process.ExitCode -eq 0) {
            $Selected = $Selected.TrimEnd([char[]]"`r`n")
            if ($Selected) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert("'" + $Selected.Replace("'", "''") + "'")
            }
        }
    } finally {
        $Process.Dispose()
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}

Set-PSReadLineKeyHandler -Chord Ctrl+r -BriefDescription SkimHistory -LongDescription 'Recall a command with skim, without executing it' -ScriptBlock {
    $Line = $null
    $Cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Line, [ref]$Cursor)
    $Commands = [System.Collections.Generic.List[string]]::new()
    $HistoryPath = (Get-PSReadLineOption).HistorySavePath
    $Continuation = ''
    if (Test-Path -LiteralPath $HistoryPath) {
        foreach ($Entry in (Get-Content -LiteralPath $HistoryPath -Encoding utf8)) {
            if ($Entry.EndsWith('`')) {
                $Continuation += $Entry.Substring(0, $Entry.Length - 1) + "`n"
            } else {
                $Commands.Add($Continuation + $Entry)
                $Continuation = ''
            }
        }
    }
    foreach ($Entry in [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()) {
        $Commands.Add($Entry.CommandLine)
    }
    $Seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $Choices = for ($Index = $Commands.Count - 1; $Index -ge 0; $Index--) {
        if ($Seen.Add($Commands[$Index])) {
            '{0}  {1}' -f $Index, ($Commands[$Index] -replace '[\r\n]+', ' ; ')
        }
    }
    if (-not $Choices) { return }
    $Selected = $Choices | & sk --no-sort --delimiter '  ' --with-nth '2..' --prompt 'history> ' --query $Line
    if ($LASTEXITCODE -eq 0 -and $Selected -match '^(\d+)  ') {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($Commands[[int]$Matches[1]])
    }
}
