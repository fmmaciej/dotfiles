# Transfer clipboard text through a file so quotes/newlines are never commands.
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^%[0-9]+$')]
    [string] $Pane
)

$ErrorActionPreference = 'Stop'
$Session = $env:PSMUX_TARGET_SESSION
if ([string]::IsNullOrWhiteSpace($Session)) { throw 'psmux paste: missing server session context.' }
$SessionTarget = '=' + $Session
$BufferFile = [System.IO.Path]::GetTempFileName()
$BufferName = 'dotfiles-clipboard-' + [guid]::NewGuid().ToString('N')
$BufferLoaded = $false
try {
    $Text = Get-Clipboard -Raw
    if ($null -ne $Text) {
        [System.IO.File]::WriteAllText($BufferFile, $Text, [System.Text.UTF8Encoding]::new($false))
        & psmux -t $SessionTarget load-buffer -b $BufferName $BufferFile
        if ($LASTEXITCODE -ne 0) { throw 'psmux: could not load clipboard text' }
        $BufferLoaded = $true
        # Pin the server with the global -t and the captured pane with the
        # command's -t. Changing focus while PowerShell starts must not redirect it.
        & psmux -t $SessionTarget paste-buffer -d -b $BufferName -t $Pane
        if ($LASTEXITCODE -ne 0) { throw 'psmux: could not paste clipboard text' }
        $BufferLoaded = $false
    }
} finally {
    if ($BufferLoaded) {
        & psmux -t $SessionTarget delete-buffer -b $BufferName 2>$null
    }
    Remove-Item -LiteralPath $BufferFile -Force
}
