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
        call add(l:return, vimprojectconfig#_configs#createConfigLocInstance(l:storename, l:entry, l:configdir, l:initscript))
      endif
    endfor
  endfor

  return l:return
endfun

fun! vimprojectconfig#_configs#getCfgForBuffer(bufnr, reportfail)
  " Returns a list of [cfg, projectroot, projectid] for the given buffer
  " Any of cfg, projectroot or projetid may be v:null

  " 1. Determine the project root dir for the buffer
  let l:projectroot = vimprojectconfig#_utils#getRootDir(a:bufnr, a:reportfail)

  if l:projectroot is v:null
    " abort - we could not learn the buffer's projectroot so can't continue
    return [v:null, v:null, v:null]
  endif

  " 2. [Maybe] Determine the ID of the project
  let l:projectid = vimprojectconfig#_utils#getProjectId(l:projectroot)

  if l:projectid isnot v:null
    " If the project has an id and there is a config that matches that ID, use
    " it
    let l:cfg = vimprojectconfig#_configs#getCfgFromProjectId(l:projectid)

    if l:cfg isnot v:null
      return [l:cfg, l:projectid, l:projectroot]
    endif
  endif

  " 3. [Fallback] map a raw path to an existing project
  let l:cfg = vimprojectconfig#_configs#getCfgFromProjectRootPath(l:projectroot)
  return [l:cfg, l:projectid, l:projectroot]
endfun

fun! vimprojectconfig#_configs#getCfgFromProjectId(projectid)
  " Returns the cfg for the nominated project id or v:null if it does not exist

  " TODO: add unit tests for this util

  " TODO: PC009: add some caching to speed this up
  for l:configloc in <SID>getAllConfigs()
    let l:cfg = <SID>readExistingCfg(l:configloc)
    if l:cfg.project_id == a:projectid
      return l:cfg
    endif
  endfor

  return v:null
endfun

fun! vimprojectconfig#_configs#getCfgFromProjectRootPath(projectroot)
  " Returns the config path for the nominated project or v:null if it does not
  " exist
  " TODO: PC003: find configs that match based on path
  return v:null
endfun

fun! vimprojectconfig#_configs#createEmptyCfg(projectid, projectroot, description, slug, storename)
  " Create an empty config with the given parameters, return a cfg object

  " TODO: PC004: initscript may be 'project.lua'
  let l:initscript = 'project.vim'
  let l:configloc = vimprojectconfig#_configs#createConfigLocInstance(
        \ a:storename,
        \ a:slug,
        \ vimprojectconfig#_utils#getConfigStoreDir(a:storename) . '/' . a:slug,
        \ l:initscript,
        \ )

  " create the folder
  call mkdir(l:configloc.dirpath, 'p')

  " store the project's description at the top of the file
  let l:header = ['" Project: ' . a:description]

  if a:projectid isnot v:null
    if type(a:projectid) != type('')
      throw 'ERROR: invalid a:project_id'
    endif
    call add(l:header, '" ProjectID: ' . a:projectid)
    call add(l:header, '')
    let l:paths = []
  else
    call add(l:header, '" Recognised Paths:')
    call add(l:header, '" - ' . a:projectroot)
    call add(l:header, '')
    let l:paths = [a:projectroot]
  endif

  " TODO: PC010: provide a better file template and document the possible
  " methods in README.md
  call add(l:header, '')
  call add(l:header, '" TODO: place your project init commands here')

  " TODO: PC011: PC006: bail out if the project.vim file already exists and has a different
  " description or project id

  call writefile(l:header, l:configloc.initpath)

  return <SID>createConfigInstance(l:configloc, a:description, a:projectid, l:paths)
endfun

fun! vimprojectconfig#_configs#getBufferNumbersAssociatedWithConfig(configloc)
  let l:cfg = <SID>readExistingCfg(a:configloc)
  if l:cfg.project_id isnot v:null
    return <SID>getBuffersByProjectId(l:cfg.project_id)
  endif

  return <SID>getBufferNumbersByProjectPaths(l:cfg.paths)
endfun

fun! <SID>getBufferNumbersByProjectPaths(projectpaths)
  " TODO: PC003: implement this
  let l:buffers = []
  for l:bufnr in range(1, bufnr('$'))
  endfor
  return l:buffers
endfun

fun! <SID>getBuffersByProjectId(projectid)
  " TODO: PC020: ensure this is all optimized/performant
  let l:buffers = []
  for l:bufnr in range(1, bufnr('$'))
    if ! bufexists(l:bufnr)
      continue
    endif

    let l:buf_projectroot = vimprojectconfig#_utils#getRootDir(l:bufnr, v:false)
    if l:buf_projectroot is v:null
      " skip buffers where we can't determine the project root
      continue
    endif
    let l:buf_projectid = vimprojectconfig#_utils#getProjectId(l:buf_projectroot)
    if l:buf_projectid isnot v:null && l:buf_projectid == a:projectid
      call add(l:buffers, l:bufnr)
    endif
  endfor
  return l:buffers
endfun

fun! <SID>readExistingCfg(configloc)
  let l:description = v:null
  let l:projectid = v:null
  let l:paths = []

  let l:head = readfile(a:configloc.initpath, '', 50)
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
        let l:projectid = substitute(l:line, '^"\s*ProjectID:\s*', '', '')
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

fun! vimprojectconfig#_configs#createConfigLocInstance(storename, slug, dirpath, initscript)
  let l:instance = {}

  let l:instance.storename = a:storename
  let l:instance.slug = a:slug
  let l:instance.dirpath = a:dirpath
  let l:instance.initpath = a:dirpath . '/' . a:initscript
  let l:instance.initscript = a:initscript
  let l:instance.cfgkey = a:dirpath
  let l:instance.serialize = function("<SID>configLocSerialize")
  let l:instance._serialized = v:null

  return l:instance
endfun

fun! <SID>configLocSerialize() dict
  if self._serialized is v:null
    let self._serialized = printf(
          \ 'vimprojectconfig#_configs#createConfigLocInstance(%s, %s, %s, %s)',
          \ <SID>safeStr(self.storename),
          \ <SID>safeStr(self.slug),
          \ <SID>safeStr(self.dirpath),
          \ <SID>safeStr(self.initscript),
          \ )
  endif
  return self._serialized
endfun

fun! <SID>safeStr(val)
  return "'" . substitute(a:val, "'", "''", 'g') . "'"
endfun

fun! <SID>createConfigInstance(configloc, description, projectid, paths)
  let l:instance = {}

  let l:instance.project_id = a:projectid
  let l:instance.paths = a:paths
  let l:instance.description = a:description
  let l:instance.configloc = a:configloc

  return l:instance
endfun
