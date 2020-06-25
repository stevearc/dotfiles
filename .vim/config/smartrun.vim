" Execute current file
" TODO: break this into autoload & ftplugins
function! SmartRun()
    :w
    :silent !clear
    if match(expand("%"), '.py$') != -1
        exec ":botright split | terminal python " . @%
    elseif match(expand("%"), '.sh$') != -1
        exec ":botright split | terminal bash " . @%
    elseif match(expand("%"), '.rb$') != -1
        exec ":botright split | terminal ruby " . @%
    elseif match(expand("%"), '.go$') != -1
        GoRun
    elseif match(expand("%"), '.coffee$') != -1
        exec ":botright split | terminal coffee " . @%
    elseif match(expand("%"), '.js$') != -1
        exec ":botright split | terminal node " . @%
    elseif match(expand("%"), '.clj$') != -1
        exec ":%Eval"
        exec ":redraw!"
    else
        :redraw!
        :echo "Unknown file type"
    end
endfunction

nnoremap <leader>e :call SmartRun()<cr>
