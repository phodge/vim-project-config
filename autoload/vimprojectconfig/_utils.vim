let s:root_dir_cache = {}
let s:project_id_cache = {}

fun! vimprojectconfig#_utils#getRootDir(bufnr, reportfail)
  " returns the project root for the nominated buffer, or v:null if it could
  " not be discovered

  " Note that this plugin doesn't do anything special in terms of symlinks
  " TODO: PC013 PC006: add unit tests for symlink behaviour

  " TODO: this should have unit tests

  if has_key(s:root_dir_cache, a:bufnr)
    return s:root_dir_cache[a:bufnr]
  endif

  let l:root_dir = <SID>getBufferRootDir(a:bufnr)

  if l:root_dir is v:false
    " TODO: PC038: I suspect this may prevent things working - it's not great
    " that we are trying to figure out the buffer project when the buffer
    " isn't yet sufficiently loaded
    if a:reportfail
      " ... ?
    endif
    return v:null
  endif

  " store in cache
  let s:root_dir_cache[a:bufnr] = l:root_dir

  if l:root_dir is v:null
    if a:reportfail
      " TODO: PC012 PC006: report a helpful error message when a:reportfail is
      " true and we have to return v:null because we couldn't determine a
      " project root for the current buffer
    endif
  endif

  return l:root_dir
endfun

fun! <SID>getBufferRootDir(bufnr)
  let l:fn = get(g:vimprojectconfig#usersettings, 'get_project_root', v:null)
  if l:fn is v:null
    " fall back to our internal handler
    return <SID>getGitProjectRoot(a:bufnr)
  endif

  " TODO: PC014: what if get_project_root isn't a callable?

  let l:result = call(l:fn, [a:bufnr])
  if l:result is v:null
    return v:null
  endif

  if type(l:result) != type('')
    " TODO: PC006: unit test this code path and ensure a nice error message
    throw 'ERROR: get_project_root handler did not return a string'
  endif

  " TODO: PC006: can we check whether we got a valid path back?
  " TODO: PC006: can we check whether the returned path is a parent of the
  " buffer's path?

  return l:result == '' ? v:null : l:result
endfun

fun! <SID>getGitProjectRoot(bufnr)
  " TODO: PC029: add unit tests for this
  let l:thebuf = bufname(a:bufnr)

  if l:thebuf == ""
    " doesn't work if run this before the buffer is properly initialised
    " TODO: PC038: add unit tests for this
    return v:false
  endif

  let l:fullpath = fnamemodify(l:thebuf, ':p')
  let l:last = ''
  while len(l:fullpath) > 3 && l:fullpath != l:last

    let l:try = l:fullpath . '/.git'
    if isdirectory(l:try) || filereadable(l:try)
      return l:fullpath
    endif

    let l:last = l:fullpath
    let l:fullpath = fnamemodify(l:fullpath, ':h')
  endwhile

  " did not work
  return v:null
endfun

if ! exists('g:vimprojectconfig#_utils#slug_min_length')
  " make sure this always exists
  let g:vimprojectconfig#_utils#slug_min_length = 4
endif

fun! vimprojectconfig#_utils#slugify(description)
  " TODO: make some unit tests for this
  let l:slug = substitute(a:description, '[^A-Za-z0-9_]\+', '-', 'g')
  let l:slug = tolower(trim(l:slug, '-'))
  if len(l:slug) < g:vimprojectconfig#_utils#slug_min_length
    throw printf('ERROR: could not generate a long enough slug from "%s"', a:description)
  endif

  return l:slug
endfun

fun! vimprojectconfig#_utils#getProjectId(projectroot)
  if has_key(s:project_id_cache, a:projectroot)
    return s:project_id_cache[a:projectroot]
  endif

  let l:dotgit = a:projectroot . '/.git'
  if isdirectory(l:dotgit) || filereadable(l:dotgit)
    let l:projectid = <SID>getGitProjectId(a:projectroot)
  else
    " TODO: PC001: add support for detecting ID of other types of projects
    let l:projectid = v:null
  endif

  let s:project_id_cache[a:projectroot] = l:projectid
  return l:projectid
endfun

fun! vimprojectconfig#_utils#getConfigStoreDir(storename)
  " Return the full path to the directory storing configs for the given
  " storename.
  " The directory will be created if it does not exist.
  let l:dir = vimprojectconfig#_settings#getValidProjectStoreDir(a:storename)

  " TODO: PC006: should we instead add try/catch around this to give a better
  " error when the folder can't be creatd?
  call mkdir(l:dir, 'p')

  if ! isdirectory(l:dir)
    " TODO: PC006: add E2E tests ensuring this error messages is always helpful/nice
    throw printf('ERROR: config dir %s is not a directory', l:dir)
  endif

  return l:dir
endfun

fun! <SID>getGitProjectId(reporoot)
  let l:cachekey = 'git-project-id-by-path|' . a:reporoot
  let l:cached = vimprojectconfig#_cache#get(l:cachekey, '__not_set__')
  if l:cached != '__not_set__'
    return l:cached
  endif

  " get the commit sha of the first commit in the repo - use that as the
  " project id
  " TODO: PC006: graceful error message when the git project has no commits
  " TODO: PC030: handle repos with multiple initial commits
  let l:checkcmd = ['git', '-C', a:reporoot, 'rev-list', '--max-parents=0', 'HEAD']
  let l:sha = trim(system(l:checkcmd))
  if v:shell_error
    throw 'GIT ERROR: ' . l:sha
  endif

  " TODO: PC006: graceful error message when the command did not return a sha string
  let l:projectid = len(l:sha) ? l:sha : v:null
  call vimprojectconfig#_cache#set(l:cachekey, l:projectid)
  return l:projectid
endfun
