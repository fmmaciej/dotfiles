# Shared PowerShell profile loader

$PowerShellConfigDir = Join-Path $HOME ".config/powershell"

if (Test-Path -LiteralPath $PowerShellConfigDir) {
    $PowerShellProfileScripts = Get-ChildItem -LiteralPath $PowerShellConfigDir -Filter "*.ps1" |
        Where-Object { $_.Name -ne "profile.ps1" } |
        Sort-Object Name

    foreach ($Script in $PowerShellProfileScripts) {
        . $Script.FullName
    }
}
