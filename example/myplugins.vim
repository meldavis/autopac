" vim: sw=4 et
" NOTE: 
"     Install autopac into '~/pack/unmanaged/opt/'
"     Include this line in your vimrc
"          :runtime OPT autopac.vim

" Some common settings:
"   g:packadd_cb:
"      Set this g:packadd_cb and create the function if you need
"      special handling before/after a plugin is loaded
"
"   g:autopac_options:
"       I set my default package name to 'general'.
"
"   g:vimball_home:
"       I use a few of Dr.Chips plugins. They should be placed in an 
"       unmanaged package so that PackClean will not delete them.
"       When installing a vimball, first :let g:vimball_home = g:vimball."<plugname>"
"
" Updating plugin list:
"   After updating this file run:
"       :so % | PackUpdate
"
" No longer want a plugin?:
"   Remove the Plugin <plug> line, save this file, and run:
"       :so % | PackClean
"   or
"       :so % | PackClean '<plugname>'

let g:packadd_cb        = 'myplugins#callback'
let g:autopac_options   = {'package':'general'} 
let g:vimball           = expand('~/vimfiles/pack/unmanaged/opt/')

"===================================================
" Colorschemes
"===================================================
" I rename themes so that they will appear last in the :packadd completions
" I also put all themes in the 'colors' package.
"
" Note: vim automactically searches the 'opt' packages for colorshemes. 
" You should not put them in start unless they come with special plugins.

Plugin 'NLKNguyen/papercolor-theme'             , {'package':'colors', 'name':'zz-papercolor'}
Plugin 'morhetz/gruvbox'                        , {'package':'colors', 'name':'zz-gruvbox'}
Plugin 'dracula/vim'                            , {'package':'colors', 'name':'zz-dracula'}
Plugin 'jnurmine/Zenburn'                       , {'package':'colors', 'name':'zz-zenburn'}
Plugin 'sjl/badwolf'                            , {'package':'colors', 'name':'zz-badwolf'}
Plugin 'nanotech/jellybeans.vim'                , {'package':'colors', 'name':'zz-jellybeans'}

"===================================================
" General Utilities
"===================================================

"--- NERDTree and helpers ---

Plugin 'scrooloose/nerdtree'
Plugin 'ryanoasis/vim-devicons'                , {'name':'devicons'}
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
let g:WebDevIconsUnicodeDecorateFolderNodes = 1


"--- NERDCommenter ---
Plugin 'scrooloose/nerdcommenter'

"--- Calendar ---
Plugin 'mattn/calendar-vim'                 , {'name':'calendar'}


"===================================================
" Async Utils
"===================================================
"
Plugin 'prabirshrestha/async.vim'           , {'package':'async', 'name':'async'}
Plugin 'prabirshrestha/vim-lsp'             , {'package':'async'}
Plugin 'prabirshrestha/asyncomplete.vim'    , {'package':'async', 'name':'asyncomplete'}
Plugin 'prabirshrestha/asyncomplete-lsp.vim', {'package':'async', 'name':'asyncomplete-lsp'}
Plugin 'skywind3000/asyncrun.vim'           , {'package':'async'}


"===================================================
" Rust Development
"===================================================
" Requires the first 4 async plugins, above.
" Optionally depends on syntastic
Plugin 'rust-lang/rust.vim'                 , {'name':'rust'}                 


"===================================================
" Syntax Checkers
"===================================================
Plugin 'vim-syntastic/sytastic'            
Plugin 'w0rp/ale'


"||||||||||||||||||||||||||||||||||||||||||||||||||||||
" These plugins will be loaded after vimrc. This is an 
" alternative to installing into 'start' folders.
"
" Note the ! character
" 
PackAdd! 'calendar' 'NERDCommenter'
"||||||||||||||||||||||||||||||||||||||||||||||||||||||



" Only load NERDTree when needed
if mapcheck("<F1>") == ""
    noremap  <silent>   <F1>       :if !exists('*NERDTreeToggle') <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeToggle<CR><ESC>
    inoremap <silent>   <F1> <ESC> :if !exists('*NERDTreeToggle') <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeToggle<CR><ESC>
    noremap  <silent> <C-F1>       :if !exists('*NERDTreeFind')   <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeFind<CR><ESC>
    inoremap <silent> <C-F1> <ESC> :if !exists('*NERDTreeFind')   <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeFind<CR><ESC>
endif 


" Load rust plugin only when editing rust
au vimrc FileType rust PackAdd rust


" This function is called before/after a plugin is loaded with PackAdd.
function! myplugins#callback(plugname, before)
    "----------------------------------------------------------------------
    if a:plugname == "nerdtree"
        if a:before
            let g:NERDTreeBookmarksFile = $VIMDATA . '.NERDTreeBookmarks'
            PackAdd 'devicons' 'vim-nerdtree-syntax-highlight'
        endif        
        "----------------------------------------------------------------------
    elseif a:plugname == "asyncrun"      
        if a:before
            augroup ASYNCRUN
                autocmd!
                " Automatically open the quickfix window
                autocmd User AsyncRunStart call asyncrun#quickfix_toggle(15, 1)
            augroup END
        endif
        "----------------------------------------------------------------------
    elseif a:plugname == "rust"
        if a:before
            let g:rustfmt_autosave = 1
            
            if executable('rls')
                au vimrc User lsp_setup call lsp#register_server({
                            \ 'name': 'rls',
                            \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
                            \ 'whitelist': ['rust'],
                            \ })
            endif 
            
            PackAdd async asyncomplete asyncomplete-lsp vim-lsp 
        endif
    endif
    "----------------------------------------------------------------------
endfunction
