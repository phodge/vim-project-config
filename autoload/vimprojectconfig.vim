if ! exists('g:vimprojectconfig#usersettings')
  " make sure this always exists
  let g:vimprojectconfig#usersettings = {}
endif

fun! vimprojectconfig#initialise(usersettings)
  " in case the global has been overwritten with something else
  if type(get(g:, 'vimprojectconfig#usersettings')) != type({})
    let g:vimprojectconfig#usersettings = {}
  endif

  " local ref
  let l:settings = g:vimprojectconfig#usersettings

  " TODO: PC002: actually validate a:usersettings before storing
  let l:settings.project_config_dirs = get(a:usersettings, 'project_config_dirs', {})

  " TODO:: PC007: validate it is callable
  let l:settings.get_project_root = get(a:usersettings, 'get_project_root', v:null)
endfun

" reset any existing autocmds
aug VimProjectConfig
au!
aug end

" TODO: PC025: add E2E tests for this core part of the plugin
" PC008 provide more efficient hooks
au! VimProjectConfig BufEnter * call vimprojectconfig#_engine#dispatch('BufEnter')

fun! vimprojectconfig#edit()
  let [l:cfg, l:projectid, l:projectroot] = vimprojectconfig#_configs#getCfgForBuffer(bufnr(), v:true)

  if l:cfg is v:null
    " if there is no config, try and create a new one
    if l:projectid is v:null && l:projectroot is v:null
      " abort - note that getCfgForBuffer() should have reported to the user
      return
    endif

    let l:cfg = vimprojectconfig#_ui#createConfigOrLinkProject(l:projectid, l:projectroot)

    if l:cfg is v:null
      " aborted
      return
    endif
  endif

  call vimprojectconfig#_ui#openConfigFile(l:cfg)
endfun
