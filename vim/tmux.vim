if !exists('g:split_horizontal')
    let g:split_horizontal = 1
endif

if !exists('g:split_size')
    let g:split_size = 0
endif

if !exists('g:split_detach')
    let g:split_detach = 0
endif

if !exists('g:tmux_executable')
    let g:tmux_executable = 'tmux'
endif

function! s:Prepare(cmd) abort
    return join(map(a:cmd, 'shellescape(v:val)'))
endfunction

" Пытается исполнить команду в терминале
function! s:SystemError(cmd, ...) abort
    try
        if &shellredir ==# '>' && &shell =~# 'sh\|cmd'
            let shellredir = &shellredir
            if &shell =~# 'csh'
                set shellredir=>&
            else
                set shellredir=>%s\ 2>&1
            endif
        endif
        if exists('+guioptions') && &guioptions =~# '!'
            let guioptions = &guioptions
            set guioptions-=!
        endif

        let cmd = type(a:cmd) ==# type([]) ? s:Prepare(a:cmd) : a:cmd
        let out = call('system', [cmd])
        return [out, v:shell_error]
    catch /^Vim\%((\a\+)\)\=:E484:/
        let opts = ['shell', 'shellcmdflag', 'shellredir', 'shellquote', 'shellxquote', 'shellxescape', 'shellslash']
        call filter(opts, 'exists("+".v:val) && !empty(eval("&".v:val))')
        call map(opts, 'v:val."=".eval("&".v:val)')
        call s:throw('failed to run `' . a:cmd . '` with ' . join(opts, ' '))
    finally
        if exists('shellredir')
            let &shellredir = shellredir
        endif
        if exists('guioptions')
            let &guioptions = guioptions
        endif
    endtry
endfunction


function! s:InsideTmux()
    return exists('$TMUX')
endfunction

function! s:Run(...)
    if len(a:000) == 0
        return ''
    endif

    let cmd = [g:tmux_executable]
    for item in a:000
        if type(item) ==# type([])
            let cmd = cmd + item
        else
            call add(cmd, item)
        endif
    endfor

    let [out, err] = s:SystemError(cmd)
    return err ? 'echoerr ' . string(out) : ''
endfunction

function! s:ListPanes()
    let [out, err] = s:SystemError([g:tmux_executable,
                \ 'list-panes', '-F"#P #{pane_active} #{pane_current_path}"'])

    let panes = []
    for line in split(out, "\n")
        let line = trim(line, '"')
        let index = matchstr(line, '^[0-9]\+')

        if !empty(index)
            let line = line[len(index) + 1:]
            let active = matchstr(line, '^[0-9]\+')

            call add(panes, {
                        \ 'index': index + 0,
                        \ 'active': active ==# '1',
                        \ 'path': line[len(active) + 1:]
                        \ })
        endif
    endfor

    retur panes
endfunction


function! s:SwichToPane(index)
    return s:Run('select-pane', '-t', a:index)
endfunction


function! s:SplitWindow(horizontal, detach, size, dir)
    let cmd = ['split-window']

    if a:horizontal
        call add(cmd, '-h')
    endif

    if a:detach
        call add(cmd, '-d')
    endif

    if a:size
        call add(cmd, '-l')
        call add(cmd, a:size)
    endif

    if !empty(a:dir)
        call add(cmd, '-c')
        call add(cmd, a:dir)
    endif

    return call('s:Run', cmd)
endfunction

function! s:SendKeys(pane_index, command)
    return s:Run("send-keys", "-t", a:pane_index, "C-c", "Enter", a:command, "Enter")
endfunction

" tmux#SplitWindow([, {horizontal}, {detach}, {size}, {dir}])
function! tmux#SplitWindow(...) abort
    if !s:InsideTmux()
        return 'echoerr ' . string('cannot split outside tmux')
    endif

    try
        let panes = s:ListPanes()
    catch
        return 'echoerr ' . string(v:exception)
    endtry

    return s:SplitWindow(
                \ get(a:000, 0, g:split_horizontal),
                \ get(a:000, 1, g:split_detach),
                \ get(a:000, 2, g:split_size),
                \ get(a:000, 3, ''))
endfunction

function! tmux#SelectWindow(window_index)
    if !s:InsideTmux()
        return 'echoerr ' . string('cannot select window outside tmux')
    endif

    return s:Run("select-window", "-t", a:window_index)
endfunction

" tmux#SendKeys([, command ...])
function! tmux#SendKeys(dir, ...) abort
    if !s:InsideTmux()
        return 'echoerr ' . string('cannot split outside tmux')
    endif

    if !a:0
        return ''
    endif

    try
        let panes = s:ListPanes()
    catch
        return 'echoerr ' . string(v:exception)
    endtry

    let index = -1

    for pane in panes
        if !pane.active && (empty(a:dir) || pane.path == a:dir)
            let index = pane.index
            break
        endif
    endfor

    if index == -1
        let msg = s:SplitWindow(g:split_horizontal, 1, g:split_size, a:dir)
        if !empty(msg)
            return msg
        endif
        let index = 1
    endif

    return s:SendKeys(index, a:000)
endfunction

function! tmux#FastNote() abort
    if !s:InsideTmux()
        return 'echoerr ' . string('cannot display popup outside tmux')
    endif

    let vim = 'vim'
    if has('nvim')
        let vim = 'nvim'
    endif

    return s:Run('popup', '-w', '60%', '-h', '80%',
                \ '-E', vim, '-c', 'VimwikiMakeDiaryNote')
endfunction


" commands
command! -bang -nargs=* -range=-1 TFastNote exec tmux#FastNote(<f-args>)
command! -bang -nargs=* -range=-1 Tvsplit exec tmux#SplitWindow(1, <f-args>)
command! -bang -nargs=* -range=-1 Tsplit exec tmux#SplitWindow(0, <f-args>)
command! -bang -nargs=1 -range=-1 Tmux exec tmux#SendKeys('', <q-args>)
command! -bang -nargs=1 -range=-1 Twselect exec tmux#SelectWindow(<q-args>)

" remaps
noremap <leader>v :Tvsplit<CR>
noremap <leader>s :Tsplit<CR>
noremap <leader>o :TFastNote<CR>
noremap <leader>0 :Twselect 0<CR>
noremap <leader>1 :Twselect 1<CR>
noremap <leader>2 :Twselect 2<CR>
noremap <leader>3 :Twselect 3<CR>
noremap <leader>4 :Twselect 4<CR>
noremap <leader>5 :Twselect 5<CR>
noremap <leader>6 :Twselect 6<CR>
noremap <leader>7 :Twselect 7<CR>
noremap <leader>8 :Twselect 8<CR>
noremap <leader>9 :Twselect 9<CR>
