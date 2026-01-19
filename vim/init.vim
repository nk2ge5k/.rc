set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath

let s:vim_dir = expand('<sfile>:h')
function! s:LocalSource(filename) abort
    exec 'source ' . s:vim_dir . '/' . a:filename
endfunction

""""""""""""""""""""""""""""""""""" GENERAL """"""""""""""""""""""""""""""""""""

if has('nvim')
    au TermOpen * setlocal nonumber norelativenumber
endif

let mapleader=" "
set nocompatible
set background=dark         " dark background

set foldmethod=manual
set nobackup nowritebackup
filetype plugin indent on   " autodetect file type
set syntax=on               " syntax highlighting
scriptencoding utf-8
set encoding=utf-8
set t_ut=
set ttyfast
set termguicolors

if !has("nvim")
    set ttyscroll=10
endif

if has('clipboard')
    if has('unnamedplus')   " When possible use + register for copy-paste
        set clipboard=unnamed,unnamedplus
    else                    " On mac and Windows, use * register for copy-paste
        set clipboard=unnamed
    endif
endif

set ruler                   " Show the ruler
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " A ruler on steroids
set showcmd                 " Show partial commands in status line and

set mouse=""                " disable mouse
set noswapfile              " disable swap files
set nobackup
set hidden                  " Allow buffer switching without saving
set history=1000
set number
set relativenumber
set virtualedit=block
set autoread

set backupdir=/tmp/nvim/backup

" For when you forget to sudo.. Really Write the file.
cmap w!! w !sudo tee % >/dev/null

" Shortcuts
" Change Working Directory to that of the current file
cmap cwd lcd %:p:h
cmap cd. lcd %:p:h

noremap <leader>hl :nohl<CR>
noremap <leader>nl :set invnumber invrelativenumber<CR>
noremap <leader>j :cnext<CR>
noremap <leader>k :cprevious<CR>
noremap <C-j> :lnext<CR>
noremap <C-k> :lprevious<CR>
noremap <C-h> :tabp<CR>
noremap <C-l> :tabn<CR>
noremap Y y$
noremap <leader>s :split %:p:h/<CR>
noremap <leader>v :vsplit %:p:h/<CR>
" copy directory under cursor into 'x' register then open in the new tab,
" changign tab current directory to the same directory.
" NOTE: does not work properly if path under cursor is file
noremap <leader>p :let @x = expand('<cfile>')<CR>
      \ :execute 'tabnew' @x<CR>
      \ :execute 'tcd' @x<CR>

cnoreabbrev hs split %:p:h/<C-R>
cnoreabbrev hv vsplit %:p:h/<C-R>
cnoreabbrev he e %:p:h/<C-R>

if has('nvim')
    cnoreabbrev vt vsplit \| terminal
    cnoreabbrev st split \| terminal
else
    cnoreabbrev vt vertical terminal
    cnoreabbrev st terminal
endif

nnoremap <leader>u :UndotreeToggle<CR>

if has("persistent_undo")
    let target_path = expand('~/.rc/vim/.vimdid')

    if !isdirectory(target_path)
        call mkdir(target_path, "p", 0700)
    endif

    let &undodir=target_path
    set undofile
endif

autocmd FileType yaml,python setlocal cursorcolumn " draw cursorcolumn for python and yaml
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

function BigFile()
    if exists(':TSBufDisable')
        exec 'TSBufDisable autotag'
        exec 'TSBufDisable highlight'
        " etc...
    endif

    syntax off
    filetype off
    set noundofile
    set noswapfile
    set noloadplugins
    set nowrap
endfunction

autocmd BufReadPre * if getfsize(expand("%")) > 52428800 | exec BigFile() | endif

let &undodir=s:vim_dir . '/.vimdid/'
set undofile


"""""""""""""""""""""""""""""""""" APPERENCE """""""""""""""""""""""""""""""""""

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_autowrite = 1
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
set conceallevel=2


set tabpagemax=15               " Only show 15 tabs
set showmode                    " Display the current mode

set cursorline                  " Highlight current line

highlight clear VertSplit
highlight Normal guifg=NvimLightGrey2 guibg=none

augroup comment_highlights
  autocmd!

  autocmd Syntax * syntax match @comment.atodo "\k\@<!@\k\+"

  " @note
  autocmd Syntax * syntax match @comment.atnote /@note/
        \ containedin=.*Comment,vimCommentTitle,cCommentL

  " @fix
  autocmd Syntax * syntax match @comment.aterror /@fix/
        \ containedin=.*Comment,vimCommentTitle,cCommentL
  " @leak
  autocmd Syntax * syntax match @comment.aterror /@leak/
        \ containedin=.*Comment,vimCommentTitle,cCommentL

  " @slow
  autocmd Syntax * syntax match @comment.aterror /@slow/
        \ containedin=.*Comment,vimCommentTitle,cCommentL
  " @important
  autocmd Syntax * syntax match @comment.important /@important/
        \ containedin=.*Comment,vimCommentTitle,cCommentL
  " @hack
  autocmd Syntax * syntax match @comment.hack /@hack/
        \ containedin=.*Comment,vimCommentTitle,cCommentL
  " @nocheckin
  autocmd Syntax * syntax match @comment.nocheckin /@nocheckin/
        \ containedin=.*Comment,vimCommentTitle,cCommentL


  highlight @comment.atnote
        \ ctermbg=none ctermfg=11 guifg=#FDDA0D guibg=none
  highlight @comment.aterror
        \ ctermbg=none ctermfg=9 guifg=#FF2400 guibg=none
  highlight @comment.important
        \ cterm=bold gui=bold ctermbg=none ctermfg=4 guifg=#3C93FA guibg=none
  highlight @comment.hack
        \ cterm=bold ctermbg=none ctermfg=45 guifg=#a86add guibg=none
  highlight @comment.nocheckin
        \ cterm=bold,underline ctermbg=none ctermfg=9 gui=bold,underline guifg=#FF2400 guibg=none
  highlight @comment.attodo
        \ cterm=bold gui=bold guifg=NvimLightGrey2

augroup END

autocmd FileType yaml setlocal ts=4 sts=4 sw=4 expandtab

set laststatus=2                " always display statusline
set statusline=%<%F\ %m\ %r\ %y\ 0x%B,%b%=%l:%c\ %P
set statusline+=\ %{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\"\ BOM\":\"\").\"]\ \"}

set backspace=indent,eol,start  " Backspace for dummies
set linespace=0                 " No extra spaces between rows
set showmatch                   " Show matching brackets/parenthesis
set incsearch                   " Find as you type search
set hlsearch                    " Highlight search terms
set winminheight=0              " Windows can be 0 line high
set ignorecase                  " Case insensitive search
set smartcase                   " Case sensitive when uc present
set wildmenu                    " Show list instead of just completing
set wildmode=list:longest,full  " Command <Tab> completion, list matches, then
                                " longest common part, then all.
set whichwrap=b,s,h,l,<,>,[,]   " Backspace and cursor keys wrap too
set scrolljump=5                " Lines to scroll when cursor leaves screen
set scrolloff=3                 " Minimum lines to keep above and below cursor
set colorcolumn=81              " higlight column 81
set list!
set listchars=tab:·\ ,trail:.   " Highlight problematic whitespace
set fillchars+=vert:│           " separator
set fillchars+=stl:\ ,stlnc:\   "
set vb t_vb=                    " No more beeps
set lazyredraw
set noshowmode
set noerrorbells

"""""""""""""""""""""""""""""""""" FORMATTING """"""""""""""""""""""""""""""""""

set autoindent                  " Indent at the same level of the previous line
set expandtab                   " Tabs are spaces, not tabs
set shiftwidth=2                " Use indents of 2 spaces
set tabstop=2                   " An indentation every four columns
set softtabstop=2               " Let backspace delete indent
set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
set splitright                  " Puts new vsplit windows to the right of the current
set splitbelow                  " Puts new split windows to the bottom of the current

""""""""""""""""""""""""""""""""" KEY MAPPING """"""""""""""""""""""""""""""""""

autocmd InsertLeave  * normal mZ
nmap <leader>i `Z

nmap j gj
nmap k gk

" nvim terminal more like vim terminal
if has('nvim')
    tnoremap <C-w>n <C-\><C-n>
    tnoremap <C-w>h <C-\><C-N><C-w>h
    tnoremap <C-w>j <C-\><C-N><C-w>j
    tnoremap <C-w>k <C-\><C-N><C-w>k
    tnoremap <C-w>l <C-\><C-N><C-w>l
endif

""""""""""""""""""""""""""""""""""" vim-go """""""""""""""""""""""""""""""""""""

