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

function! s:NavCommand(cmd, qf) abort
  let jumpcmd = 'silent! ' . a:qf.type . a:qf.type
  exec 'silent! ' . a:qf.type . a:cmd
  normal! zvzz
endfunction
