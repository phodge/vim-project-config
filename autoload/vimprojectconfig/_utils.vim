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
