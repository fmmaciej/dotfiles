# Loaded after skim: Atuin owns Ctrl+R, while skim retains Ctrl+T.
if (-not (Get-Command atuin -ErrorAction SilentlyContinue)) { return }
if (-not (Get-Module PSReadLine)) { return }
if (-not $env:ATUIN_CONFIG_DIR) { $env:ATUIN_CONFIG_DIR = Join-Path $HOME '.config/atuin' }

$AtuinInit = & atuin init powershell --disable-up-arrow --disable-ai
if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Atuin initialization failed; the existing history binding is unchanged.'
    return
}
$AtuinInit | Out-String | Invoke-Expression
