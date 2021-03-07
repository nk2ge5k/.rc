set shell=/bin/bash

""""""""""""""""""""""""""""""""""" PLUGINS """"""""""""""""""""""""""""""""""""

if filereadable(expand("~/.vimrc.plugins"))
    source ~/.vimrc.plugins
endif

""""""""""""""""""""""""""""""""""" GENERAL """"""""""""""""""""""""""""""""""""

if has('nvim')
    au TermOpen * setlocal nonumber norelativenumber
endif

let mapleader=" "
set nocompatible

set background=dark         " dark background

filetype plugin indent on   " autodetect file type
syntax on                   " syntax highlighting
scriptencoding utf-8
set encoding=utf-8
set termencoding=utf-8
set t_ut=
set ttyfast

if !has("nvim")
    set ttyscroll=10
endif

if has("termguicolors")
    set termguicolors
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
set hidden                  " Allow buffer switching without saving
set history=1000
set number
set relativenumber
set virtualedit=block

" For when you forget to sudo.. Really Write the file.
cmap w!! w !sudo tee % >/dev/null

" Shortcuts
" Change Working Directory to that of the current file
cmap cwd lcd %:p:h
cmap cd. lcd %:p:h

noremap <leader>hl :nohl<CR>
noremap <leader>nl :set invnumber invrelativenumber<CR>
noremap <leader>j :cnext
noremap <leader>k :cprevious

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

autocm FileType yaml,python setlocal cursorcolumn " draw cursorcolumn for python and yaml
autocmd BufWritePre * %s/\s\+$//e

function YaPaste() range
  echo system('echo '.shellescape(join(getline(a:firstline, a:lastline), "\n")).'| ya paste | ya notify')
endfunction

vnoremap <silent> <leader>y :call YaPaste()<cr>

"""""""""""""""""""""""""""""""""" APPERENCE """""""""""""""""""""""""""""""""""

color nord

highlight Comment guifg=#bdae93

set tabpagemax=15               " Only show 15 tabs
set showmode                    " Display the current mode

set cursorline                  " Highlight current line

highlight clear SignColumn      " SignColumn should match background
highlight clear LineNr          " Current line number row will have same


autocmd FileType yaml setlocal ts=4 sts=4 sw=4 expandtab

set laststatus=2                " always display statusline
set statusline=%<%n\ %F\ %m\ %r\ %y\ 0x%B,%b%=%l:%c\ %P

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
set fillchars+=vert:\           " separator
set vb t_vb=                    " No more beeps
set lazyredraw
set nofoldenable
set noshowmode
set noerrorbells

"""""""""""""""""""""""""""""""""" FORMATTING """"""""""""""""""""""""""""""""""

set autoindent                  " Indent at the same level of the previous line
set expandtab                   " Tabs are spaces, not tabs
set shiftwidth=4                " Use indents of 4 spaces
set tabstop=4                   " An indentation every four columns
set softtabstop=4               " Let backspace delete indent
set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
set splitright                  " Puts new vsplit windows to the right of the current
set splitbelow                  " Puts new split windows to the bottom of the current

""""""""""""""""""""""""""""""""" KEY MAPPING """"""""""""""""""""""""""""""""""

nmap <C-j> <C-W>j
nmap <C-k> <C-W>k
nmap <C-h> <C-W>h
nmap <C-l> <C-W>l

nmap j gj
nmap k gk

nnoremap <silent> n nzz
nnoremap <silent> N Nzz

" nvim terminal more like vim terminal
if has('nvim')
    tnoremap <C-w>N <C-\><C-n>
    tnoremap <C-w>h <C-\><C-N><C-w>h
    tnoremap <C-W>j <C-\><C-N><C-w>j
    tnoremap <C-w>k <C-\><C-N><C-w>k
    tnoremap <C-w>l <C-\><C-N><C-w>l
endif

""""""""""""""""""""""""""""""" NERDCommenter """"""""""""""""""""""""""""""""""

let g:NERDSpaceDelims = 1

""""""""""""""""""""""""""""""""""" vim-go """""""""""""""""""""""""""""""""""""

let g:go_highlight_functions = 1
let g:go_highlight_methods = 0
let g:go_highlight_fields = 0
let g:go_highlight_types = 0
let g:go_highlight_operators = 0
let g:go_highlight_build_constraints = 1
let g:go_fmt_command = "goimports"
let g:go_def_mapping_enabled = 1

let g:go_term_enabled = 1
let g:go_term_close_on_exit = 0

cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

