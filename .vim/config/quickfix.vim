" Sugar around the Quickfix and Location List buffers
let g:qf_min_height = 1
let g:qf_max_height = 8

" Close quickfix if it's the only visible buffer
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

nnoremap <leader>q :call quickfix#QFToggle('c')<CR>
nnoremap <leader>l :call quickfix#QFToggle('l')<CR>
nnoremap <silent> <C-N> :call quickfix#NextResult()<CR>
nnoremap <silent> <C-P> :call quickfix#PrevResult()<CR>
