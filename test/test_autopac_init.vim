
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

function s:check_options(exp)
    let l:act = autopac#impl#options()
    
    for l:key in keys(a:exp)
        call assert_true(has_key(l:act, l:key))
        call assert_equal(a:exp[l:key], l:act[l:key]) 
    endfor
endfunction

function Test_autopac_init()
    "redir! > test.log
    call delete('pack', 'rf')
 
    " Default setting
    call autopac#impl#init()
    call s:check_options(s:std_options)
    call assert_equal(0, len(autopac#impl#pluglist()))

    " Custom options, check that url and dir are paths are fixed
    call autopac#impl#init({"package":"mypacs", 'url':'http://example.com', 'dir': 'fakedir'})
    call s:check_options(
                \extend({"package":"mypacs", 'url':'http://example.com/', 'dir':'fakedir'}
                \, s:std_options, 'keep')
                \)
    call assert_equal(0, len(autopac#impl#pluglist()))

    "redir END
endfunction


