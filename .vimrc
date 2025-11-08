" --- ~/.vimrc ---

" VimPlug bootstrap
let s:data_dir = has('nvim') ? stdpath('data') . '/site' : expand('~/.vim')
if empty(glob(s:data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo ' . s:data_dir . '/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
  Plug 'vim-airline/vim-airline'
  Plug 'tpope/vim-surround'
  Plug 'preservim/nerdtree'
  " Plug 'w0rp/ale'
  " Plug 'junegunn/fzf'
  " Plug 'ervandew/supertab'
  " Plug 'rhysd/vim-clang-format'
call plug#end()

" Kolorowanie składni
syntax on
filetype plugin indent on
" set termguicolors
" set background=light     " lub light, zależnie od motywu
" colorscheme desert

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

" Clipboard – na macOS najlepiej:
set clipboard=unnamedplus

" Kursor w Vim (DECSCUSR):
" insert/replace = beam (5=blink/6=steady),
" normal = block
let &t_SI = "\e[6 q"
let &t_SR = "\e[6 q"
let &t_EI = "\e[2 q"

" Force block on startup and restore on exit
let &t_ti .= "\e[2 q"  " when Vim initializes the terminal, set block
let &t_te .= "\e[0 q"  " on exit, restore terminal default cursor

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

