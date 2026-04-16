# Shared PowerShell profile loader

$PowerShellConfigDir = Join-Path $HOME ".config/powershell"

if (Test-Path -LiteralPath $PowerShellConfigDir) {
    Get-ChildItem -LiteralPath $PowerShellConfigDir -Filter "*.ps1" |
        Where-Object { $_.Name -ne "profile.ps1" } |
        Sort-Object Name |
        ForEach-Object { . $_.FullName }
}
