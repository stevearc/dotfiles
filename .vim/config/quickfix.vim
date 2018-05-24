" Sugar around the Quickfix and Location List buffers

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
function! QuickfixToggle()
  if IsBufferOpen("Quickfix List")
    cclose
  else
    copen
  endif
endfunction
function! LocationListToggle()
  if IsBufferOpen("Location List")
    lclose
  else
    lopen
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
    lnext
  else
    cnext
  endif
  exec "normal! zv"
endfunction
function! PrevResult()
  if IsBufferOpen("Location List")
    lprev
  else
    cprev
  endif
  exec "normal! zv"
endfunction

nnoremap <leader>q :call QuickfixToggle()<CR>
nnoremap <leader>l :call LocationListToggle()<CR>
nnoremap <silent> <C-N> :call NextResult()<CR>
nnoremap <silent> <C-P> :call PrevResult()<CR>
