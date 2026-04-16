# Windows PowerShell profile

$PowerShellConfigDir = Join-Path $HOME ".config/powershell"

if (Test-Path -LiteralPath $PowerShellConfigDir) {
    Get-ChildItem -LiteralPath $PowerShellConfigDir -Filter "*.ps1" |
        Sort-Object Name |
        ForEach-Object { . $_.FullName }
}
