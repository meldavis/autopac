"{{{ 
" vim: foldmarker={{{,}}} foldmethod=marker
let s:pluglist = {}
let s:joblist= []
let s:remain_jobs = 0


"---------------------------------------------------------------------------- }}} 
" PUBLIC:  init(...)                                 {{{
"
" Sets up global options and some defaults for plugins 
"
" Global autopac options - cannot be overridden by plugin 
"   dir      - pack directory                = defaults to first directory in &packpath
"   git      - git executable                = defaults to 'git'
"   jobs     - max number of parallel jobs   = defaults to 8
"   disabled - autopac had unrecoverable error
"
" Plugin default options
"   package - default package name          = defaults to 'autopac'
"   type    - default plugin type           = defaults to 'opt'
"   url     - default domain url            = defaults to 'https://github.com'
"   depth   - default repo depth            = defaults to 1
"   frozen  - download, but never update    = defaults to 0
"   verbose -                               = defaults to 1
"       4 - prints git commands
"       3 = prints git actions (not commands)
"       2 = prints error message when git command failed
"       1 = prints update status for each plugin
"       0 = results
"--------------------------------------------------------------------------------
function! autopac#init(...) abort
    let s:options = extend(copy(get(a:000, 0, {})),
                \{
                \  'dir'            : ''
                \, 'git'            : 'git'
                \, 'jobs'           : 8
                \, 'disabled'       : 0
                \, 'package'        : 'autopac'
                \, 'type'           : 'opt'
                \, 'url'            : 'https://github.com/'
                \, 'depth'          : 1
                \, 'verbose'        : 1
                \, 'frozen'         : 0
                \}
                \, 'keep')

    " Define default pack dir. 
    if s:options.dir == '' && &packpath != ''
        let s:options.dir = split(&packpath, ',')[0]
    endif
    
    " Ensure the pack dir ends in a '/'
    if s:options.dir !~ "[/\\]$"
        let s:options.dir = s:options.dir . '/'
    endif 

    " Add the 'pack' subdir 
    if s:options.dir !~ "pack[\//]$"
        let s:options.dir = s:options.dir .'pack/'
    endif

    " Add trailing '/' to default domain url
    if s:options.url != '' && s:options.url !~ "/$" 
        let s:options.url = s:options.url . '/'
    endif

    let s:pluglist = {}
endfunction

"--------------------------------------------------- }}}
" PUBLIC:  add(plugin, ...)                          {{{
"
" Register plugin info 
"------------------------------------------------------
function! autopac#add(plugname, ...) abort 

    if !s:check_initialization()
        return
    endif

    let l:opt = extend(copy(get(a:000, 0, {})),
                \{
                \  'package': s:options.package
                \, 'name'   : ''
                \, 'type'   : s:options.type 
                \, 'frozen' : s:options.frozen
                \, 'branch' : ''
                \, 'depth'  : s:options.depth
                \, 'verbose': s:options.verbose
                \, 'do'     : ''
                \}
                \,'keep')

    " Do not let user override package name with an empty string
    if l:opt.package == '' 
        let l:opt.package = s:options.package
    endif

    " 
    " Calulate l:opt.url, l:opt.name, l:opt.dir
    "

    " URL (l:opt.url)
    if a:plugname =~? '^[-._0-9a-z]\+\/[-._0-9a-z]\+$'
        " If it has a single '/', assume it is a github URL
        let l:opt.url = s:options.url . a:plugname . '.git'
    else
        let l:opt.url = a:plugname
    endif

    " Name of the plugin (l:opt.name)
    if l:opt.name == ''
        let l:opt.name = matchstr(l:opt.url, '[/\\]\zs[^/\\]\+$')
        let l:opt.name = substitute(l:opt.name, '\C\.git$', '', '')
    endif
    if l:opt.name == ''
        echoerr 'Cannot extract the plugin name. (' . a:plugname . ')'
        return
    endif

    " Directory for repo (l:opt.dir)
    if l:opt.type ==# 'start'
        let l:opt.dir = s:options.dir . l:opt.package . '/start/' . l:opt.name
    elseif l:opt.type ==# 'opt'
        let l:opt.dir = s:options.dir . l:opt.package . '/opt/' . l:opt.name
    else
        echoerr "Wrong type specified for plugin '". l:opt.name ."' (must be 'start' or 'opt'): " . l:opt.type
        return
    endif

    " If the pluginfo was previously added, silently replace it, unless 
    " package or type changed.  In that case, warn first.
    if has_key(s:pluglist, l:opt.name)
        if s:pluglist[l:opt.name].package != l:opt.package
            echohl WarningMsg
            echom printf("Plugin (%s): Package changed from '%s' to '%s')", 
                        \l:opt.name, s:pluglist[l:opt.name].package, l:opt.package) 
            echohl None
        elseif s:pluglist[l:opt.name].type != l:opt.type
            echohl WarningMsg
            echom printf("Plugin (%s): Type changed from '%s' to '%s')", 
                        \l:opt.name, s:pluglist[l:opt.name].type, l:opt.type) 
            echohl None
        elseif s:pluglist[l:opt.name].dir != l:opt.dir
            echohl WarningMsg
            echom printf("Plugin (%s): Path changed from '%s' to '%s')", 
                        \l:opt.name, s:pluglist[l:opt.name].dir, l:opt.dir) 
            echohl None
        endif

    endif
    let s:pluglist[l:opt.name] = l:opt

