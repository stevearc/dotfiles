if (exists('g:loaded_session_wrapper') && g:loaded_session_wrapper)
	finish
endif
let g:loaded_session_wrapper = 1
let s:detach_after_open = 0

function! session_wrapper#DetachSession()
  if xolox#session#is_tab_scoped()
    let t:this_session = ''
  else
    let v:this_session = ''
  endif
endfunction

function! session_wrapper#QuickOpen(detach)
  if exists('s:id')
    let s:detach_after_open = a:detach
    call ctrlp#init(s:id)
  else
    OpenSession
    if a:detach
      call session_wrapper#DetachSession()
    endif
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
  if s:detach_after_open
    call session_wrapper#DetachSession()
  endif
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

function! session_wrapper#vcs_feature_branch()
  let [kind, directory] = xolox#session#suggestions#find_vcs_repository()
  if kind == 'hg'
    let command = 'hg log -l 1 -T "{bookmarks}" | xargs printf "%s\n"'
    let names_to_ignore = ['default']
    let result = xolox#misc#os#exec({'command': command, 'check': 0})
    if result['exit_code'] == 0 && !empty(result['stdout'])
      let branch_name = xolox#misc#str#trim(result['stdout'][0])
      if !empty(branch_name) && index(names_to_ignore, branch_name) == -1
        return [xolox#misc#str#slug(branch_name)]
      endif
    endif
  endif
  return xolox#session#suggestions#vcs_feature_branch()
endfunction
