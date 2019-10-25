let g:qf_min_height = get(g:, 'qf_min_height', 1)
let g:qf_max_height = get(g:, 'qf_max_height', 10)
let g:qf_update_position_delay = get(g:, 'qf_update_position_delay', 100)
let g:qf_autoclose = get(g:, 'qf_autoclose', 1)
let g:qf_prefer_loclist = get(g:, 'qf_prefer_loclist', 1)
" Experimental, buggy features
let g:qf_update_position = get(g:, 'qf_update_position', 0)
let g:qf_smart_jump = get(g:, 'qf_smart_jump', 0)

" Auto-update your position in the quickfix window
if g:qf_update_position
  augroup QFUpdateListPosition
    autocmd!
    autocmd User ALELintPost call quickerfix#UpdateQFListPositionBuffered(5)
    autocmd CursorMoved * call quickerfix#UpdateQFListPositionBuffered(g:qf_update_position_delay)
  augroup end
endif

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
