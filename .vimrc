" ==============================================
" VIM CONFIGURATION FILE
"
" VimPlug configuration
" READ HERE: https://github.com/junegunn/vim-plug
" :PlugInstall
" fetches https://github.com/junegunn/fzf 

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
" Plug 'w0rp/ale'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-surround'
" Plug 'terryma/vim-multiple-cursors'
Plug 'scrooloose/nerdtree',
" Plug 'dylanaraps/wal.vim'
" Plug 'junegunn/fzf'
" Plug 'ervandew/supertab'
" Plug 'rhysd/vim-clang-format'
call plug#end()		" Initialize plugin system

" his enables mouse in all modes, hence a for all. See vim manpages and
" http://vim.wikia.com/wiki/Using_the_mouse_for_Vim_in_an_xterm.
set mouse=a

" Leader key
let mapleader=","
map <leader>s :source ~/.vimrc<CR>

" colorscheme wal
set t_Co=256

syntax enable
set nocompatible

set fileencodings=ucs-bom,utf-8,sjis
set number		" Show line numbers
" set relativenumber	" Relativve numbers
set numberwidth=4
set scrolloff=15
" set cursorline
" set cursorcolumn
" set ruler		" Show row and column ruler information
set linebreak		" Break lines at word (requires Wrap lines)
set showbreak=<<<<	" Wrap-broken line prefix
set textwidth=100	" Line wrap (number of cols)
set showmatch		" Highlight matching brace
"set visualbell		" Use visual bell (no beeping)
 
set hlsearch		" Highlight all search results

" Powoduje start vim w trybie zmiana, dlaczego?
" noremap <esc> :noh<return><esc> 
" noremap <silent> <Esc> :nohlsearch<Bar>:echo<CR> 

set smartcase		" Enable smart-case search
set ignorecase		" Always case-insensitive
set incsearch		" Searches for strings incrementally
 
set autoindent		" Auto-indent new lines
set shiftwidth=4	" Number of auto-indent spaces
set softtabstop=4	" Number of spaces pTab
set smartindent		" Enable smart-indent
set smarttab		" Enable smart-tabs
 
set undolevels=1000	" Number of undo levels
set backspace=indent,eol,start	" Backspace behaviour
set timeoutlen=1000 ttimeoutlen=0

" map <C-K> :pyf </usr/local/share/clang/>/clang-format.py<cr>
" imap <C-K> <c-o>:pyf </usr/local/share/clang/>clang-format.py<cr>

"" For windows and MacOS
set clipboard=unnamed
"" For linux
" set clipboard=unnamedplus

" the desktop clipboard is the + (quoteplus) register. The * (quotestar) instead refers to X11 visual selections
" xnoremap "+y y:call system("wl-copy", @")<cr>
" nnoremap "+p :let @"=substitute(system("wl-paste --no-newline"), '<C-v><C-m>', '', 'g')<cr>p
" nnoremap "*p :let @"=substitute(system("wl-paste --no-newline --primary"), '<C-v><C-m>', '', 'g')<cr>p

nnoremap <F5> "=strftime("%c")<CR>P
inoremap <F5> <C-R>=strftime("%c")<CR>

" VIM CURSOR
let &t_SI = "\<esc>[5 q"
let &t_SR = "\<esc>[5 q"
let &t_EI = "\<esc>[2 q"

set ttimeout
set ttimeoutlen=1
set listchars=tab:>-,trail:~,extends:>,precedes:<,space:.
set ttyfast