endfunction

"-------------------------------------------------- }}}
"PUBLIC:  pluginfo(name)                            {{{
" Retrieve info for specified plugin
"------------------------------------------------------
function! autopac#pluginfo(name)
    return get(s:pluglist, a:name, {})
endfunction

"-------------------------------------------------- }}}
"PUBLIC:  clean(...)                                {{{
" Remove plugins that are not registered
" EX: clean( ...)
"     clean('plugin')
"     clean(p1', 'p2')
"     clean(p1', 'p2', {'package': "colors"})
"------------------------------------------------------
function! autopac#clean(...) abort
    if !s:check_initialization()
        return
    endif

    let l:names = []
    let l:opts = {"package": s:options.package} 

    for l:v in a:000 
        if type(l:v) == v:t_string
            call add(l:names, l:v)
        elseif type(l:v) == v:t_list
            call extend(l:names, l:v)
        elseif type(l:v) == v:t_dict
            call extend(l:opts, l:v, 'force')
        else
            echoerr 'Wrong parameter type. Must be string, list of strings or dictionary.'
            return
        endif
    endfor
    call filter(l:names, 'v:val != ""')

    let l:plugin_dirs = s:get_packages(l:opts.package)

    if len(l:names) > 0
        let l:to_remove = filter(l:plugin_dirs,
                    \ {-> s:match_plugin(v:val, l:opts.package, l:names)})
    else
        " Remove all plugins that are not registered.
        let l:safelist = map(keys(s:pluglist),
                    \ {-> s:pluglist[v:val].type . '/' . v:val})
                    \ + ['opt/autopac']  " Don't remove itself.
        let l:to_remove = filter(l:plugin_dirs,
                    \ {-> !s:match_plugin(v:val, l:opts.package, l:safelist)})
    endif

    if len(l:to_remove) == 0
        echo 'Already clean.'
        return
    endif

    " Show the list of plugins to be removed.
    for l:item in l:to_remove
        echo l:item
    endfor

    let l:dir = (len(l:to_remove) > 1) ? 'directories' : 'directory'
    if input('Removing the above ' . l:dir . '. [y/N]? ') =~? '^y'
        echo "\n"
        let err = 0
        for l:item in l:to_remove
            if delete(l:item, 'rf') != 0
                echohl ErrorMsg
                echom 'Clean failed: ' . l:item
                echohl None
                let err = 1
            endif
        endfor
        if has('nvim') && exists(':UpdateRemotePlugins') == 2
            UpdateRemotePlugins
        endif
        if err == 0
            echo 'Successfully cleaned.'
        endif
    else
        echo "\n" . 'Not cleaned.'
    endif
endfunction


