" Sugar around the Quickfix and Location List buffers
let g:qf_min_height = 1
let g:qf_max_height = 8

" Quickly toggle the quickfix window
" from http://vim.wikia.com/wiki/Toggle_to_open_or_close_the_quickfix_window
function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction
function! IsBufferOpen(name)
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ a:name'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      return 1
    endif
  endfor
  return 0
endfunction
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
function! QFToggle(cmd, bufpattern)
  if IsBufferOpen(a:bufpattern)
    exec a:cmd . "close"
  else
    let l:winnr = winnr()
    if a:cmd == "l"
      let list = getloclist(0)
    else
      let list = getqflist()
    endif
    let height = min([max([len(list), g:qf_min_height]), g:qf_max_height])
    let pos = GetPositionInList(list)
    exec a:cmd . "open " . height
    if pos > 0
      exec a:cmd . a:cmd . " " . pos
    endif
    if l:winnr !=# winnr()
      wincmd p
    endif
  endif
endfunction

" Close quickfix if it's the only visible buffer
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" Intelligently go to next location or quickfix
function! NextResult()
  if IsBufferOpen("Location List")
    silent! lnext
  else
    silent! cnext
  endif
  exec "normal! zvzz"
endfunction
function! PrevResult()
  if IsBufferOpen("Location List")
    silent! lprev
  else
    silent! cprev
  endif
  exec "normal! zvzz"
endfunction

nnoremap <leader>q :call QFToggle('c', 'Quickfix List')<CR>
nnoremap <leader>l :call QFToggle('l', 'Location List')<CR>
nnoremap <silent> <C-N> :call NextResult()<CR>
nnoremap <silent> <C-P> :call PrevResult()<CR>
