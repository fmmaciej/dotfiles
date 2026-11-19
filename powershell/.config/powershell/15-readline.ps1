# Local history and completion predictions; skim keeps Ctrl+R and Ctrl+T.
if (-not (Get-Module -ListAvailable PSReadLine)) { return }
Import-Module PSReadLine

$DotfilesPredictionSource = 'History'
if (Get-Module -ListAvailable CompletionPredictor) {
    Import-Module CompletionPredictor
    $DotfilesPredictionSource = 'HistoryAndPlugin'
}

Set-PSReadLineOption -PredictionSource $DotfilesPredictionSource -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
