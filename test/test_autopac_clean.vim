
set rtp^=..
set packpath=.
let g:autopac_debug = 1
runtime plugin/autopac.vim

" Tests for autopac#impl#clean()
func Test_autopac_clean()
  call delete('pack', 'rf')

  call autopac#impl#init()

  let plugs = [
	\ 'pack/autopac/opt/plug0',
	\ 'pack/autopac/opt/plug1',
	\ 'pack/autopac/start/plug2',
	\ 'pack/autopac/start/plug3',
	\ 'pack/autopac/start/autopac',
	\ 'pack/autopac/opt/autopac',
	\ 'pack/colors/opt/plug6',
	\ 'pack/colors/opt/plug7',
    \ 'pack/unmanaged/opt/plug8',
    \ 'pack/unmanaged/start/plug9',
    \ 'pack/unmanaged/start/plug10'
	\ ]
  for dir in plugs
    call mkdir(dir, 'p')
  endfor

  " Just type Enter. All plugins should not be removed.
  call feedkeys(":call autopac#impl#clean()\<CR>\<CR>", 'x')
  for dir in plugs
    call assert_true(isdirectory(dir))
  endfor

  " Register some plugins
  call autopac#impl#add('foo', {'name': 'plug0', 'type':'opt'})         " opt/plug0
  call autopac#impl#add('bar/plug2', {'type': 'start'})                 " start/plug2
  call autopac#impl#add('baz/plug3', {'type': 'opt'})                   " opt/plug3
  call autopac#impl#add('baz/plug6', {'type': 'opt', 'package':'colors'}) "colors/opt/plug6

  " Type y and Enter. Unregistered plugins should be removed.
  " 'opt/autopac' should not be removed even it is not registered.
  call feedkeys(":call autopac#impl#clean()\<CR>y\<CR>", 'x')
  call assert_equal(1, isdirectory(plugs[0]))  " keep      opt/plug0
  call assert_equal(0, isdirectory(plugs[1]))  " remove    opt/plug1
  call assert_equal(1, isdirectory(plugs[2]))  " keep    start/plug2
  call assert_equal(0, isdirectory(plugs[3]))  " remove  start/plug3
  call assert_equal(0, isdirectory(plugs[4]))  " remove  start/autopac
  call assert_equal(1, isdirectory(plugs[5]))  " keep      opt/autopac
  call assert_equal(1, isdirectory(plugs[6]))  " keep    colors/opt/plug6 - registered
  call assert_equal(0, isdirectory(plugs[7]))  " remove  colors/opt/plug7 - not registered

  " Specify a plugin. It should be removed even it is registered.
  " But not if it is an unmanaged package
  call feedkeys(":call autopac#impl#clean('plug0')\<CR>y\<CR>", 'x')
  call assert_equal(0, isdirectory(plugs[0]))  " remove   opt/plug0
  call assert_equal(1, isdirectory(plugs[2]))  " keep   start/plug2
  call assert_equal(1, isdirectory(plugs[5]))  " keep     opt/autpac

  " 'opt/autopac' can be also removed when it is specified.
  call autopac#impl#add('k-takata/autopac', {'type': 'opt'})
  call feedkeys(":call autopac#impl#clean('autopa?')\<CR>y\<CR>", 'x')
  call assert_equal(1, isdirectory(plugs[2]))  " keep   start/plug2  
  call assert_equal(0, isdirectory(plugs[5]))  " remove   opt/autopac

  " Type can be also specified.
  " Not match - so this should not prompt for a removal since nothing matches
  call autopac#impl#clean('opt/plug2')
  call assert_equal(1, isdirectory(plugs[2]))
  " Match
  call feedkeys(":call autopac#impl#clean('start/plug*')\<CR>y\<CR>", 'x')
  call assert_equal(0, isdirectory(plugs[2]))

  " Remove all plugins in a package
  call assert_equal(1, isdirectory(plugs[6]))  " keep    colors/opt/plug6 - registered
  call feedkeys(":call autopac#impl#clean('colors/*/*')\<CR>y\<CR>", 'x')
  call assert_equal(0, isdirectory(plugs[6]))  " remove  colors/opt/plug6

  " all of our unmanaged plugins should still be there
  call assert_equal(1, isdirectory(plugs[8]))
  call assert_equal(1, isdirectory(plugs[9]))
  call assert_equal(1, isdirectory(plugs[10]))
  "
endfunc