let g:go_highlight_functions = 0
let g:go_highlight_methods = 0
let g:go_highlight_fields = 0
let g:go_highlight_types = 0
let g:go_highlight_operators = 0
let g:go_highlight_build_constraints = 00
let g:go_fmt_command = "goimports"
let g:go_def_mapping_enabled = 0

let g:go_term_enabled = 1
let g:go_term_close_on_exit = 0
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'


"""""""""""""""""""""""""""""""""""" FZF """""""""""""""""""""""""""""""""""""""

if executable('ag')
    let g:ackprg = 'ag --vimgrep'
endif

if executable('fzf')
    let g:fzf_buffers_jump = 1
    let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }
endif


"""""""""""""""""""""""""""""""""""" lsp """""""""""""""""""""""""""""""""""""""

let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
set completeopt=menuone,noinsert,noselect

""""""""""""""""""""""""""""""""""" custom """""""""""""""""""""""""""""""""""""

augroup autospell
  autocmd FileType markdown,vimwiki setlocal spelllang=ru,en spell
augroup END

noremap <silent> <leader>ss :setlocal spelllang=ru,en spell<CR>
noremap <silent> <leader>sn :setlocal nospell<CR>

call s:LocalSource('term.vim')

if has('nvim')
  call s:LocalSource('lua/init.lua')
else
  call s:LocalSource('vimrc.plugins')
endif
