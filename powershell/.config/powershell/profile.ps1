# Shared interactive loader: AllHosts and explicit terminal startup can use it.
# Only numbered modules are loaded; private files are never sourced by a glob.
if ($global:DotfilesProfileLoaded) { return }
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning 'These dotfiles use PowerShell 7. Start pwsh for the configured environment.'
    return
}

$PowerShellConfigDir = Join-Path $HOME '.config/powershell'
foreach ($Module in (Get-ChildItem -LiteralPath $PowerShellConfigDir -Filter '*.ps1' | Where-Object Name -Match '^\d{2}-' | Sort-Object Name)) {
    . $Module.FullName
}
$global:DotfilesProfileLoaded = $true
