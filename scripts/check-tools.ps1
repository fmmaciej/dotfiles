# Native Windows availability check only; no programs are executed or installed.
$Programs = @(
    'scoop', 'git', 'pwsh', 'msys2',
    'wezterm', 'psmux', 'vim', 'starship', 'yazi',
    'sk', 'fd', 'rg', 'bat', 'eza',
    'ffmpeg', 'ffprobe', '7z', 'jq', 'pdftoppm'
)
$Missing = $false

foreach ($Program in $Programs) {
    if (Get-Command -Name $Program -ErrorAction SilentlyContinue) {
        Write-Output "OK       $Program"
    } else {
        Write-Output "MISSING  $Program (not in PATH)"
        $Missing = $true
    }
}

if ($Missing) { exit 1 }
exit 0
