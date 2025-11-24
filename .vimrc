" --- ~/.vimrc ---

" VimPlug bootstrap
let s:data_dir = has('nvim') ? stdpath('data') . '/site' : expand('~/.vim')
if empty(glob(s:data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo ' . s:data_dir . '/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'tomasiser/vim-code-dark'
  Plug 'tpope/vim-surround'
  Plug 'preservim/nerdtree'
  " Plug 'w0rp/ale'
  " Plug 'junegunn/fzf'
  " Plug 'ervandew/supertab'
call plug#end()

" Kolorowanie
syntax on
filetype plugin indent on
set termguicolors
" vscode colorscheme
colorscheme codedark
" vscode airline
let g:airline_theme = 'codedark'
" dziedziczenie tła:
hi Normal guibg=NONE ctermbg=NONE

" Podstawy
set nocompatible
set number
" set relativenumber
set numberwidth=4
set scrolloff=8
set linebreak
set showbreak=↪\
set textwidth=100
set showmatch
set mouse=a

" Szukanie
set hlsearch
set smartcase
set ignorecase
set incsearch

" Wcięcia
set autoindent
set smartindent
set shiftwidth=4
set softtabstop=4
set expandtab      " (opcjonalnie: spacje zamiast tabów)

" Undo / backspace
set undolevels=1000
set backspace=indent,eol,start

" Clipboard - na macOS najlepiej:
set clipboard=unnamed,unnamedplus

" --- Kursor tylko w Vim:
"  Normal = blok,
"  Insert = "beam"
if !has('nvim')
  " Normal/Visual/Command: migający blok
  let &t_EI = "\e[1 q"
  " Insert/Replace: migająca pionowa kreska (beam)
  let &t_SI = "\e[5 q"
endif

" F2 = tryb bezpiecznego wklejania z zewnątrz (Cmd+V)
set pastetoggle=<F2>

" Normal-mode wklejka prosto z systemowego schowka
nnoremap <leader>p "+p
vnoremap <leader>p "+p

" Timeouty dla ESC
set ttimeout
set ttimeoutlen=10

" Znaki niewidoczne (opcjonalnie)
set listchars=tab:»\ ,trail:·,extends:>,precedes:<,space:·

" Mapy
let mapleader=","
nnoremap <leader>s :source $MYVIMRC<CR>
nnoremap <F5> "=strftime("%c")<CR>P
inoremap <F5> <C-R>=strftime("%c")<CR>

