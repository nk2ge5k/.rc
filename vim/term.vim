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

if !exists('g:term_channel_id')
    let g:term_channel_id = -1
endif

if !exists('g:term_use_tmux')
    let g:term_use_tmux = 0
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

function! s:Tmux(...)
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

function! s:InsideTmux()
    return exists('$TMUX')
endfunction

function! s:UseTmux()
    return g:term_use_tmux && s:InsideTmux()
endfunction

function! s:TermOpen(cwd, remember, horizontal)
    if a:horizontal
        new
    else
        vnew
    endif

    let channel_id = termopen(&shell, {'cwd': a:cwd})
    if a:remember
        let g:term_channel_id = channel_id
    endif
endfunction

function! s:SendKeys(cmd)
    call chansend(g:term_channel_id, [a:cmd, ""])
endfunction

function! s:TmuxListPanes()
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

function! s:TmuxSplitWindow(horizontal, detach, size, dir)
    let cmd = ['split-window']

    if !a:horizontal
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

    return call('s:Tmux', cmd)
endfunction

function! s:TmuxSendKeys(pane_index, command)
    return s:Tmux("send-keys", "-t", a:pane_index, "C-c", "Enter", a:command, "Enter")
endfunction

" term#SplitWindow([, {horizontal}, {detach}, {size}, {dir}])
function! term#SplitWindow(...) abort
    if !s:UseTmux()
        call s:TermOpen(getcwd(), 0, get(a:000, 0, g:split_horizontal))
        return
    endif

    return s:TmuxSplitWindow(
                \ get(a:000, 0, g:split_horizontal),
                \ get(a:000, 1, g:split_detach),
                \ get(a:000, 2, g:split_size),
                \ get(a:000, 3, ''))
endfunction

" term#SendKeys([, command ...])
function! term#SendKeys(dir, ...) abort
    if a:1 == ''
        return
    endif

    let dir = a:dir
    if !dir
        let dir = getcwd()
    endif

    if !s:UseTmux()
        try
            " canceling previous job
            call s:SendKeys("\<c-c>")
            call s:SendKeys("cd " . dir)
            call s:SendKeys(a:1)
        catch
            call s:TermOpen(dir, 1, g:split_horizontal)
            call s:SendKeys(a:1)
        endtry

        return
    endif


    try
        let panes = s:TmuxListPanes()
    catch
        return 'echoerr ' . string(v:exception)
    endtry

    let index = -1

    for pane in panes
        if !pane.active && (empty(dir) || pane.path == dir)
            let index = pane.index
            break
        endif
    endfor

    if index == -1
        let msg = s:TmuxSplitWindow(g:split_horizontal, 1, g:split_size, dir)
        if !empty(msg)
            return msg
        endif
        let index = 1
    endif

    return s:TmuxSendKeys(index, a:000)
endfunction

function! term#FastNote() abort
    if !s:InsideTmux()
        return 'echoerr ' . string('cannot display popup outside tmux')
    endif

    let vim = 'vim'
    if has('nvim')
        let vim = 'nvim'
    endif

    let directory = get(g:, 'note_dir', $HOME)
    return s:Tmux('popup', '-w', '60%', '-h', '80%', '-d', directory,
                \ '-E', vim, '-c', 'VimwikiMakeDiaryNote')
endfunction


" commands
command! -bang -nargs=* -range=-1 TFastNote exec term#FastNote(<f-args>)
command! -bang -nargs=* -range=-1 Tvsplit exec term#SplitWindow(0, <f-args>)
command! -bang -nargs=* -range=-1 Tsplit exec term#SplitWindow(1, <f-args>)
command! -bang -nargs=1 -range=-1 Tsend exec term#SendKeys('', <q-args>)

" remaps
noremap <leader>o :TFastNote<CR>
