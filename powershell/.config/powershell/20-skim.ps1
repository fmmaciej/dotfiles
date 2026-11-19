# Native skim integration. sk --shell-bindings does not provide PSReadLine bindings.
$env:SKIM_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
$env:SKIM_DEFAULT_OPTIONS = '--layout=reverse --inline-info'

if (-not (Get-Command sk -ErrorAction SilentlyContinue)) { return }
if (-not (Get-Module -ListAvailable PSReadLine)) { return }
Import-Module PSReadLine

Set-PSReadLineKeyHandler -Chord Ctrl+t -BriefDescription SkimFiles -LongDescription 'Insert a file selected with skim' -ScriptBlock {
    $SkimArgs = @('--prompt', 'file> ')
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        $SkimArgs += @('--preview', 'bat --color=always --style=numbers -- {}')
    }
    $Selected = & fd --type f --hidden --follow --exclude .git | & sk @SkimArgs
    if ($LASTEXITCODE -eq 0 -and $Selected) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("'" + ($Selected -replace "'", "''") + "'")
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
