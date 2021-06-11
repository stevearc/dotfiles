" Window size settings
set winwidth=88 " minimum width of current window (includes gutter)
set winheight=20 " minimal height of current window
set splitbelow
set splitright

let g:wequality = 1
function! s:ResizeWindows() abort
  if g:wequality == 1 && !&winfixwidth && !&winfixheight
    wincmd =
  endif
endfunction
function! s:ToggleWinEqual() abort
  let g:wequality = !g:wequality
endfunction
function! s:SetSize() abort
  if &winfixwidth
    let &winwidth=winwidth(0)
  else
    " Set the winwidth based on the textwidth
    let &winwidth=&tw+8
  endif
  if &winfixheight
    let &winheight=winheight(0)
  else
    let &winheight=20
  endif
endfunction
augroup WinWidth
  au!
  " Keep window sizes roughly equal
  au VimEnter,WinEnter,BufWinEnter * :call <sid>ResizeWindows()
  au BufEnter * :call <sid>SetSize()
augroup END
nmap <C-w>+ :call <sid>ToggleWinEqual()<CR>
nmap <C-w>z :resize<CR>:vertical resize<CR>
