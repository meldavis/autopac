" Tests for autopac.

set rtp^=..
set packpath=.
let g:autopac_debug = 1
runtime plugin/autopac.vim

"------------------------------------
" UTILITY FUNCTIONS
"------------------------------------
let s:key = ""

function s:check(std, vut) 
    call assert_equal(type(a:std), type(a:vut), printf("%sType mismatch", s:key))


    if type(a:std) == v:t_dict
        for key in keys(a:std) 
            if type(a:std[key] == v:t_none) 
                call assert_true(!has_key(a:vut, key), print("[Key %s] should not be present", key))
            else
                call assert_true(has_key(a:vut, key), printf("[Key %s]", key))
                call assert_equal(type(a:std[key]), type(a:vut[key]), printf("[Key %s]", key))
                let s:key = printf("[Key %s] ", key)
                call s:check(a:std[key], a:vut[key])            
                let s:key = ""
            endif
        endfor
    elseif type(a:std) == v:t_string || type(a:std) == v:t_number
        call assert_equal(a:std, a:vut, printf("%s", s:key))
    endif
    call assert_false(0, "Unexpected type")
endfunction

function s:check_options(std)
    let vut = autopac#options()
    call s:check(a:std, vut)
endfunction

function s:check_pluginfo(plug, std)
    let vut = autopac#pluginfo(a:plug)
    call s:check(a:std, vut)
endfunction


let s:std_options = 
            \{ 'package': 'autopac'
            \, 'dir': './pack/'
            \, 'git': 'git'
            \, 'jobs': 8
            \, 'type':'opt'
            \, 'url': 'https://github.com/'
            \, 'depth': 1
            \, 'frozen': 0
            \, 'verbose': 1
            \}

let s:std_pluginfo = 
            \{ 'package': s:std_options.package
            \, 'name'   : ''
            \, 'type'   : s:std_options.type 
            \, 'frozen' : s:std_options.frozen
            \, 'branch' : ''
            \, 'depth'  : s:std_options.depth
            \, 'verbose': s:std_options.verbose
            \, 'do'     : ''
            \}
"------------------------------------
" TESTS
"------------------------------------
function Test_autopac_init()
    "redir! > test.log
    call delete('pack', 'rf')
    call autopac#clear_pluglist()

    " Default setting
    call autopac#init()
    call s:check_options(s:std_options)
    call assert_equal(0, len(autopac#pluglist()))

    " Custom options, check that url and dir are paths are fixed
    call autopac#init({"package":"mypacs", 'url':'http://example.com', 'dir': 'fakedir'})
    call s:check_options(
                \extend({"package":"mypacs", 'url':'http://example.com/', 'dir':'fakedir/pack/'}
                \, s:std_options, 'keep')
                \)
    call assert_equal(0, len(autopac#pluglist()))

    call autopac#clear_pluglist()
    "redir END
endfunction

function Test_autopac_add()
    "redir! > test.log
    call delete('pack', 'rf')
    call autopac#clear_pluglist()

    call autopac#init()

    " Default plugin values
    call autopac#add("example/abc")
    call assert_equal(1, len(autopac#pluglist()))
    call s:check_pluginfo('abc', extend( 
                \{ 'package': 'autopac'
                \, 'name':'abc'
                \, 'url': 'https://github.com/example/abc.git'
                \, 'dir': './pack/autopac/opt/abc'
                \}
                \, s:std_pluginfo, 'keep') )

    " Plugin in custom package
    call autopac#add("http://git.nickel.local/example/abc", {'package':'colors'})
    call assert_equal(1, len(autopac#pluglist()))
    call s:check_pluginfo('abc', extend( 
                \{ 'package': 'colors'
                \, 'name':'abc'
                \, 'url': 'http://git.nickel.local/example/abc'
                \, 'dir': './pack/colors/opt/abc'
                \}
                \, s:std_pluginfo, 'keep') )

    " 
    call autopac#add("file:///mydir/abc.git" )
    call assert_equal(1, len(autopac#pluglist()))
    call s:check_pluginfo('abc', extend( 
                \{ 'package': 'autopac'
                \, 'name':'abc'
                \, 'url': 'file:///mydir/abc.git'
                \, 'dir': './pack/autopac/opt/abc'
                \}
                \, s:std_pluginfo, 'keep') )


    call autopac#clear_pluglist()
    call delete('pack', 'rf')
    "redir END
endfunction

" Test get_packages

func s:getnames(plugs)
    return sort(map(a:plugs, {-> substitute(v:val, '^.*[/\\]', '', '')}))
endfunc


function Test_autopac_get_packages()
    "redir! > test.log
    call delete('pack', 'rf')
    call autopac#clear_pluglist()


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
    let GetPackages =  autopac#function("get_packages")

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



    call autopac#clear_pluglist()
    call delete('pack', 'rf')
    "redir END
endfunction


