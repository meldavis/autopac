
if exists('g:loaded_autopac') && !exists('g:autopac_debug')
  finish
endif
let g:loaded_autopac = 1


"
"Commands:
"   Plugin
"   PackUpdate
"   PackClean
"
" Plugins are placed in myplugins.vim in root of $VIMFILES

if exists('*autopac#init')
    call autopac#init()
    command! -nargs=+ -bar Plugin call autopac#add(<args>) | call s:register_plugin_for_type(<args>)
else
    command! -nargs=+ Plugin call s:register_plugin_for_type(<args>)
endif



command! -bar -nargs=* PackUpdate packadd autopac | runtime OPT autopac.vim | call autopac#update(<args>)
command! -bar -nargs=* PackClean  packadd autopac | runtime OPT autopac.vim | call autopac#clean(<args>)
command! -bar -nargs=+ -bang -complete=packadd PackAdd call s:load_plugin(<bang>0, <f-args>)
cabbrev packadd <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'PackAdd' : 'packadd')<CR>

runtime! OPT ftdetect/*.vim

augroup AutoPac
    au!
    runtime! myplugins.vim
augroup END

"--------------------------------------------------------------------------

function! s:load_plugin(bang, ...) abort 
    let l:bang = a:bang ? '!' : ''
    for l:plug in a:000
        let l:plug = substitute(l:plug, "['\"]", "", "g" )
        execut 'packadd' . l:bang . ' ' . l:plug
        execut printf('runtime after/pack/%s.vim', l:plug)
    endfor
endfunction


function! s:register_plugin_for_type(repo, ...) abort
    let l:opts = get(a:000, 0, {})
    if has_key(l:opts, 'for')
        let l:name = substitute(a:repo, '^.*/', '', '')
        let l:ft = type(l:opts.for) == type([]) ? join(l:opts.for, ',') : l:opts.for
        execut printf('autocmd FileType %s packadd %s', l:ft, l:name)
    endif
endfunction


