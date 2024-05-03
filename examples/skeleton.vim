" TODO: PC040: finish this skeleton file - add a placeholder for each example
" in docs/examples.md
fun! projectconfig.api2024.filetypeDetect(bufnr, ext, basename, relname) dict
    if 0 && a:ext == 'txt'
        return 'markdown'
    endif
endfun