"-------------------------------------------------- }}} 
" PUBLIC:  update(...)                              {{{
"
" Update all or specified plugins
"   Ex:
"       update()                    ' updates all plugins
"       update('myplugin')          ' updates single plugin
"       update('plug1, 'plug2")  ' updates several plugins
"   Ex with 'do' hook:
"       update( 'p1', 'p2',  {'do': 'call mycallback()'})
"------------------------------------------------------
function! autopac#update(...) 
    if !s:check_initialization()
        return
    endif

    let l:names = []
    let l:opt =  {'do': ''}

    for l:v in a:000
        if type(l:v) == v:t_string
            if l:v != "" | call add(l:names, l:v) | endif
        elseif type(l:v) == v:t_list
            call extend(l:names, l:v)
        elseif type(l:v) == v:t_dict
            call extend(l:opt, l:v, "force")
        else
            echoerr "Wrong parameter type. Must be string, list or dictionary"
            return
        endif
    endfor
    call filter(l:names, 'v:val != ""')

    if len(l:names) == 0
        let l:names = keys(s:pluglist)
        let l:force = 0
    else
        let l:force = 1
    endif

    if s:remain_jobs > 0
        echom 'Previous update has not been finished.'
        return
    endif

    let l:force = 0
    let s:remain_jobs = len(l:names)
    let s:error_plugins = 0
    let s:updated_plugins = 0
    let s:installed_plugins = 0
    let s:finish_update_hook = l:opt.do

    " Disable the pager temporarily to avoid jobs being interrupted.
    if !exists('s:save_more')
        let s:save_more = &more
    endif
    set nomore

    for l:name in l:names
        let ret = s:update_single_plugin(l:name, l:force)
    endfor
endfunction

"-------------------------------------------------- }}} 
" PRIVATE: check_initialization()                   {{{
"
" Checks autopac intialization
"   Returns 1, if okay to continue
"------------------------------------------------------
function! s:check_initialization() abort 
    
    if !exists('s:options') 
        echohl WarningMsg
        echom 'AutoPac has not been initialized. Using the default values.'
        echohl None
        call autopac#init()
    endif

    if get(s:options, 'disabled', 0)
        return 0
    endif

    if s:options.package == ''
        echohl WarningMsg
        echom "AutoPac's default package name cannot be empty. Setting it to 'autopac'"
        echohl None
        let s:options.package = 'autopac'
    endif

    
    if s:options.url == ''
        echohl WarningMsg
        echom "AutoPac's default repo url cannot be empty. Setting it to 'https://github.com/'"
        echohl None
        let s:options.url = 'https://github.com/'
    endif


    if !isdirectory(s:options.dir)
        try
            call mkdir(s:options.dir, "p")
        catch  
            echoerr 'Failed to create pack directory: ' . v:exception
            echoerr 'Disabling AutoPac'
            let s:options.disabled = 1
            return 0
        endtry
    endif

    if !executable(s:options.git)
        echoerr 'Git executable not found: ' . s:options.git
        echoerr 'Disabling AutoPac'
        let s:options.disabled = 1
        return 0
    endif

    return 1
endfunction

"--------------------------------------------------  }}}
" PRIVATE: update_single_plugin(name, force)        {{{
"------------------------------------------------------

function! s:update_single_plugin(name, force) 
    if !has_key(s:pluglist, a:name)
        echoerr 'Plugin not registered: ' . a:name
        call s:decrement_job_count()
        return 1
    endif

    let l:pluginfo = s:pluglist[a:name]

    if !isdirectory(l:pluginfo.dir)
        let l:pluginfo.installed = 0
        let l:pluginfo.revision = ''
        call s:echo_verbose(3, 'Cloning ' . a:name)

        let l:cmd = [s:options.git, 'clone', '--quiet', l:pluginfo.url, l:pluginfo.dir]
        if l:pluginfo.depth > 0
            let l:cmd += ['--depth=' . l:pluginfo.depth]
        endif
        if l:pluginfo.branch != ''
            let l:cmd += ['--branch=' . l:pluginfo.branch]
        endif
    else
        let l:pluginfo.installed = 1
        if l:pluginfo.frozen && !a:force
            call s:echom_verbose(3, 'Skipped: ' . a:name)
            call s:decrement_job_count()
            return 0
        endif

        call s:echo_verbose(3, 'Updating ' . a:name)
        let l:pluginfo.revision = s:get_plugin_revision(a:name)
        let l:cmd = [s:options.git, '-C', l:pluginfo.dir, 'pull', '--quiet', '--ff-only']
    endif

    call s:echo_verbose(4, join(l:cmd))
    return s:start_job(l:cmd, a:name, 0)

