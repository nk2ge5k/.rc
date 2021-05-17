function! s:ExtractUservicesRootDir()
    let previous = ''

    let root = getcwd()
    while root !=# previous
        if fnamemodify(root, ':t') ==# 'uservices'
            return root
        endif

        let previous = root
        let root = fnamemodify(root, ':h')
    endwhile

    return ''
endfunction

function! uservices#Testsuite(service)
    let uservices_dir = s:ExtractUservicesRootDir()
    if empty(uservices_dir)
        " return 'echoerr cannot call outside uservices directory'
    endif

    let service = a:service
    if empty(a:service)
        let dir = getcwd()
        " Try to get service name from dirctory name
        let service = fnamemodify(getcwd(), ':t')
        if service !=? '^eats-'
            return 'echoerr service name is required'
        endif
    endif

    return tmux#SendKeys(uservices_dir, 'make testuite-' . service)
endfunction

" commands
command! -bang -nargs=1 -range=-1 Testsuite exec uservices#Testsuite(<f-args>)
