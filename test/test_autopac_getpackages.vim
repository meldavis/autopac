

set rtp^=..
set packpath=.
let g:autopac_debug = 1
runtime plugin/autopac.vim


" Test get_packages

func s:getnames(plugs)
    return sort(map(a:plugs, {-> substitute(v:val, '^.*[/\\]', '', '')}))
endfunc


function Test_autopac_get_packages()
    call delete('pack', 'rf')
    call autopac#impl#clear_pluglist()


    let plugs = [
                \ './pack/autopac/start/plug0',
                \ './pack/autopac/start/plug1',
                \ './pack/autopac/opt/plug2',
                \ './pack/autopac/opt/plug3',
                \ './pack/foo/start/plug4',
                \ './pack/foo/start/plug5',
                \ './pack/foo/opt/plug6',
                \ './pack/foo/opt/plug7',
                \ ]
    for dir in plugs
        call mkdir(dir, 'p')
    endfor


    "get a reference to the function under test
    let GetPackages =  autopac#impl#function("get_packages")

    " All plugins
    let p = GetPackages()
    let exp = plugs[:]
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('', '', '', 1)
    call assert_equal(s:getnames(exp), sort(p))

    " All packages
    let p = GetPackages('', 'NONE')
    let exp = ['./pack/foo', './pack/autopac']
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('', 'NONE', '', 1)
    call assert_equal(s:getnames(exp), sort(p))

    " Plugins under autopac
    let p = GetPackages('autopac')
    let exp = plugs[0 : 3]
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('autopac', '', '', 1)
    call assert_equal(s:getnames(exp), sort(p))

    " 'start' plugins
    let p = GetPackages('', 'start')
    let exp = plugs[0 : 1] + plugs[4 : 5]
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('', 'start', '', 1)
    call assert_equal(s:getnames(exp), sort(p))

    " 'opt' plugins
    let p = GetPackages('*', 'opt', '')
    let exp = plugs[2 : 3] + plugs[6 : 7]
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('*', 'opt', '', 1)
    call assert_equal(s:getnames(exp), sort(p))

    " Plugins with 'plug1*' name
    let p = GetPackages('', '', 'plug1*')
    let exp = plugs[1 : 1]
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('', '', 'plug1', 1)
    call assert_equal(s:getnames(exp), sort(p))

    " No match
    let p = GetPackages('autopac', 'opt', 'plug1*')
    let exp = []
    call assert_equal(sort(exp), sort(p))
    " name only
    let p = GetPackages('autopac', 'opt', 'plug1*', 1)
    call assert_equal(s:getnames(exp), sort(p))



    call autopac#impl#clear_pluglist()
    call delete('pack', 'rf')
endfunction


