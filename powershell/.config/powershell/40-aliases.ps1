# Common shell aliases

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ll -Force -ErrorAction SilentlyContinue
Remove-Item Alias:la -Force -ErrorAction SilentlyContinue
Remove-Item Alias:v -Force -ErrorAction SilentlyContinue
Remove-Item Alias:y -Force -ErrorAction SilentlyContinue

Set-Alias -Name v -Value vim -Scope Global

# Keep the chosen Yazi directory in the calling shell, including paths with spaces.
function global:y {
    $CwdFile = [System.IO.Path]::GetTempFileName()
    try {
        & yazi @args --cwd-file $CwdFile
        $Directory = Get-Content -LiteralPath $CwdFile -Raw -Encoding utf8
        if (-not [string]::IsNullOrWhiteSpace($Directory)) {
            Set-Location -LiteralPath $Directory.TrimEnd("`r", "`n")
        }
    } finally {
        Remove-Item -LiteralPath $CwdFile -Force
    }
}

function global:ls {
    eza --group-directories-first @args
}

function global:ll {
    eza --long --group --git --group-directories-first @args
}

function global:la {
    eza --all --group-directories-first @args
}

function global:lla {
    eza --long --all --group --git --group-directories-first @args
}

function global:lt {
    eza --tree --level=2 --group-directories-first @args
}