endfunction


"-------------------------------------------------- }}} 
" PRIVATE: get_plugin_revision(name)                {{{
"--------------------------------------------------  
" Get the revision of the specified plugin.
function! s:get_plugin_revision(name) abort
    let l:pluginfo = s:pluglist[a:name]
    let l:dir = l:pluginfo.dir
    let l:cmd = [s:options.git, '-C', l:dir, 'rev-parse', 'HEAD']
    call s:echo_verbose(4, join(l:cmd))

    let l:res = s:system(l:cmd)
    if l:res[0] == 0 && len(l:res[1]) > 0
        return l:res[1][0]
    else
        " Error
        return ''
    endif
endfunction


"-------------------------------------------------- }}} 
" PRIVATE: start_job(cmds, name seq)                {{{
"--------------------------------------------------  
function! s:start_job(cmds, name, seq) abort
    if len(s:joblist) > 1
        sleep 20m
    endif

    if s:options.jobs > 0
        while len(s:joblist) >= s:options.jobs
            sleep 500m
        endwhile
    endif

    let l:job_id = autopac#job#start(s:quote_cmds(a:cmds), {
                \ 'on_stderr': function('s:job_err_cb'),
                \ 'on_exit': function('s:job_exit_cb'),
                \ 'name': a:name, 'seq': a:seq
                \ })
    if l:job_id > 0
        " It worked!
    else
        echohl ErrorMsg
        echom 'Fail to execute: ' . a:cmds[0]
        echohl None
        call s:decrement_job_count()
        return 1
    endif
    let s:joblist += [l:job_id]
    return 0
endfunction


"-------------------------------------------------- }}} 
" PRIVATE: decrement_job_count()                    {{{
"--------------------------------------------------  
function! s:decrement_job_count()
    let s:remain_jobs -= 1
    if s:remain_jobs == 0
        call s:invoke_hook('finish-update', [s:updated_plugins, s:installed_plugins], s:finish_update_hook)

        if has('nvim') && exists(':UpdateRemotePlugins') == 2
                    \ && (s:updated_plugins > 0 || s:installed_plugins > 0)
            UpdateRemotePlugins
        endif

        " Show the status.
        if s:error_plugins != 0
            echohl WarningMsg
            echom 'Error plugins: ' . s:error_plugins
            echohl None
        else
            let l:mes = 'All plugins are up to date.'
            if s:updated_plugins > 0 || s:installed_plugins > 0
                let l:mes .= ' (Updated: ' . s:updated_plugins . ', Newly installed: ' . s:installed_plugins . ')'
            endif
            echom l:mes
        endif

        " Restore the pager.
        if exists('s:save_more')
            let &more = s:save_more
            unlet s:save_more
        endif
    endif

endfunction


"-------------------------------------------------- }}} 
" PRIVATE: echo_verbose(level, msg)                 {{{
"-------------------------------------------------- 
function! s:echo_verbose(level, msg) abort
    if s:options.verbose >= a:level
        echo a:msg
    endif
endfunction

"-------------------------------------------------- }}} 
" PRIVATE: echom_verbose(level, msg)                {{{
"-------------------------------------------------- 
function! s:echom_verbose(level, msg) abort
  if s:options.verbose >= a:level
    echom a:msg
  endif
endfunction


