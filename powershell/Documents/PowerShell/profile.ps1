# PowerShell profile for all hosts

$SharedProfile = Join-Path $HOME ".config/powershell/profile.ps1"

if (Test-Path -LiteralPath $SharedProfile) {
    . $SharedProfile
}
