
set rtp^=..
set packpath=.

" This will give us access to private functions in autopac's
" autoload/autopac.vim
let g:autopac_debug = 1
runtime plugin/autopac.vim


function Test_autopac_matchplugin()
 
    "get a reference to the function under test
    let MatchPlugin =  autopac#impl#function("match_plugin")

    let p = './pack/autopac/start/plug0'
    call assert_true (MatchPlugin(p, '',                    "plug0"))
    call assert_true (MatchPlugin(p, [],                    "plug0"))
    call assert_true (MatchPlugin(p, '',                    "start/plug0"))
    call assert_true (MatchPlugin(p, [],                    "start/plug0"))
    call assert_true (MatchPlugin(p, "autopac",             "plug0"))
    call assert_true (MatchPlugin(p, ["autopac"],           "plug0"))
    call assert_true (MatchPlugin(p, ["autopac"],           "start/plug0"))
    call assert_true (MatchPlugin(p, ["autopac",'zzz'],     "start/plug0"))
    call assert_true (MatchPlugin(p, ["autopac"],           "start/plug?"))
    call assert_true (MatchPlugin(p, ["autopac"],           "start/*"))

    " wrong plug name
    call assert_false(MatchPlugin(p, '',                    "plug1"))
    call assert_false(MatchPlugin(p, [],                    "plug1"))
    call assert_false(MatchPlugin(p, '',                    "start/plug1"))

    " wrong type
    call assert_false(MatchPlugin(p, '',                    "opt/plug0"))
    call assert_false(MatchPlugin(p, [],                    "opt/plug0"))

    " any type
    call assert_true (MatchPlugin(p, '',                    "*/plug0"))
    call assert_false(MatchPlugin(p, [],                    "*/plug1"))
    
    " multple plug regex's 
    call assert_true (MatchPlugin(p, ['autopac'],           ['plug0', 'plug1']))

    " specified package
    call assert_true (MatchPlugin(p, [],                    "autopac/start/plug0"))
    call assert_false(MatchPlugin(p, [],                    "autopac/opt/plug0"))

    " apply package parameter only to plugnames without a package component
    " In these 5 examples, the 'zzz' is not applied to the regex's
    call assert_true (MatchPlugin(p, ['zzz'],               "autopac/start/plug0"))
    call assert_false(MatchPlugin(p, ['zzz'],               "autopac/opt/plug0"))
    call assert_true (MatchPlugin(p, ['zzz'],               "*/start/plug0"))
    call assert_false(MatchPlugin(p, ['zzz'],               "*/opt/plug0"))
    call assert_true (MatchPlugin(p, ['zzz'],               "*/*/plug0"))

    " In the three below, the pkgnames are applied to the 2nd regex, but
    " not the first. 
    call assert_true (MatchPlugin(p, ['zzz'],               ['*/start/plug0', 'plug1']))
    call assert_false(MatchPlugin(p, ['zzz'],               ['*/start/plug1', 'plug0']))
    call assert_true (MatchPlugin(p, ['autopac'],           ['*/start/plug1', 'plug0']))
    call assert_true (MatchPlugin(p, ['zzz', 'autopac'],    ['*/start/plug1', 'plug0']))

endfunction


