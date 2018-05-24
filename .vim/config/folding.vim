" Smart folding
aug SmartFold
    au!
    au BufEnter * if !exists('b:all_folded') | let b:all_folded = 1 | endif
aug END
function! ToggleFold()
    if( b:all_folded == 0 )
        exec "normal! zM"
        let b:all_folded = 1
    else
        exec "normal! zR"
        let b:all_folded = 0
    endif
endfunction
nmap <leader>z :call ToggleFold()<CR>