"-------------------------------------------------- }}} 
" PRIVATE: quote_cmds(cmds)                         {{{
"--------------------------------------------------  
if has('win32')
  function! s:quote_cmds(cmds)
    " If space is found, surround the argument with "".
    " Assuming double quotations are not used elsewhere.
    return join(map(a:cmds,
          \ {-> (v:val =~# ' ') ? '"' . v:val . '"' : v:val}), ' ')
  endfunction
else
  function! s:quote_cmds(cmds)
    return a:cmds
  endfunction
endif


"-------------------------------------------------- }}} 
" PRIVATE: system(cmds)                             {{{
"--------------------------------------------------  
" Replacement for system().
" This doesn't open an extra window on MS-Windows.
function! s:system(cmds) abort
  let l:opt = {
        \ 'on_stdout': function('s:system_out_cb'),
        \ 'out': []
        \ }
  let l:job = autopac#job#start(s:quote_cmds(a:cmds), l:opt)
  if l:job > 0
    " It worked!
    let l:ret = autopac#job#wait([l:job])[0]
    sleep 5m    " Wait for out_cb. (not sure this is enough.)
  endif
  return [l:ret, l:opt.out]
endfunction


"-------------------------------------------------- }}} 
" PRIVATE: match_plugin(dir, packname, plugnames)   {{{
"--------------------------------------------------  
function! s:match_plugin(dir, packname, plugnames) abort
  let l:plugname = '\%(' . join(a:plugnames, '\|') . '\)'
  let l:plugname = substitute(l:plugname, '\.', '\\.', 'g')
  let l:plugname = substitute(l:plugname, '\*', '.*', 'g')
  let l:plugname = substitute(l:plugname, '?', '.', 'g')
  if l:plugname =~ '/'
    let l:pat = '/pack/' . a:packname . '/' . l:plugname . '$'
  else
    let l:pat = '/pack/' . a:packname . '/\%(start\|opt\)/' . l:plugname . '$'
  endif
  if has('win32')
    let l:pat = substitute(l:pat, '/', '[/\\\\]', 'g')
    " case insensitive matching
    return a:dir =~? l:pat
  else
    " case sensitive matching
    return a:dir =~# l:pat
  endif
endfunction

"-------------------------------------------------- }}} 
" PRIVATE: get_packages(args)                       {{{
"  All positional arguments are optional: 
"     get_packages(
"            <packname-regex>, 
"            <packtype-regex> | NONE , 
"            <plugname-regex>, 
"            <nameonly>  )
"
"  <packpath>/pack/<packname>/<type>/<plugname>
" Missing or empty string regex values are the same as "*"
" NONE returns the package names instead of the plugin names
" nameonly -returns names without the paths
"--------------------------------------------------  
function! s:get_packages(...) abort
    let l:packname = get(a:000, 0, '')
    let l:packtype = get(a:000, 1, '')
    let l:plugname = get(a:000, 2, '')
    let l:nameonly = get(a:000, 3, 0)

    if l:packname == '' | let l:packname = '*' | endif
    if l:packtype == '' | let l:packtype = '*' | endif
    if l:plugname == '' | let l:plugname = '*' | endif

    if l:packtype ==# 'NONE'
        let l:pat = 'pack/' . l:packname
    else
        let l:pat = 'pack/' . l:packname . '/' . l:packtype . '/' . l:plugname
    endif

    let l:ret = filter(globpath(&packpath, l:pat, 0 , 1), {-> isdirectory(v:val)})
    if l:nameonly
        call map(l:ret, {-> substitute(v:val, '^.*[/\\]', '', '')})
    endif
    return l:ret
endfunction

"-------------------------------------------------- }}} 
" PRIVATE: generate_helptags(dir, force)            {{{
"--------------------------------------------------  
function! s:generate_helptags(dir, force) abort
  if isdirectory(a:dir . '/doc')
    if a:force || len(glob(a:dir . '/doc/tags*', 1, 1)) == 0
      silent! execute 'helptags' a:dir . '/doc'
    endif
  endif
endfunction

"-------------------------------------------------- }}} 
" PRIVATE: invoke_hook(hooktype, args, hook)        {{{
"--------------------------------------------------  
function! s:invoke_hook(hooktype, args, hook) abort
    if a:hook == ''
        return
    endif

    if a:hooktype ==# 'post-update'
        let l:name = a:args[0]
        let l:pluginfo = s:pluglist[l:name]
        let l:cdcmd = haslocaldir() ? 'lcd' : 'cd'
        let l:pwd = getcwd()
        noautocmd execute l:cdcmd fnameescape(l:pluginfo.dir)
    endif
    try
        if type(a:hook) == v:t_func
            call call(a:hook, [a:hooktype] + a:args)
        elseif type(a:hook) == v:t_string
            execute a:hook
        endif
    catch
        echohl ErrorMsg
        echom v:throwpoint
        echom v:exception
        echohl None
    finally
        if a:hooktype ==# 'post-update'
            noautocmd execute l:cdcmd fnameescape(l:pwd)
        endif
    endtry
endfunction

"-------------------------------------------------- }}} 
" CALLBACK: system_out_cb(id, message, event)       {{{
"--------------------------------------------------  
function! s:system_out_cb(id, message, event) dict abort
  let self.out += a:message
endfunction


"-------------------------------------------------- }}} 
" CALLBACK: job_err_cb(id, message, event)          {{{
"--------------------------------------------------  
function! s:job_err_cb(id, message, event) dict abort
  echohl WarningMsg
  for l:line in a:message
    call s:echom_verbose(2, self.name . ': ' . l:line)
  endfor
  echohl None
endfunction

"-------------------------------------------------- }}} 
" CALLBACK: job_exit_cb(id, message, event)         {{{
"--------------------------------------------------  
function! s:job_exit_cb(id, errcode, event) dict abort
    call filter(s:joblist, {-> v:val != a:id})

    let l:err = 1
    if !a:errcode
        let l:pluginfo = s:pluglist[self.name]

        " Check if the plugin directory is available.
        if isdirectory(l:pluginfo.dir)
            " Check if it is actually updated (or installed).
            let l:updated = 1
            if l:pluginfo.revision != ''
                if l:pluginfo.revision ==# s:get_plugin_revision(self.name)
                    let l:updated = 0
                endif
            endif

            if l:updated
                if self.seq == 0 && filereadable(l:pluginfo.dir . '/.gitmodules')
                    " Update git submodule.
                    let l:cmd = [s:options.git, '-C', l:pluginfo.dir, 'submodule', '--quiet',
                                \ 'update', '--init', '--recursive']
                    call s:echom_verbose(3, 'Updating submodules: ' . self.name)
                    call s:echom_verbose(4, join(l:cmd))
                    call s:start_job(l:cmd, self.name, self.seq + 1)
                    return
                endif

                call s:generate_helptags(l:pluginfo.dir, 1)

                if has('nvim') && isdirectory(l:pluginfo.dir . '/rplugin')
                    " Required for :UpdateRemotePlugins.
                    exec 'set rtp+=' . l:pluginfo.dir
                endif

                call s:invoke_hook('post-update', [self.name], l:pluginfo.do)
            else
                " Even if the plugin is not updated, generate helptags if it is not found.
                call s:generate_helptags(l:pluginfo.dir, 0)
            endif

            if l:pluginfo.installed
                if l:updated
                    let s:updated_plugins += 1
                    call s:echom_verbose(1, 'Updated: ' . self.name)
                else
                    call s:echom_verbose(3, 'Already up-to-date: ' . self.name)
                endif
            else
                let s:installed_plugins += 1
                call s:echom_verbose(1, 'Installed: ' . self.name)
            endif
            let l:err = 0
        endif
    endif

    if l:err
        let s:error_plugins += 1
        echohl ErrorMsg
        call s:echom_verbose(1, 'Error while updating "' . self.name . '".  Error code: ' . a:errcode)
        echohl None
    endif

    call s:decrement_job_count()
endfunction

"-------------------------------------------------- }}} 
"==  TEST SUPPORT ================================= {{{
"
if !exists('g:autopac_debug')
    finish
endif
"TEST: pluglist()                                   {{{
function! autopac#pluglist()
    return exists('s:pluglist') ? s:pluglist : {}
endfunction
"-------------------------------------------------- }}}
"TEST: options()                                    {{{
function! autopac#options()
    return exists('s:options') ? s:options : {}
endfunction
"-------------------------------------------------- }}}
"TEST: clear_pluglist()                             {{{
function! autopac#clear_pluglist()  
    let s:pluglist = {}
endfunction
"-------------------------------------------------- }}}
"TEST: function()                                   {{{
" Allow test to access private functions
function! autopac#function(name, ...)  
    if exists("*autopac#".a:name)
        return funcref("autopac#".a:name, a:000)
    elseif exists("*s:".a:name)
        return funcref("s:".a:name, a:000)
    else
        throw "Unknown function:".a:name
    endif
endfunction
"-------------------------------------------------- }}}

"================================================== }}}
