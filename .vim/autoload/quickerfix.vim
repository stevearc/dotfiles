" Public functions {{{ "

function! quickerfix#QFToggle(cmd, ...) abort
  let l:wincount = winnr('$')
  let l:winnr = winnr()
  let list = a:cmd == 'l' ? getloclist(0) : getqflist()
  let height = a:0 && a:1 ? a:1 : min([max([len(list), g:qf_min_height]), g:qf_max_height])
  let pos = quickerfix#GetPositionInList(list)
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

function! quickerfix#Open(cmd, ...) abort
  if a:cmd == 'c' && quickerfix#IsQuickFixOpen()
    return
  endif
  if a:cmd == 'l' && quickerfix#IsLocListOpen()
    return
  endif
  let list = a:cmd == 'l' ? getloclist(0) : getqflist()
  let height = a:0 && a:1 ? a:1 : min([max([len(list), g:qf_min_height]), g:qf_max_height])
  let pos = quickerfix#GetPositionInList(list)
  let opencmd = a:cmd . "open " . height
  if a:cmd == "c"
    let opencmd = "botright " . opencmd
  endif
  exec opencmd
  if pos != -1
    exec a:cmd . a:cmd . " " . (pos + 1)
  endif

endfunction

" Intelligently go to next location or quickfix
function! quickerfix#NextResult(...) abort
  let qf = a:0 ? a:1 : quickerfix#GetActiveList()
  call s:NavCommand('next', qf)
endfunction

function! quickerfix#PrevResult(...) abort
  let qf = a:0 ? a:1 : quickerfix#GetActiveList()
  call s:NavCommand('prev', qf)
endfunction

function! quickerfix#IsLocListOpen() abort
  return !empty(filter(getwininfo(), 'v:val.quickfix && v:val.loclist'))
endfunction

function! quickerfix#IsQuickFixOpen() abort
  return !empty(filter(getwininfo(), 'v:val.quickfix && !v:val.loclist'))
endfunction

function! quickerfix#GetActiveList() abort
  let loclist = getloclist(0)
  let qflist = getqflist()
  let lret = {'type': 'l', 'list': loclist}
  let cret = {'type': 'c', 'list': qflist}
  " If loclist is empty, use quickfix
  if empty(loclist)
    return cret
  " If quickfix is empty, use loclist
  elseif empty(qflist)
    return lret
  elseif quickerfix#IsQuickFixOpen()
    if !quickerfix#IsLocListOpen()
      return cret
    endif
  elseif quickerfix#IsLocListOpen()
    return lret
  endif
  " They're either both empty or both open
  return g:qf_prefer_loclist ? lret : cret
endfunction

function! quickerfix#GetPositionInList(list) abort
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

" }}} Public functions "

" Update position {{{ "

function! quickerfix#UpdateQFListPosition(...) abort
  let qf = quickerfix#GetActiveList()
  if empty(qf.list)
    return
  endif
  if !s:IsListOpen(qf.type)
    return
  endif
  let pos = quickerfix#GetPositionInList(qf.list)
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
function! quickerfix#UpdateQFListPositionBuffered(...) abort
  let delay = a:0 ? a:1 : 100
  if s:timerid != -1
    call timer_stop(s:timerid)
  endif
  let timerid = timer_start(delay, function('quickerfix#UpdateQFListPosition'))
endfunction


" }}} Update position "

" Private functions {{{ "

function! s:GetActiveFromType(type) abort
  if a:type == 'c'
    return { 'type': a:type, 'list': getqflist() }
  else
    return { 'type': a:type, 'list': getloclist(0) }
  endif
endfunction

function! s:IsListOpen(type) abort
  return a:type == 'c' ? quickerfix#IsQuickFixOpen() : quickerfix#IsLocListOpen()
endfunction

function! s:NavCommand(cmd, qf) abort
  let jumpcmd = 'silent! ' . a:qf.type . a:qf.type
  let pos = quickerfix#GetPositionInList(a:qf.list)
  let lineno = line('.')
  let bufnum = bufnr('%')

  " If we don't know the position in the list, we must be in a buffer that
  " doesn't have an entry in the (quickfix) list.
  " Execute (c|l)(prev|next) and get on with our life
  if pos == -1
    exec 'silent! ' . a:qf.type . a:cmd
  else
    " Otherwise, go to the next/prev entry that has a different line number
    let idx = pos
    if a:cmd == 'prev'
      while idx > 0 && a:qf.list[idx].bufnr == bufnum && a:qf.list[idx].lnum >= lineno
	let idx -= 1
      endwhile
    else
      while idx < len(a:qf.list) - 1&& a:qf.list[idx].bufnr == bufnum && a:qf.list[idx].lnum <= lineno 
	let idx += 1
      endwhile
    endif
    let jumpcmd = jumpcmd . ' ' . (idx + 1)
  endif

  exec jumpcmd
  normal! zvzz
endfunction

" }}} Private functions "
