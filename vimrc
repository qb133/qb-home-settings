syntax on

if !has('gui_running') && &term =~# '^\%(tmux\|xterm\|screen\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

set termguicolors
set t_ut=
colorscheme gruvbox
set background=dark
set ignorecase
set smartcase
set hlsearch
set incsearch
set visualbell
set autoindent
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set showmatch
set ruler
set number!
set mouse=a
set wildmenu
set scrolloff=8
set backspace=indent,eol,start
