# Common shell aliases

$env:EDITOR = "vim"
$env:TERMINAL = "wezterm"

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ll -Force -ErrorAction SilentlyContinue
Remove-Item Alias:la -Force -ErrorAction SilentlyContinue

Set-Alias -Name v -Value vim

function ls {
    eza --group-directories-first @args
}

function ll {
    eza --long --group --git --group-directories-first @args
}

function la {
    eza --all --group-directories-first @args
}

function lla {
    eza --long --all --group --git --group-directories-first @args
}

function lt {
    eza --tree --level=2 --group-directories-first @args
}
