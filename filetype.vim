if has('nvim')
  lua vim.filetype.add({pattern={[".*"]=function(path, bufnr, ext) vim.api.nvim_call_function('vimprojectconfig#_engine#dispatch', {'internal_filetype_override'}) end}})
else
  " TODO: PC039: add unit tests for this hook
  aug VimProjectConfig | aug end
  au! VimProjectConfig BufRead,BufNewFile * call vimprojectconfig#_engine#dispatch('internal_filetype_override')
endif
