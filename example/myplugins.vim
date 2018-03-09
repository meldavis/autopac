" INSTALL: 
"   1. Clone the autopac repo into '~/pack/unmanaged/opt/'
"   2. In your vimrc: add the following line:
"       runtime OPT autopac.vim
"   3. In your vimfiles folder, create a myplugins.vim 
"
" There is rarely a need to install packages in 'start' subfolders.
" It is more flexible to install into 'opt' subfolders and 
" then add calls to 'packadd! <plug>' to start plugins when vim starts.
"
" By default, autopac installs plugins into 'pack/autopac/opt/'.
" Autopac will not clean (delete) plugins in unmanaged packages, which
" by default is 'pack/unmaanged/*'
"
" In the settings below, 
"   * I change the default package name from 'autopac' to 'general'.
"   * I set a callback function that will handle dependencies 
"       between plugins. (The function is defined at the end of this file.)

let g:packadd_cb        = 'myplugins#callback'
let g:autopac_options   = {'package':'general'} 
let g:vimball           = expand('~/vimfiles/pack/unmanaged/opt/')

augroup myplugins | au! | augroup END

"===================================================
" Colorschemes
"===================================================
" I rename themes so that they will appear last in the :packadd completions
" I also put all themes in the 'colors' package.
"
" Note: vim automactically searches the 'opt' packages for colorshemes. 
" You almost never need to auto-start or packadd a colorscheme to use one.

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
Plugin 'ryanoasis/vim-devicons'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
let g:WebDevIconsUnicodeDecorateFolderNodes = 1


"--- NERDCommenter ---
Plugin 'scrooloose/nerdcommenter'

"--- Calendar ---
Plugin 'mattn/calendar-vim'                 , {'name':'calendar'}


"===================================================
" Async Util
"===================================================
"Note: vim-lsp requires async, asyncomplete, asynccomplet-lsp

Plugin 'prabirshrestha/async.vim'           , {'package':'async', 'name':'async'}
Plugin 'prabirshrestha/vim-lsp'             , {'package':'async'}
Plugin 'prabirshrestha/asyncomplete.vim'    , {'package':'async', 'name':'asyncomplete'}
Plugin 'prabirshrestha/asyncomplete-lsp.vim', {'package':'async', 'name':'asyncomplete-lsp'}
Plugin 'skywind3000/asyncrun.vim'           , {'package':'async'}


"===================================================
" Rust Development
"===================================================
" The rust plugin requires vim-lsp

Plugin 'rust-lang/rust.vim'                 , {'name':'rust'}                 


"===================================================
" Syntax Checkers
"===================================================
Plugin 'vim-syntastic/sytastic'            
Plugin 'w0rp/ale'


"||||||||||||||||||||||||||||||||||||||||||||||||||||||
" AUTOSTART 
"
" These plugins will be loaded after vimrc. This is an 
" alternative to installing into 'start' folders.
"
" Note the ! character
" 
PackAdd! 'calendar' 'nerdcommenter'
"||||||||||||||||||||||||||||||||||||||||||||||||||||||


" Load NERDTree only when needed
if mapcheck("<F1>") == ""
    noremap  <silent>   <F1>       :if !exists('*NERDTreeToggle') <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeToggle<CR><ESC>
    inoremap <silent>   <F1> <ESC> :if !exists('*NERDTreeToggle') <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeToggle<CR><ESC>
    noremap  <silent> <C-F1>       :if !exists('*NERDTreeFind')   <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeFind  <CR><ESC>
    inoremap <silent> <C-F1> <ESC> :if !exists('*NERDTreeFind')   <bar> :PackAdd 'nerdtree' <bar> :endif <bar> :NERDTreeFind  <CR><ESC>
endif 


" Load rust plugin only when editing rust
au vimrc FileType rust PackAdd rust



" This function (named in g:packadd_cb) is called before/after a plugin 
" is loaded with PackAdd. It is entirely optional.
"
" Its purpose is to 
"   1. Provide a way to handle dependencies between plugins,
"   2. Delay creating plugin settings until absolutely needed.
"
" NOTE: packadd fails silently if is a package does not exist. The only way to 
" tell if a plugin is loaded is by checking for the existence  of 
" plugin-specific functions or variables
"
" Most plugins have include-guards, so it should make little difference
" if a package is added multiple times.
"
function! myplugins#callback(plugname, before)

    if !a:before | return | endif
    "----------------------------------------------------------------------

    if a:plugname == "nerdtree"
        let g:NERDTreeBookmarksFile = $VIMDATA . '.NERDTreeBookmarks'
        PackAdd 'vim-devicons' 'vim-nerdtree-syntax-highlight'
        "----------------------------------------------------------------------

    elseif a:plugname == "asyncrun"       
        augroup packadd_asyncrun 
            au! packadd_asyncrun User AsyncRunStart call asyncrun#quickfix_toggle(15, 1)
        augroup packadd_asyncrun
        "----------------------------------------------------------------------
    
    elseif a:plugname == "rust"
        PackAdd vim-lsp 
        "----------------------------------------------------------------------
    
    elseif a:plugname == "vim-lsp"
        augroup packadd_vim_lsp | au! | augroup END

        if executable('rls')
            au packadd_vim_lsp User lsp_setup call lsp#register_server({
                        \ 'name': 'rls',
                        \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
                        \ 'whitelist': ['rust'],
                        \ })
        endif 

        if executable('pyls')
            au packadd_vim_lsp User lsp_setup call lsp#register_server({
                \ 'name': 'pyls',
                \ 'cmd': {server_info->['pyls']},
                \ 'whitelist': ['python'],
                \ })
        endif

        
        PackAdd async asyncomplete asyncomplete-lsp 
    "----------------------------------------------------------------------
    
    endif
endfunction

