" Do not use an include guard
"--------------------------------------------------------------------------
" If actions need to be taken before or after a call to PackAdd,
" set g:packadd_cb to the name of a callback function with the following
" signature:
"
"    function packadd_callback(plugname, before)
"--------------------------------------------------------------------------
function! s:load_plugin(bang, ...) abort 
    for l:plug in a:000
        let l:plug = substitute(l:plug, "['\"]", "", "g" )

        if exists('g:packadd_cb') && exists('*'.g:packadd_cb)
            if call(g:packadd_cb, [l:plug, 1]) != 0
                continue
            endif
        endif
    
        execute printf('packadd%s %s', a:bang ? '!' : '', l:plug) 
        
        if exists('g:packadd_cb') && exists('*'.g:packadd_cb)
            call call(g:packadd_cb, [l:plug, 0])
        endif
 
        execute printf('runtime OPT %s/ftdetect/*.vim', l:plug)
    endfor
endfunction

"--------------------------------------------------------------------------

if exists('*autopac#init')
    call autopac#init(exists('g:autopac_options') ? g:autopac_options : {} )
endif

"--------------------------------------------------------------------------

command! -nargs=+ Plugin     if exists('*autopac#add') <bar> call autopac#add(<args>) <bar> endif 
command! -nargs=* PackUpdate packadd autopac | runtime OPT autopac.vim  | call autopac#update(<args>)
command! -nargs=* PackClean  packadd autopac | runtime OPT autopac.vim  | call autopac#clean(<args>)

command! -bar -nargs=+ -bang -complete=packadd PackAdd call s:load_plugin(<bang>0, <f-args>)
cabbrev packadd <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'PackAdd' : 'packadd')<CR>

"--------------------------------------------------------------------------
augroup AutoPac
    au!
    execute printf("runtime! %s", exists('g:autopac_plugins') ? g:autopac_plugins :  'myplugins.vim')
augroup END

"vim: ts=8 sw=4 et


