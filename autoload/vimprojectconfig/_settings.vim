fun! vimprojectconfig#_settings#getValidProjectConfigDirs()
  let l:dirs = get(g:vimprojectconfig#usersettings, 'project_config_dirs', {})

  if type(l:dirs) != type({})
    throw 'ERROR: g:vimprojectconfig#usersettings.project_config_dirs is not a dict'
  elseif len(l:dirs) == 0
    throw 'ERROR: g:vimprojectconfig#usersettings.project_config_dirs does not contain any entries'
          \ . ' - did you call vimprojectconfig#initialise() yet?'
  endif

  " Note: any further validation of the contents of the dict should have been
  " handled by vimprojectconfig#initialise()

  return l:dirs
endfun
