let s:ready = v:false
let s:interval = 5
let s:timer = localtime() - s:interval

function! lsp_addons#StatusLine() abort
    if luaeval('vim.lsp == null')
        try
            let l:diagnosticsDict = LanguageClient#statusLineDiagnosticsCounts()
        catch
            return ''
        endtry
        let l:errors = get(l:diagnosticsDict,'E',0)
        let l:warnings = get(l:diagnosticsDict,'W',0)
        return s:getStatus(l:errors, l:warnings)
    else
        let sl = ''

        if !s:ready && (localtime() - s:timer) > s:interval
            let s:ready = luaeval('vim.lsp.buf.server_ready()')
            let s:timer = localtime()
        endif

        if s:ready
            try
                let l:errors = luaeval("vim.lsp.util.buf_diagnostics_count(\"Error\")")
                let l:warnings = luaeval("vim.lsp.util.buf_diagnostics_count(\"Warning\")")
                let sl .= s:getStatus(l:errors, l:warnings)
            catch
                let s:ready = v:false
            endtry
        else
            let sl .= '[LSP off]'
        endif
        return sl
    endif
endfunction

function! s:getStatus(errors, warnings) abort
    if a:errors + a:warnings == 0
        return "✔"
    endif
    let l:line = ''
    if a:errors != v:null && a:errors > 0
        let l:line = l:line . "E:" . a:errors
    endif
    if a:warnings != v:null && a:warnings > 0
        if a:errors != v:null && a:errors > 0
            let l:line = l:line . ' '
        endif
        let l:line = l:line . "W:" . a:warnings
    endif
    return l:line
endfunction
