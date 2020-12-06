let s:ready = v:false
let s:interval = 5
let s:timer = localtime() - s:interval

function! statusline#StatusLine() abort
    let l:ts = nvim_treesitter#statusline(60)
    if l:ts == v:null
        let l:ts = ''
    elseif g:debug_treesitter
        let l:ts .= ' ' . luaeval("tostring(require'nvim-treesitter.ts_utils'.get_node_at_cursor(0))")
    endif
    if luaeval('#vim.lsp.buf_get_clients() == 0')
        return '%f %h%w%m%r ' . l:ts . '%=%(%l,%c%V %= %P%)'
    endif

    let l:sl = ''

    if !s:ready && (localtime() - s:timer) > s:interval
        let s:ready = luaeval('vim.lsp.buf.server_ready()')
        let s:timer = localtime()
    endif

    if s:ready
        try
            let l:errors = luaeval("vim.lsp.diagnostic.get_count(0, [[Error]])")
            let l:warnings = luaeval("vim.lsp.diagnostic.get_count(0, [[Warning]])")
            let l:sl .= s:getStatus(l:errors, l:warnings)
            let l:coverage = luaeval("require'flow'.get_coverage_percent()")
            if l:coverage != v:null && l:coverage != 100
                let l:sl .= ' [' . l:coverage . '%%]'
            endif
        catch
            let s:ready = v:false
        endtry
    else
        let l:sl .= '[LSP off]'
    endif
    return '%f %h%w%m%r ' . l:sl . ' ' . l:ts . ' %=%(%l,%c%V %= %P%)'
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
