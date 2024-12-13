## Example 1: Set a custom filetype for certain files in my project

Lets say that you want all `.jsx` files to be have their filetype set to
`javascript` instead of the default. You could create a project config hook
that looks like this:

    fun! projectconfig.api2024.filetypeDetect(bufnr, ext, basename, relname) dict
        " map by extension
        if a:ext == 'jsx'
            return 'javascript'
        endif

        " map by filename
        if a:basename == '.eslintrc'
            return 'eslintrc'
        endif

        " map using runtime logic
        if a:relname =~ '^bin/'
            if getbufline(a:bufnr, 1)[0] =~ 'bin/python'
                return 'python'
            endif
        endif
    endfun


<!-- TODO: PC017: review examples below and autocmds available and implement as many as needed



## Set an option for all buffers in my project

- it should not be clobbered by after/ vimruntime files
- proposed hook - projectconfig.BufEnter() - because the docs say useful for setting options for a file type
<!--
- NOTE: see TODO/PC043.txt where we need something that actually fires *before*
  the vimruntime files are loaded.
-->


## Set an option for a specific filetype in my project

- it should not be clobbered by ftplugin or after/ftplugin vimruntime files
- proposed hook - projectconfig.BufEnter.filetype() - because the docs say useful for setting options for a file type


## Set a buffer-local variable for a specific filetype in my project

- it should not be clobbered by other autocmds or vimruntime files (include after/ files)
- proposed hook - projectconfig.BufEnter.filetype() - because the docs say useful for setting options for a file type


## Turn TreeSitter ON or OFF for a specific filetype in my project

- needs to take precedence over global syntax/treesitter settings
- needs to not leak out into non-project files of the same FT
- proposed hook - projectconfig.BufEnter.filetype() - because the docs say useful for setting options for a file type


## Turn LSP ON or OFF for a specific filetype in myproject

- needs to take precedence over global LSP settings
- needs to not leak out into non-project files of the same FT
- proposed hook - projectconfig.BufEnter.filetype() - because the docs say useful for setting options for a file type


## XXX: these used to be in the README ...

... would they _actually_ be useful for anything though?

    fun! projectconfig.projectLoad(projectstate)
        " executed once when a buffer for the project is first opened. Store per-project state in
        " a:projectstate
    endfun

    fun! projectconfig.projectUnload(projectstate)
        " executed once when the last buffer for a project is unloaded.
    endfun

/TODO -->
