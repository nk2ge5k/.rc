let g:split_horizontal = 1
let g:split_size = 0
let g:split_detach = 0
let g:tmux_executable = 'tmux'

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

" s:SplitWindow([, {horizontal}, {detach}, {size}])
function! s:SplitWindow(...) abort
    if !s:InsideTmux()
        return
    endif

    let panes = s:ListPanes()
    if len(panes) > 1
        let cmd = [g:tmux_executable, 'select-pane']
        for pane in panes
            if !pane.active
                call add(cmd, '-t')
                call add(cmd, pane.index)
                call s:SystemError(cmd)
            endif
        endfor

        return ''
    endif

    let cmd = [g:tmux_executable, 'split-window']

    let horizontal = get(a:000, 0, g:split_horizontal)
    if horizontal
        call add(cmd, '-h')
    endif

    let detach = get(a:000, 1, g:split_detach)
    if detach
        call add(cmd, '-d')
    endif

    let size = get(a:000, 2, g:split_size)
    if size
        call add(cmd, '-l')
        call add(cmd, size)
    endif

    call s:SystemError(cmd)

    return ''
endfunction

function! s:SendKeys(...)
    if !a:0
        return ''
    endif


    let panes = s:ListPanes()
    let index = -1

    if len(panes) > 1
        for pane in panes
            if !pane.active
                let index = pane.index
                break
            endif
        endfor
    else
        call s:SplitWindow(g:split_horizontal, 1, g:split_size)
        let index = 1
    endif

    if index == -1
        echo 'could not find pane'
        return ''
    endif

    let cmd = [g:tmux_executable,
                \ 'send-keys', '-t', index] + a:000 + ['Enter']

    call s:SystemError(cmd)

    return ''
endfunction

function! s:ListPanes() abort
    let cmd = [g:tmux_executable,
                \ 'list-panes', '-F"#P #{pane_active} #{pane_current_path}"']

    let [out, err] = s:SystemError(cmd)
    if err
        throw 'failed to list panes: ' . out
    end

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

" commands
command! -bang -nargs=? -range=-1 Tsplit exec s:SplitWindow(<f-args>)
command! -bang -nargs=? -range=-1 Tmux exec s:SendKeys(<f-args>)

" remaps
noremap <leader>s :Tsplit<CR>

