# Windows PowerShell profile

$SharedProfile = Join-Path $HOME ".config/powershell/profile.ps1"

if (Test-Path -LiteralPath $SharedProfile) {
    . $SharedProfile
}
