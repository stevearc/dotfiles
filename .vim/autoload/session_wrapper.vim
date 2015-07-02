if (exists('g:loaded_session_wrapper') && g:loaded_session_wrapper)
	finish
endif
let g:loaded_session_wrapper = 1

function! session_wrapper#QuickOpen()
  if exists('s:id')
    call ctrlp#init(s:id)
  else
    OpenSession
  endif
endfunction

" Ctrlp integration for OpenSession

if exists('g:ctrlp_ext_vars')
  call add(g:ctrlp_ext_vars, {
    \ 'init': 'session_wrapper#GetSessions()',
    \ 'accept': 'session_wrapper#ChooseSession',
    \ 'lname': 'load session',
    \ 'sname': 'session',
    \ 'type': 'line',
    \ })

  let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
endif

function! session_wrapper#GetSessions()
  let names = xolox#session#get_names(0)
  return names
endfunction

function! session_wrapper#ChooseSession(mode, str)
	call ctrlp#exit()
  exe ':OpenSession ' . a:str
endfunction

function! session_wrapper#SafeDelete()
  let names = xolox#session#get_names(0)
  if len(names) > 1
    DeleteSession
  elseif len(names) == 1
    if confirm("Delete " . names[0] . "? ", "&Yes\n&No\n") == 1
      DeleteSession
    endif
  else
    echo "No sessions to delete"
  endif
endfunction
