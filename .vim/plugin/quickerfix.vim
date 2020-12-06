let g:qf_min_height = get(g:, 'qf_min_height', 1)
let g:qf_max_height = get(g:, 'qf_max_height', 10)
let g:qf_autoclose = get(g:, 'qf_autoclose', 1)
let g:qf_prefer_loclist = get(g:, 'qf_prefer_loclist', 1)

" Close quickfix if it's the only visible buffer
if g:qf_autoclose
  augroup QFCloseIfLast
    autocmd!
    autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
  augroup END
endif

command! -bar QuickFixAutoNext call quickerfix#NextResult()
command! -bar QuickFixAutoPrev call quickerfix#PrevResult()
command! -bar QuickFixNext call quickerfix#NextResult('c')
command! -bar QuickFixPrev call quickerfix#PrevResult('c')
command! -bar LocListNext call quickerfix#NextResult('l')
command! -bar LocListPrev call quickerfix#PrevResult('l')
command! -bar -count QuickFixToggle call quickerfix#QFToggle('c', <count>)
command! -bar -count LocListToggle call quickerfix#QFToggle('l', <count>)
command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])

nnoremap <silent> <C-N> :QuickFixAutoNext<CR>
nnoremap <silent> <C-P> :QuickFixAutoPrev<CR>
nnoremap <leader>q :QuickFixToggle<CR>
nnoremap <leader>l :LocListToggle<CR>
