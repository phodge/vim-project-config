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
