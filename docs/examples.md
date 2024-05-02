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

