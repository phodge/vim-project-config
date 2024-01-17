fun! <SID>getAllConfigs()
  let l:dirs = vimprojectconfig#_settings#getValidProjectConfigDirs()

  let l:return = []

  for [l:storename, l:dir] in items(l:dirs)
    if ! isdirectory(l:dir)
      " it is safe to silently ignore a project config dir if it doesn't exist
      " yet
      continue
    endif

    for l:entry in readdir(l:dir)
      let l:configdir = l:dir . '/' . l:entry
      if l:entry !~ '^\.' && isdirectory(l:configdir)
        " TODO: PC004: initscript may be "project.lua"
        let l:initscript = 'project.vim'
        call add(l:return, <SID>createConfigLocInstance(l:storename, l:entry, l:configdir, l:initscript))
      endif
    endfor
  endfor

  return l:return
endfun

fun! <SID>readExistingCfg(configloc)
  let l:description = v:null
  let l:paths = []

  let l:head = readfile(vimprojectconfig#_configs#getConfigInitPath(a:configloc.initpath), '', 50)
  let l:state = 'expect_description'
  for l:line in l:head
    if l:state == 'expect_description'
      if l:line =~ '^"\s*Project:'
        let l:description = substitute(l:line, '^"\s*Project:\s*', '', '')
        let l:state = 'expect_fields'
        continue
      endif
      throw printf('ERROR: expect %s to begin with ''" <DESCRIPTION>''', a:configloc.initpath)
    endif

    if l:state == 'expect_fields'
      if l:line =~ '^"\s*ProjectID:\s*'
        let l:project_id = substitute(l:line, '^"\s*ProjectID:\s*', '', '')
        continue
      elseif l:line =~ '^"\s*Recognised Paths:$'
        let l:state = 'expect_paths'
        let l:paths_prefix = substitute(l:line, '"\s*\zs.*', '', '')
        continue
      endif
    endif

    if l:state == 'expect_paths'
      " TODO: PC005: collect matching paths into a list
    endif

    if l:line !~ '^"\s*'
      " stop processing lines early
      break
    endif
  endfor

  if l:description is v:null
    throw printf('ERROR: expect %s to begin with ''" <DESCRIPTION>''', a:configloc.initpath)
  endif

  return <SID>createConfigInstance(a:configloc, l:description, l:projectid, l:paths)
endfun

fun! <SID>createConfigLocInstance(storename, slug, dirpath, initscript)
  let l:instance = {}

  let l:instance.storename = a:storename
  let l:instance.slug = a:slug
  let l:instance.dirpath = a:dirpath
  let l:instance.initpath = a:dirpath . '/' . a:initscript
  let l:instance.initscript = a:initscript

  return l:instance
endfun

fun! <SID>createConfigInstance(configloc, description, projectid, paths)
  let l:instance = {}

  let l:instance.project_id = a:projectid
  let l:instance.paths = a:paths
  let l:instance.description = a:description
  let l:instance.configloc = a:configloc

  return l:instance
endfun
