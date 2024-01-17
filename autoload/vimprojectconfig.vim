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
endfun
