" Smart folding

" Don't nest folds
se foldnestmax=1
" Start with folds open
se foldlevelstart=99
" Disable fold column
se foldcolumn=0
" Only create a fold for >5 lines
se foldminlines=5

" aug SmartFold
"     au!
"     au BufEnter * if !exists('b:all_folded') | let b:all_folded = 0 | endif
"     " This option is window-local
"     au WinEnter * se foldnestmax=1
" aug END
" function! ToggleFold()
"     if( b:all_folded == 0 )
"         normal! zM
"         let b:all_folded = 1
"     else
"         normal! zR
"         let b:all_folded = 0
"     endif
" endfunction
" nmap <leader>z :call ToggleFold()<CR>
