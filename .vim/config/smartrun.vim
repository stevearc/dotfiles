" Execute current file
" TODO: break this into autoload & ftplugins
function! SmartRun()
    :w
    :silent !clear
    if match(expand("%"), '.py$') != -1
        exec ":!python " . @%
    elseif match(expand("%"), '.sh$') != -1
        exec ":!bash " . @%
    elseif match(expand("%"), '.rb$') != -1
        exec ":!ruby " . @%
    elseif match(expand("%"), '.go$') != -1
        GoRun
    elseif match(expand("%"), '.coffee$') != -1
        exec ":!coffee " . @%
    elseif match(expand("%"), '.js$') != -1
        exec ":!node " . @%
    elseif match(expand("%"), '.clj$') != -1
        exec ":%Eval"
        exec ":redraw!"
    else
        :redraw!
        :echo "Unknown file type"
    end
endfunction

nnoremap <leader>e :call SmartRun()<cr>
