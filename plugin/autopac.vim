function! autopac#init(...) abort
    call call("autopac#impl#init", a:000)
endfunction

function! autopac#add(plugname, ...) abort 
    call call("autopac#impl#add", [a:plugname] + a:000)
endfunction

function! autopac#pluginfo(name)
    return call("autopac#impl#pluginfo", a:name)
endfunction

function! autopac#clean(...) abort
    call call("autopac#impl#clean", a:000)
endfunction

function! autopac#update(...) abort
    call call("autopac#impl#update", a:000)
endfunction

