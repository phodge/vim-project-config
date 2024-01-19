fun! vimprojectconfig#_settings#getValidProjectConfigDirs()
  let l:dirs = get(g:vimprojectconfig#usersettings, 'project_config_dirs', {})

  " TODO: PC006: add E2E tests ensuring these error messages are always helpful/nice
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

fun! vimprojectconfig#_settings#getValidProjectStoreDir(storename)
  " Return the full path to the directory storing configs for the given
  " storename

  let l:dirs = vimprojectconfig#_settings#getValidProjectConfigDirs()

  let l:dir = get(l:dirs, a:storename, v:null)
  if l:dir is v:null
    " TODO: PC006: add E2E tests ensuring this error messages is always helpful/nice
    throw printf(
          \ 'ERROR: g:vimprojectconfig#usersettings.project_config_dirs does not contain any entry for "%s"',
          \ a:storename)
  endif

  " note that the directory may not exist
  return l:dir
endfun
