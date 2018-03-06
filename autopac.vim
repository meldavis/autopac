" Do not use an include guard
"--------------------------------------------------------------------------
function! s:load_plugin(bang, ...) abort 
    let l:bang = a:bang ? '!' : ''
    for l:plug in a:000
        let l:plug = substitute(l:plug, "['\"]", "", "g" )
        execut 'packadd' . l:bang . ' ' . l:plug
        execut printf('runtime after/pack/%s.vim', l:plug)
    endfor
endfunction

"--------------------------------------------------------------------------

"
"Commands:
"   Plugin
"   PackUpdate
"   PackClean
"
" Plugins are placed in myplugins.vim in root of $VIMFILES

command! -nargs=+ Plugin     if exists('*autopac#add') <bar> call autopac#add(<args>) <bar> endif 
command! -nargs=* PackUpdate packadd autopac | runtime myplugins.vim  | call autopac#update(<args>)
command! -nargs=* PackClean  packadd autopac | runtime myplugins.vim  | call autopac#clean(<args>)

command! -bar -nargs=+ -bang -complete=packadd PackAdd call s:load_plugin(<bang>0, <f-args>)
cabbrev packadd <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'PackAdd' : 'packadd')<CR>

runtime! OPT ftdetect/*.vim

augroup AutoPac
    au!
    runtime! myplugins.vim
augroup END


