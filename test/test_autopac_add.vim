" Tests for autopac.

set rtp^=..
set packpath=.
let g:autopac_debug = 1
runtime plugin/autopac.vim

let s:std_options = 
            \{ 'package': 'autopac'
            \, 'dir': '.'
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

function s:check_pluginfo(name, exp)
    let l:act = autopac#impl#pluginfo(a:name)
    
    for l:key in keys(a:exp)
        call assert_true(has_key(l:act, l:key))
        call assert_equal(a:exp[l:key], l:act[l:key]) 
    endfor
endfunction


"------------------------------------
" TESTS
"------------------------------------
function Test_autopac_add()
    "redir! > test.log
    call delete('pack', 'rf')

    call autopac#impl#init()

    " Default plugin values
    call autopac#impl#add("example/abc")
    call assert_equal(1, len(autopac#impl#pluglist()))
    call s:check_pluginfo('abc', extend( 
                \{ 'package': 'autopac'
                \, 'name':'abc'
                \, 'url': 'https://github.com/example/abc.git'
                \, 'dir': './pack/autopac/opt/abc'
                \}
                \, s:std_pluginfo, 'keep') )

    " Plugin in custom package
    call autopac#impl#add("http://git.nickel.local/example/abc", {'package':'colors'})
    call assert_equal(1, len(autopac#impl#pluglist()))
    call s:check_pluginfo('abc', extend( 
                \{ 'package': 'colors'
                \, 'name':'abc'
                \, 'url': 'http://git.nickel.local/example/abc'
                \, 'dir': './pack/colors/opt/abc'
                \}
                \, s:std_pluginfo, 'keep') )

    " 
    call autopac#impl#add("file:///mydir/abc.git" )
    call assert_equal(1, len(autopac#impl#pluglist()))
    call s:check_pluginfo('abc', extend( 
                \{ 'package': 'autopac'
                \, 'name':'abc'
                \, 'url': 'file:///mydir/abc.git'
                \, 'dir': './pack/autopac/opt/abc'
                \}
                \, s:std_pluginfo, 'keep') )


    call delete('pack', 'rf')
    "redir END
endfunction

