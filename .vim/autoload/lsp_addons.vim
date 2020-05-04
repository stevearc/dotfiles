function! lsp_addons#StatusLine() abort
    try
        let l:diagnosticsDict = LanguageClient#statusLineDiagnosticsCounts()
    catch
        return ''
    endtry
    let l:errors = get(l:diagnosticsDict,'E',0)
    let l:warnings = get(l:diagnosticsDict,'W',0)
    if l:errors + l:warnings == 0
        return "✔"
    endif
    let l:line = ''
    if l:errors > 0
        let l:line = l:line . "E:" . l:errors
    endif
    if l:warnings > 0
        if l:errors > 0
            let l:line = l:line . ' '
        endif
        let l:line = l:line . "W:" . l:warnings
    endif
    return l:line
endfunction
