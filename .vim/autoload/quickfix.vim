function! quickfix#QFToggle(cmd) abort
  let l:wincount = winnr('$')
  let l:winnr = winnr()
  let list = a:cmd == 'l' ? getloclist(0) : getqflist()
  let height = min([max([len(list), g:qf_min_height]), g:qf_max_height])
  let pos = s:GetPositionInList(list)
  let cur = getcurpos()
  let opencmd = a:cmd . "open " . height
  " Always open QF as a full-width window aligned to bottom
  if a:cmd == "c"
    let opencmd = "botright " . opencmd
  endif
  exec opencmd
  if pos != -1
    exec a:cmd . a:cmd . " " . (pos + 1)
    call setpos('.', cur)
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

function! s:IsQuickFixOpen() abort
  return !empty(filter(getwininfo(), 'v:val.quickfix && !v:val.loclist'))
endfunction

function! s:IsListOpen(type) abort
  return a:type == 'c' ? s:IsQuickFixOpen() : s:IsLocListOpen()
endfunction

function! s:GetActiveList() abort
  let loclist = getloclist(0)
  let qflist = getqflist()
  if empty(loclist)
    return {'type': 'c', 'list': qflist}
  elseif empty(qflist)
    return {'type': 'l', 'list': loclist}
  elseif s:IsQuickFixOpen()
    return {'type': 'c', 'list': qflist}
  else
    return {'type': 'l', 'list': loclist}
  endif
endfunction

function! s:NavCommand(cmd) abort
  let qf = s:GetActiveList()

  let jumpcmd = 'silent! ' . qf.type . qf.type
  let pos = s:GetPositionInList(qf.list)
  let lineno = line('.')
  let bufnum = bufnr('%')

  " If we don't know the position in the list, we must be in a buffer that
  " doesn't have an entry in the (quickfix) list.
  " Execute (c|l)(prev|next) and get on with our life
  if pos == -1
    exec 'silent! ' . qf.type . a:cmd
  else
    " Otherwise, go to the next/prev entry that has a different line number
    let idx = pos
    if a:cmd == 'prev'
      while idx > 0 && qf.list[idx].bufnr == bufnum && qf.list[idx].lnum >= lineno
	let idx -= 1
      endwhile
    else
      while idx < len(qf.list) - 1&& qf.list[idx].bufnr == bufnum && qf.list[idx].lnum <= lineno 
	let idx += 1
      endwhile
    endif
    let jumpcmd = jumpcmd . ' ' . (idx + 1)
  endif

  exec jumpcmd
  normal! zvzz
endfunction

" Intelligently go to next location or quickfix
function! quickfix#NextResult() abort
  call s:NavCommand('next')
endfunction

function! quickfix#PrevResult() abort
  call s:NavCommand('prev')
endfunction

function! s:GetPositionInList(list) abort
  let bufnum = bufnr('%')
  let lineno = line('.')
  let i = 0
  let foundbuf = 0
  for item in a:list
    if bufnum == item.bufnr
      let foundbuf = 1
      if item.lnum > lineno
	if i == 0
	  return 0
	else
	  if bufnum == a:list[i - 1].bufnr
	    return i - 1
	  else
	    return i
	  endif
	endif
      endif
    elseif foundbuf
      return i - 1
    endif
    let i += 1
  endfor
  return foundbuf ? i - 1 : -1
endfunction

function! s:UpdateQFListPosition(...) abort
  let qf = s:GetActiveList()
  if empty(qf.list)
    return
  endif
  if !s:IsListOpen(qf.type)
    return
  endif
  let pos = s:GetPositionInList(qf.list)
  let cur = getcurpos()
  if pos != -1 && qf.list[pos].bufnr == bufnr('%')
    exec qf.type . qf.type . " " . (pos + 1)
    call setpos('.', cur)
  endif
  if s:timerid != -1
    call timer_stop(s:timerid)
    let s:timerid = -1
  endif
endfunction

let s:timerid = -1
function! s:UpdateQFListPositionBuffered(...) abort
  let delay = a:0 ? a:1 : 100
  if s:timerid != -1
    call timer_stop(s:timerid)
  endif
  let timerid = timer_start(delay, function('s:UpdateQFListPosition'))
endfunction

augroup UpdateQFListPosition
    autocmd!
    autocmd User ALELintPost call s:UpdateQFListPositionBuffered(5)
    autocmd CursorMoved * call s:UpdateQFListPositionBuffered(100)
augroup end
