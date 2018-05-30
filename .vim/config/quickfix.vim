" Sugar around the Quickfix and Location List buffers
let g:qf_min_height = 1
let g:qf_max_height = 8

function! GetPositionInList(list)
  let bufnum = bufnr('%')
  let lineno = line('.')
  let i = 1
  for item in a:list
    if bufnum == item.bufnr && lineno == item.lnum
      return i
    endif
    let i += 1
  endfor
  return 0
endfunction
function! QFToggle(cmd)
  let l:wincount = winnr('$')
  let l:winnr = winnr()
  if a:cmd == "l"
    let list = getloclist(0)
  else
    let list = getqflist()
  endif
  let height = min([max([len(list), g:qf_min_height]), g:qf_max_height])
  let pos = GetPositionInList(list)
  let opencmd = a:cmd . "open " . height
  " Always open QF as a full-width window aligned to bottom
  if a:cmd == "c"
    let opencmd = "botright " . opencmd
  endif
  exec opencmd
  if pos > 0
    exec a:cmd . a:cmd . " " . pos
  endif
  " If we have changed windows, change back
  " (so we stay in the same window we were in when we toggled open QF)
  if l:winnr !=# winnr()
    wincmd p
  endif
  " If the number of open windows hasn't changed, QF was already open. Close it.
  if winnr('$') == l:wincount
    exec a:cmd . "close"
  endif
endfunction

" Close quickfix if it's the only visible buffer
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" Intelligently go to next location or quickfix
function! NextResult()
  if empty(getloclist(0))
    silent! cnext
  else
    silent! lnext
  endif
  exec "normal! zvzz"
endfunction
function! PrevResult()
  if empty(getloclist(0))
    silent! cprev
  else
    silent! lprev
  endif
  exec "normal! zvzz"
endfunction

nnoremap <leader>q :call QFToggle('c')<CR>
nnoremap <leader>l :call QFToggle('l')<CR>
nnoremap <silent> <C-N> :call NextResult()<CR>
nnoremap <silent> <C-P> :call PrevResult()<CR>
