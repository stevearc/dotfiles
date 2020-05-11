" Smart folding

" Don't nest folds
se foldnestmax=1
" Close folds when cursor leaves
se foldclose=all
" Start with folds open
se foldlevelstart=99

aug SmartFold
    au!
    au BufEnter * if !exists('b:all_folded') | let b:all_folded = 0 | endif
aug END
function! ToggleFold()
    if( b:all_folded == 0 )
        normal! zM
        let b:all_folded = 1
    else
        normal! zR
        let b:all_folded = 0
    endif
endfunction
nmap <leader>z :call ToggleFold()<CR>
