# Filetype Detection

## Background

### Neovim

Neovim's new `vim.filetype.add()` API supports 3 ways of matching files:

1. Mapping a file extension to a string filetype
2. Mapping a filename (either the basename or full path) to a string filetype
3. Mapping a glob pattern eo either a fix string filetype, or a callable which
   can *optionally* return a filetype (allowing for cascading through multiple
   filetype-detection callbacks). Pattern-based filetypes also support an
   optional "priority" integer which allows you to manage precedence amongst
   your own filetype rules and Neovim's bundled patterns.

Unfortunately the extension- and filename- based mapping tables don't support
callbacks, so there is no way to attach onto these to activate project-specific
filetypes.

This means the only real option is to use a pattern-based override for this
plugin (probably one pattern per project path) which dispatches to a user-defined
callback to optionally determine filetype based on custom logic.


### Vim

The state of Vim appears to be this:

`$VIMRUNTIME/filetype.vim` contains a truckload of autocommands for detecting
filetypes. They all use `:setfiletype` so that the earliest-defined one "wins"
and subsequent autocmds in this file become a no-op if they also match the same
file.

The help docs says that to do your own filetype detection, create your own
ftdetect/anything.vim and create one or more `BufRead,BufNewFile` autocommands
that can go one of two ways:

1. Use `:setfiletype blah` and don't overwrite a filetype already set by vim.
2. Use `:set filetype=blah` and it _will_ overwrite a filetype already set by
   vim.

BUT beware that whichever way you go, if a vim builtin autocmd has already set
a filetype via `:setfiletype ...` then the ftplugins scripts for that filetype
will already have been loaded and set various options and who-knows-what-else
that might be inappropriate for the actual filetype you wanted to use.

Now some bright spark has come up with the clever idea of a `b:undo_ftplugin`
variable which the ftplugin script author must (should?) carefully maintain in
line with the rest of the script as an eval-able string of vimscript to reset
all buffer-local options to their default values if the buffer filetype needs
to change to something else, so there _is_ a mechanism to try and prevent
multiple loaded filetypes conflicting with each other. However, this mechanism
appears to be completely undocumented and it's not unreasonable that you have
your own ftplugin/ files that set various options that _aren't_ included in
`b:undo_ftplugin` and thus won't be reset if the buffer filetype changes. Also,
given that ftplugin scripts are layered (there can be many loaded from
runtimepath) but there is only one `b:undo_ftplugin` variable per buffer, how
are 3rd-party plugin authors supposed to manage it?

All this is to say, that even if you add a filetype override as per the vim
docs, it's possible that two filetypes will be loaded in succession, and there
may be some cruft left over from the filetype that was loaded first.

No wonder the Neovim guys came up with a new mechanism.
