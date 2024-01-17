fun! vimprojectconfig#_utils#getRootDir(bufnr)
  " returns the project root for the nominated buffer, or v:null if it could
  " not be discovered
  " TODO: this should have unit tests

  let l:fn = get(g:vimprojectconfig#usersettings, 'get_project_root', v:null)
  if l:fn is v:null
    " fall back to our internal handler
    return <SID>getGitProjectRoot(a:bufnr)
  endif

  let l:result = call(l:fn, [a:bufnr])
  if l:result is v:null
    return v:null
  endif

  if type(l:result) != type('')
    " TODO: PC006: unit test this code path and ensure a nice error message
    throw 'ERROR: get_project_root handler did not return a string'
  endif

  return l:result == '' ? v:null : l:result
endfun

fun! <SID>getGitProjectRoot(bufnr)
  " TODO: this should have unit tests
  let l:fullpath = expand(bufname(a:bufnr), ':p')
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
  let l:dotgit = a:projectroot . '/.git'
  if isdirectory(l:dotgit) || filereadable(l:dotgit)
    return <SID>getGitProjectId(a:projectroot)
  endif

  " TODO: PC001: add support for detecting ID of other types of projects
  return v:null
endfun

fun! vimprojectconfig#_utils#getConfigStoreDir(storename)
  " Return the full path to the directory storing configs for the given
  " storename.
  " The directory will be created if it does not exist.
  let l:dir = vimprojectconfig#_settings#getValidProjectStoreDir(a:storename)

  call mkdir(l:dir, 'p')

  if ! isdirectory(l:dir)
    throw printf('ERROR: config dir %s is not a directory', l:dir)
  endif

  return l:dir
endfun

fun! <SID>getGitProjectId(reporoot)
  " get the commit sha of the first commit in the repo - use that as the
  " project id
  " TODO: PC006: graceful error message when the git project has no commits
  let l:sha = trim(system(['git', '-C', a:reporoot, 'log', '--reverse', '-1', '--format=%H']))
  if v:shell_error
    throw 'GIT ERROR: ' . l:sha
  endif

  " TODO: PC006: graceful error message when the command did not return a sha string
  return len(l:sha) ? l:sha : v:null
endfun
