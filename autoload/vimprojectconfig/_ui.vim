fun! vimprojectconfig#_ui#createConfigOrLinkProject(projectid, projectroot)
  " Show UI to either create a config or link to an existing one.
  " Returns a cfg object or v:null when aborted.

  " 1. Choose between A) creating a new config or B) linking to an existing
  " config
  let l:choice = <SID>choose(["Create a new config", "Link to an existing config"])
  if l:choice == 1
    return <SID>createEmptyProjectConfig(a:projectid, a:projectroot)
  elseif l:choice == 2
    " TODO: PC023: implement linking to an existing config
    throw printf('NOT IMPLEMENTED (PC023): link project %s in %s to an existing config', a:projectid, a:projectroot)
  endif
endfun

fun! vimprojectconfig#_ui#openConfigFile(cfg)
  let l:initpath = a:cfg.configloc.initpath

  " TODO: PC024 allow configuring the type of split used
  exe 'split' l:initpath

  " set up an autocmd for the buffer that will reload config for all buffers
  " related to the project
  let l:configlocexpr = a:cfg.configloc.serialize()
  exe printf('au! VimProjectConfig BufWritePost <buffer> nested call vimprojectconfig#_engine#configWasUpdated(%s)', l:configlocexpr)
endfun

fun! <SID>createEmptyProjectConfig(projectid, projectroot)
  " Create a new empty config and return the cfg object

  " which store do you want to put it in?
  " TODO: PC022: allow the user to choose which one if there are multiple
  let l:storename = 'Personal'

  " Go through UI to create a new config.
  " Returns a str configpath or v:null when aborted.
  let l:basename = fnamemodify(a:projectroot, ':t')

  let l:description = <SID>prompt('Enter a descriptive title for the project', l:basename, 5)
  if l:description is v:null
    " aborted
    return v:null
  endif

  let l:slug = vimprojectconfig#_utils#slugify(l:description)

  return vimprojectconfig#_configs#createEmptyCfg(a:projectid, a:projectroot, l:description, l:slug, l:storename)
endfun

fun! <SID>prompt(label, default, minlength)
  while v:true
    " keep going until aborted or valid input
    let l:value = input({'prompt': a:label, 'default': a:default})
    if l:value == ''
      " aborted
      return v:null
    elseif len(l:value) >= a:minlength
      return l:value
    endif

    echohl WarningMsg
    echo printf('Answer must be at least %s characters', a:minlength)
    echohl None
  endwhile
endfun

fun! <SID>choose(choices)
  let l:choices = []
  for l:label in a:choices
    call add(l:choices, printf('%s) %s', len(l:choices) + 1, l:label))
  endfor

  while v:true
    " keep going until aborted or valid choice
    let l:choice = inputlist(l:choices)

    if l:choice >= 0 && l:choice <= len(a:choices)
      return l:choice
    endif
  endwhile
endfun
