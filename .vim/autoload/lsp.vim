function! lsp#StatusLine() abort
    let l:diagnosticsDict = LanguageClient#statusLineDiagnosticsCounts()
    let l:errors = get(l:diagnosticsDict,'E',0)
    let l:warnings = get(l:diagnosticsDict,'W',0)
    return l:errors + l:warnings == 0 ? "✔" : "E:" . l:errors . " " . "W :" . l:warnings
endfunction
