let s:diskcache = v:null

" TODO: PC035: a more deliberate default cache path
" TODO: PC035: allow customising the cache path
if ! exists('g:vimprojectconfig#_cache#path')
  let g:vimprojectconfig#_cache#path = expand('~/.nvim/vimprojectconfig.cache.vim')
endif

fun! <SID>ReadCache()
  let g:vimprojectconfig#_cache#data = v:null
  let l:return = {}
  try
    exe 'source' g:vimprojectconfig#_cache#path
    let l:return = g:vimprojectconfig#_cache#data
  catch /^E484/
    " ignore this
    return {}
  catch
    " TODO: PC035: unlink the cache file so it doesn't happen again
  finally
    unlet! g:vimprojectconfig#_cache#data
  endtry
  return l:return
endfun

fun! vimprojectconfig#_cache#get(key, default)
  if s:diskcache is v:null
    let s:diskcache = <SID>ReadCache()
  endif

  return get(s:diskcache, a:key, a:default)
endfun

fun! vimprojectconfig#_cache#set(key, value)
  " TODO: PC035: how to make a cache mechanism that is resilient against
  " multiple Neovim instances reading/writing it at the same time?

  " force re-read in cache of failure
  let s:diskcache = v:null

  " load existing values
  let l:current = <SID>ReadCache()

  " insert the new value
  let l:current[a:key] = a:value

  call <SID>WriteCache(l:current)
endfun

fun! vimprojectconfig#_cache#delete(key)
  " TODO: PC035: how to make a cache mechanism that is resilient against
  " multiple Neovim instances reading/writing it at the same time?

  " force re-read in cache of failure
  let s:diskcache = v:null

  " load existing values
  let l:current = <SID>ReadCache()

  " insert the new value
  call remove(l:current, a:key)

  call <SID>WriteCache(l:current)
endfun

fun! <SID>WriteCache(data)
  let l:lines = ['let g:vimprojectconfig#_cache#data = {']
  for [l:key, l:value] in items(a:data)
    call add(l:lines, printf('  \ %s: %s,', string(l:key), string(l:value)))
  endfor
  call add(l:lines, '  \ }')

  " write out the cache file
  call writefile(l:lines, g:vimprojectconfig#_cache#path)

  " make sure internal representation is updated
  let s:diskcache = a:data
endfun