if executable('rg')
  set grepprg=rg\ --no-heading\ --vimgrep
  set grepformat=%f:%l:%c:%m
endif

"""""""""""""""""""""""""""""""""" undotree """"""""""""""""""""""""""""""""""""

let g:undotree_WindowLayout = 3
let g:undotree_ShortIndicators = 1

set undodir=$HOME/dotfiles/editor/.vimdid/
set undofile                " So is persistent undo ...

"""""""""""""""""""""""""""""""""""" FZF """""""""""""""""""""""""""""""""""""""

" map <C-p> :Files<CR>
" nmap <leader>; :Buffers<CR>

" Find files using Telescope command-line sugar.

let g:fzf_layout = { 'down': '~20%' }
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)


"""""""""""""""""""""""""""""""""" vim-wiki """"""""""""""""""""""""""""""""""""

let g:vimwiki_ext2syntax = {'.md': 'markdown'}

let g:vimwiki_list = [{
    \ 'path': '/home/nk2ge5k/notes',
    \ 'syntax': 'markdown',
    \ 'ext': '.md',
    \ 'nested_syntaxes': {
        \ 'go': 'go',
        \ 'json': 'json',
        \ 'php': 'php',
        \ 'c': 'c'
    \ },
    \ }]

"""""""""""""""""""""""""""""""""" coc.vim """""""""""""""""""""""""""""""""""""

let g:rustfmt_autosave = 1

let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
set completeopt=menuone,noinsert,noselect

if has('nvim')

lua << EOF

local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
  end
end

-- Use a loop to conveniently both setup defined servers
-- and map buffer local keybindings when the language server attaches
local servers = { "pyright", "clangd", "gopls", "rls" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach }
end

EOF

endif


""""""""""""""""""""""""""""" google/vim-codefmt """""""""""""""""""""""""""""""

Glaive codefmt clang_format_executable='clang-format-9'

augroup autoformat_settings
  autocmd FileType bzl AutoFormatBuffer buildifier
  autocmd FileType c,cpp,proto,javascript,arduino AutoFormatBuffer clang-format
  autocmd FileType dart AutoFormatBuffer dartfmt
  autocmd FileType go AutoFormatBuffer gofmt
  autocmd FileType gn AutoFormatBuffer gn
  autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
  autocmd FileType java AutoFormatBuffer google-java-format
  autocmd FileType python AutoFormatBuffer yapf
  autocmd FileType python AutoFormatBuffer autopep8
  autocmd FileType rust AutoFormatBuffer rustfmt
  autocmd FileType vue AutoFormatBuffer prettier
augroup END


augroup vimrc_todo
    au!
    " Highlight KILLME TODO NOTE
    au Syntax * syn match MyTodo /\v<(FIXME|NOTE|TODO|OPTIMIZE|KILLME)/
    " Highlight #diffent #tags_in-comments #hello
    au Syntax * syn match CommentTag /\v<(#[A-Za-z_-]+)/
augroup END
hi def link MyTodo Todo
hi def link CommentTag Underlined


"" telescope ""


lua << EOF


local actions = require('telescope.actions')

require('telescope').setup{
    defaults = {
        file_sorter = require('telescope.sorters').get_fzy_sorter,
        prompt_prefix = ' >',
        color_devicons = true,

        mappings = {
            i = {
                ["<C-x>"] = false,
                ["<C-q>"] = actions.send_to_qflist,
            },
        }
    },
    extensions = {
        fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        }
    }
}

require('telescope').load_extension('fzy_native')

local custom = {}

custom.ufiles = function()
    require("telescope.builtin").find_files({
        prompt_title = "UFiles",
        cwd = "$HOME/src/github.yandex-team.ru/nk2ge5k/uservices",
    })
end

custom.ugrep = function()
    require("telescope.builtin").live_grep({
        prompt_title = "UGrep",
        cwd = "$HOME/src/github.yandex-team.ru/nk2ge5k/uservices",
    })
end

custom.bfiles = function()
    require("telescope.builtin").find_files({
        prompt_title = "Cat Files",
        cwd = "$HOME/src/bb.yandex-team.ru/eda/backend_platform",
    })
end

_G.telescope_custom = custom

EOF

nnoremap <C-p> <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>g <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>; <cmd>lua require('telescope.builtin').buffers()<cr>

nnoremap <leader>uf <cmd>lua telescope_custom.ufiles()<cr>
nnoremap <leader>ug <cmd>lua telescope_custom.ugrep()<cr>

nnoremap <leader>bf <cmd>lua telescope_custom.bfiles()<cr>
