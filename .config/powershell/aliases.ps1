# Common shell aliases

$env:EDITOR = "vim"
$env:TERMINAL = "wezterm"

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ll -Force -ErrorAction SilentlyContinue
Remove-Item Alias:la -Force -ErrorAction SilentlyContinue
Remove-Item Alias:v -Force -ErrorAction SilentlyContinue
Remove-Item Alias:y -Force -ErrorAction SilentlyContinue

Set-Alias -Name v -Value vim -Scope Global
Set-Alias -Name y -Value yazi -Scope Global

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
