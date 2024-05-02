let s:config_state = get(s:, 'config_state', {})

fun! vimprojectconfig#_engine#dispatch(eventname)
  let l:cfg = vimprojectconfig#_configs#getCfgForBuffer(bufnr(), v:false)[0]

  if l:cfg is v:null
    " bail out - there is no config that matches this buffer
    return
  endif

  " load the config if it isn't already loaded
  call <SID>loadOrReloadConfig(l:cfg)

  if a:eventname == 'BufEnter'
    let l:state = s:config_state[l:cfg.configloc.cfgkey]
    let l:Hook = get(l:state, a:eventname, v:null)
    if l:Hook isnot v:null
      " execute the hook already!
      " TODO: PC018: should we be calling with the main config_state or should
      " we have something else?
      " Also should this then be using s:config_state[l:cfg.configloc.cfgkey] as
      " the 3rd arg?
      call call(l:Hook, [], l:state.data)
    endif
    return
  endif

  throw printf('ERROR: unexpected hook "%s"', a:eventname)
endfun

fun! <SID>thisConfigNeedsReload(configloc)
  if has_key(s:config_state, a:configloc.cfgkey)
    let s:config_state[a:configloc.cfgkey].needs_reload = v:true
  endif
endfun

fun! vimprojectconfig#_engine#configWasUpdated(configloc)
  call <SID>thisConfigNeedsReload(a:configloc)

  let l:buffernumbers = {}
  for l:buf in vimprojectconfig#_configs#getBufferNumbersAssociatedWithConfig(a:configloc)
    let l:buffernumbers[l:buf] = v:true
  endfor

  if ! len(l:buffernumbers)
    return
  endif

  " Simple buffer reloading
  " Step 1: reload each buffer that has a window on the current tab page
  " Step 2: add autocmds for each other buffer to reload when it is entered
  " (:au BufWinEnter <buffer=N> nested ...)
  let l:oldwin = winnr()
  try
    for l:winnr in range(1, winnr('$'))
      let l:winbufnr = winbufnr(l:winnr)

      if ! has_key(l:buffernumbers, l:winbufnr)
        continue
      endif

      " move to the window
      exe 'wincmd' l:winnr 'w'

      try
        " refresh the config ... by calling the BufEnter hook again
        call vimprojectconfig#_engine#dispatch('BufEnter')
      finally
        " remove the buffer from the list of ones needing refresh
        unlet! l:buffernumbers[l:winbufnr]
      endtry
    endfor
  finally
    " restore old currently-selected window
    exe 'wincmd' l:oldwin 'w'
  endtry

  let l:reload_cmd = 'call vimprojectconfig#_engine#dispatch("BufEnter")'
  for l:bufnr in keys(l:buffernumbers)
    " TODO: PC015: add an E2E test to ensure this works
    exe printf('au! VimProjectConfigReloadTriggers WinEnter <buffer=%s> ++once nested %s', l:bufnr, l:reload_cmd)
  endfor
endfun

fun! <SID>loadOrReloadConfig(cfg)
  let l:cfgkey = a:cfg.configloc.cfgkey

  if has_key(s:config_state, l:cfgkey)
    if ! get(s:config_state[l:cfgkey], 'needs_reload', v:false)
      return
    endif

    " TODO: PC017: do we need to call a "project unload" handler here?
    call remove(s:config_state[l:cfgkey], 'needs_reload')
  endif

  " TODO: PC018: should we reset the state object each time?
  let l:state = {"data": {}}

  " copy by ref, so updating l:state will add things to the state for that
  " script
  let s:config_state[l:cfgkey] = l:state

  " set global 'projectconfig' variable
  try
    " TODO: PC018: should we be passing state object each time?
    let g:projectconfig = l:state
    exe 'source' a:cfg.configloc.initpath

    " TODO: PC017: work out what hooks/handlers we should be looking for
    " TODO: PC019: verify entries of g:projectconfig that we might expect to
    " exist
    " TODO: PC018: if we pass a separate object to the hooks (different self)
    " then we might need to pull things of g:projectconfig and store them
    " manually?
  finally
    unlet! g:projectconfig
  endtry
endfun
