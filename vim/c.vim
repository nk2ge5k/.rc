
function! s:StartsWith(str, prefix) 
    if empty(a:str) || len(a:prefix) > len(a:str)
        return 0
    endif

    return a:str[0:len(a:prefix)-1] ==# a:prefix
endfunction

function! s:IsSource(extension)
    return s:StartsWith(a:extension, "c")
endfunction

function! s:IsHeader(extension)
    return s:StartsWith(a:extension, "h")
endfunction

function! s:TryFile(dir, filename, extensions) abort
    for extension in a:extensions
        let filepath = a:dir . '/' . a:filename . '.' . extension

        let type = getftype(filepath)
        if type ==# 'file'
            return filepath
        endif
    endfor

    return ''
endfunction

function! s:TryOpenHeader(filename) abort
    let extensions = ['h', 'hpp']

    let pair = s:TryFile(expand('%:h'), a:filename, extensions)
    if len(pair) > 0
        return 'edit ' . pair
    endif

    let path = substitute(expand('%:h'), '/src/', '/include/', '')
    let source = s:TryFile(path, a:filename, extensions)
    if len(source) > 0
        return 'edit ' . source
    endif

    return 'echoerr ' . string('could not find source file for ' . a:filename)
endfunction

function! s:TryOpenSource(filename) abort
    let extensions = ['c', 'cpp']

    let pair = s:TryFile(expand('%:h'), a:filename, extensions)
    if len(pair) > 0
        return 'edit ' . pair
    endif

    let path = substitute(expand('%:h'), '/include/', '/src/', '')
    let include = s:TryFile(path, a:filename, extensions)
    if len(include) > 0
        return 'edit ' . include
    endif

    return 'echoerr ' . string('could not find header file for ' . a:filename)
endfunction

function! s:CSwitch() abort
    let extension = expand('%:e')
    let filename = expand('%:t:r')

    if s:IsSource(extension)
        return s:TryOpenHeader(filename)
    endif

    if s:IsHeader(extension)
        return s:TryOpenSource(filename)
    endif

    return 'echoerr ' . string(expand('%:t') . ' not a c or cpp file')
endfunction

command! -bang -nargs=? -range=-1 CSwitch exec s:CSwitch(<f-args>)

noremap <leader>cs :CSwitch<CR>
