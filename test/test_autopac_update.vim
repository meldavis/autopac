set rtp^=..
set packpath=.
let g:autopac_debug = 1
runtime plugin/autopac.vim

" Tests for autopac#impl#update()
func Test_autopac_update()
    call delete('pack', 'rf')
    call autopac#impl#init()

    " autopac#impl#update() with hooks using strings.
    call autopac#impl#add('k-takata/minpac', {'type': 'opt',
                \ 'do': 'let g:post_update = 1'})
    let g:post_update = 0
    let g:finish_update = 0
    call autopac#impl#update({'do': 'let g:finish_update = 1'})
    while g:finish_update == 0
        sleep 1
    endwhile
    call assert_equal(1, g:post_update)
    call assert_true(isdirectory('pack/autopac/opt/minpac'))

    " autopac#impl#update() with hooks using funcrefs.
    let l:post_update = 0
    call autopac#impl#add('k-takata/hg-vim', {'type':'start', 'do': {hooktype, name -> [
                \ assert_equal('post-update', hooktype, 'hooktype'),
                \ assert_equal('hg-vim', name, 'name'),
                \ execute('let l:post_update = 1'),
                \ l:post_update
                \ ]}})
    let l:finish_update = 0
    call autopac#impl#update({'do': {hooktype, updated, installed -> [
                \ assert_equal('finish-update', hooktype, 'hooktype'),
                \ assert_equal(0, updated, 'updated'),
                \ assert_equal(1, installed, 'installed'),
                \ execute('let l:finish_update = 1'),
                \ l:finish_update
                \ ]}})
    while l:finish_update == 0
        sleep 1
    endwhile
    call assert_equal(1, l:post_update)
    call assert_true(isdirectory('pack/autopac/start/hg-vim'))

    call delete('pack', 'rf')
endfunc

