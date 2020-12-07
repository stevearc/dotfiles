" Window size settings
set winwidth=88 " minimum width of current window (includes gutter)
set winheight=20 " minimal height of current window
set splitbelow
set splitright

let g:wequality = 1
function! ResizeWindows()
    if g:wequality == 1
        wincmd =
    endif
endfunction
function! ToggleWinEqual()
    if g:wequality == 0
        let g:wequality = 1
    else
        let g:wequality = 0
    endif
endfunction
augroup WinWidth
    au!
    " Keep window sizes roughly equal
    au VimEnter,WinEnter,BufWinEnter * :call ResizeWindows()
    " Set the winwidth based on the textwidth
    au BufEnter * let &winwidth=&tw+8
augroup END
nmap <C-w>+ :call ToggleWinEqual()<CR>
nmap <C-w>z :resize<CR>:vertical resize<CR>
