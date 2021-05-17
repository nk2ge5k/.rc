function! s:ExtractUservicesRootDir()
    if exists('w:uservices_dir')
        return w:uservices_dir
    endif

    let previous = ''

    let root = getcwd()
    while root !=# previous
        if fnamemodify(root, ':t') ==# 'uservices'
            let w:uservices_dir = root
            return w:uservices_dir
        endif

        let previous = root
        let root = fnamemodify(root, ':h')
    endwhile

    return ''
endfunction

function! s:ExtractServiceName()
    let previous = ''
    let root = getcwd()

    while root !=# previous
        let service_yaml = substitute(root, '[\/]$', '', '') . '/service.yaml'
        let type = getftype(service_yaml)
        if type ==# 'file'
            return fnamemodify(root, ':t')
        endif

        let previous = root
        let root = fnamemodify(root, ':h')
    endwhile

    return ''
endfunction

function! uservices#Testsuite(...) abort

    let uservices_dir = s:ExtractUservicesRootDir()
    if empty(uservices_dir)
        return 'echoerr cannot call outside uservices directory'
    endif

    let service = get(a:000, 0, '')

    if empty(service)
        let service = s:ExtractServiceName()
        if empty(service)
            return 'echoerr service name is required'
        endif
    endif

    return tmux#SendKeys(uservices_dir, 'make testsuite-' . service)
endfunction

function! uservices#TestsuiteThis() abort
    let uservices_dir = s:ExtractUservicesRootDir()
    if empty(uservices_dir)
        return 'echoerr cannot call outside uservices directory'
    endif

    let service = s:ExtractServiceName()
    if empty(service)
        return 'echoerr could not detect service'
    endif

    let linenum = line('.')

    while linenum > 0
        if getline(linenum) =~ '^async def test_'
            break
        endif
        let linenum = linenum - 1
    endwhile

    if linenum == 1
        return 'echoerr failed to find test function'
    end

    let line = getline(linenum)

    let start =  match(line, 'test_')
    if start < 0
        return 'echoerr failed to get test name'
    endif

    let end = match(line, '(', start)
    let name = line[start:end-1]

    return tmux#SendKeys(uservices_dir, 'make testsuite-' . service .
                \ ' PYTEST_ARGS="-k ' . name . ' -vv"')
endfunction

" commands
command! -bang -nargs=? -range=-1 Testsuite exec uservices#Testsuite(<f-args>)
command! -bang -nargs=0 -range=-1 TT exec uservices#TestsuiteThis()
