#!/bin/bash

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"
# if [[ -z "$WAYLAND_DISPLAY" ]]; then
    ZSH_THEME="frisk"
# else 
#     ZSH_THEME="agnoster"
# fi
# ZSH_THEME="bullet-train"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=3

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# remap "+yy :call system("wl-copy", @")<cr>
#
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"
setopt nosharehistory

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  colored-man-pages
#  git
  pass
#  ssh-agent
#  gpg-agent
  gpg-agent_void
#  sudo
#  tmux
#  transfer
#  vscode
  vi-mode
  fzf_void
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# ZSH_TMUX_AUTOSTART='true'

ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh
# source ~/.oh-my-zsh/custom/plugins/antigen.zsh

# This is for bash. Zsh is not bash. Use just zsh.
# [ -f $HOME/.bashrc ] && source $HOME/.bashrc
[ -f $HOME/.aliases ] && source $HOME/.aliases

# [ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
# export FZF_BASE='/usr/share/doc/fzf'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--layout=reverse --inline-info"

# 10ms for key sequences
KEYTIMEOUT=1

# User configuration

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch aarch64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Better searching in command mode
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M vicmd '/' history-incremental-search-forward

# Beginning search with arrow keys
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search
bindkey -M vicmd "k" up-line-or-beginning-search
bindkey -M vicmd "j" down-line-or-beginning-search

typeset -U PATH path
path=("$HOME/.local/bin" "/opt/local/bin" "/opt/gcc-arm-none-eabi/bin")
path+=("/usr/local/bin" "/usr/local/sbin" "/bin" "/sbin")
export PATH

# typeset -U LD_LIBRARY_PATH ld_library_path
# ld_library_path+=("/usr/local/lib" "/opt/local/lib")
# export LD_LIBRARY_PATH

LD_LIBRARY_PATH=/opt/local/lib:/usr/local/lib:/usr/lib:/opt/gcc-arm-none-eabi/lib
ld_library_path=("/opt/local/lib" "/usr/local/lib" "/usr/lib" "/opt/gcc-arm-none-eabi/lib")
export LD_LIBRARY_PATH
export ld_library_path

typeset -U MANPATH manpath  
manpath=()
# for d in $(find /usr/share/man -type d); do manpath+="$d"; done
# for d in $(find /usr/local/share/man -type d); do manpath+="$d"; done
# for d in $(find /opt/gcc-arm-none-eabi/share/doc/gcc-arm-none-eabi/man -type d); do manpath+="$d"; done
manpath=("/opt/local/share/man" "/usr/share/man" "/usr/local/share/man")
manpath+=("/opt/gcc-arm-none-eabi/share/doc/gcc-arm-none-eabi/man")
export MANPATH

########
# iphone imobiledevice
#[ ! -d "/opt/local/src" ] && mkdir -p "/opt/local/src"

typeset -U PKG_CONFIG_PATH pkg_config_path
PKG_CONFIG_LIBDIR=/usr/lib/pkgconfig
PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
pkg_config_path=("/usr/lib/pkgconfig" "/usr/share/pkgconfig")
export PKG_CONFIG_LIBDIR
export PKG_CONFIG_PATH
export pkg_config_path


# typeset -U CPATH cpath
# cpath=("/opt/local/include")
# export CPATH
########

export EDITOR="vim"
export TERMINAL="alacritty"
export BROWSER="firefox"
export READER="zathura"

# wayland
export MOZ_ENABLE_WAYLAND=1	# In order to work urlview with firefox
export SDL_VIDEODRIVER=wayland	# or x11
export CLUTTER_BACKEND=wayland
export BEMENU_BACKEND=wayland
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=""
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc-2.0"

# ALACRITY GLES3.3 SUPPORT
export PAN_MESA_DEBUG=gl3

# CHEAT https://github.com/cheat/cheat
export CHEAT_CONFIG_PATH="~/.config/cheat/conf.yml"

# My custom scripts localization
export ENVIRONMENT_SCRIPTS="$HOME/.config/env"


# PINENTRY
# If stdin is a terminal
# if [ -t 0 ]; then
#     # Set GPG_TTY so gpg-agent knows where to prompt.  See gpg-agent(1)
#     export GPG_TTY="$(tty)"
#     # Set PINENTRY_USER_DATA so pinentry-auto knows to present a text UI.
#     export PINENTRY_USER_DATA=USE_TTY=1
# fi

# if [[ $DISPLAY ]]; then
#     # If not running interactively, do not do anything
#     [[ $- != *i* ]] && return
#     [[ -z "$TMUX" ]] && exec tmux
# fi
 
# export PYTHONPATH="/home/fm/.local/lib/python3.8/site-packages:/usr/lib/python38.zip:/usr/lib/python3.8:/usr/lib/python3.8/lib-dynload:/usr/lib/python3.8/site-packages"

# useless, it defaults to it
export XDG_CONFIG_HOME="$HOME/.config"

if [ -z "${XDG_RUNTIME_DIR}" ]; then
    export XDG_RUNTIME_DIR="/run/user/${UID}"

    if [ ! -d "${XDG_RUNTIME_DIR}" ]; then
	mkdir "${XDG_RUNTIME_DIR}"
	chmod 0700 "${XDG_RUNTIME_DIR}"
    fi
fi


cursor_mode() {
    # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
    # https://thevaluable.dev/zsh-install-configure/
    cursor_block='\e[2 q'
    cursor_beam='\e[6 q'

    function zle-keymap-select {
        if [[ ${KEYMAP} == vicmd ]] ||
            [[ $1 = 'block' ]]; then
                echo -ne $cursor_block
        elif [[ ${KEYMAP} == main ]] ||
            [[ ${KEYMAP} == viins ]] ||
            [[ ${KEYMAP} = '' ]] ||
            [[ $1 = 'beam' ]]; then
                echo -ne $cursor_beam
        fi
    }

    zle-line-init() {
        echo -ne $cursor_beam
    }

    zle -N zle-keymap-select
    zle -N zle-line-init
}

cursor_mode
