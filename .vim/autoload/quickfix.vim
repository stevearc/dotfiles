function! quickfix#QFToggle(cmd)
  let l:wincount = winnr('$')
  let l:winnr = winnr()
  if a:cmd == "l"
    let list = getloclist(0)
  else
    let list = getqflist()
  endif
  let height = min([max([len(list), g:qf_min_height]), g:qf_max_height])
  let pos = s:GetPositionInList(list)
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

function! s:IsLocListOpen() abort
  return !empty(filter(getwininfo(), 'v:val.quickfix && v:val.loclist'))
endfunction

function! s:NavCommand(cmd) abort
  if empty(getloclist(0))
    exec 'silent! c' . a:cmd
    silent! cc
  elseif empty(getqflist())
    exec 'silent! l' . a:cmd
    silent! ll
  elseif s:IsLocListOpen()
    silent! lnext
    exec 'silent! l' . a:cmd
    silent! ll
  else
    exec 'silent! c' . a:cmd
    silent! cc
  endif
  normal! zvzz
endfunction

" Intelligently go to next location or quickfix
function! quickfix#NextResult()
  call s:NavCommand('next')
endfunction

function! quickfix#PrevResult()
  call s:NavCommand('prev')
endfunction

function! s:GetPositionInList(list)
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
