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
  if luaeval("pcall(require, 'telescope')")
    let s:detach_after_open = a:detach
    let l:sessions = xolox#session#get_names(0)
    call luaeval("require('stevearc.telescope').select('Open Session', _A, 'session_wrapper#OnChooseSession')", l:sessions)
  else
    OpenSession
    if a:detach
      call session_wrapper#DetachSession()
    endif
  endif
endfunction

function! session_wrapper#OnChooseSession(session)
  exe ':OpenSession ' . a:session
  if s:detach_after_open
    call session_wrapper#DetachSession()
  endif
  if g:use_barbar
    " Close all empty buffers
    let [i, n; empty] = [1, bufnr('$')]
    while i <= n
      if bufexists(i) && bufname(i) == ''
        call add(empty, i)
      endif
      let i += 1
    endwhile
    if len(empty) > 0
      exe 'bdelete' join(empty)
    endif
  endif
endfunction

function! session_wrapper#SafeDelete()
  let l:names = xolox#session#get_names(0)
  if len(l:names) > 1
    if luaeval("pcall(require, 'telescope')")
      call luaeval("require('stevearc.telescope').select('Delete Session', _A, 'session_wrapper#OnChooseDeleteSession')", l:names)
    else
      call s:DeleteSession()
    endif
  elseif len(l:names) == 1
    call session_wrapper#OnChooseDeleteSession(l:names[0])
  else
    echo "No sessions to delete"
  endif
endfunction

function! session_wrapper#OnChooseDeleteSession(session)
  if confirm("Delete " . a:session . "? ", "&Yes\n&No\n") == 1
    call s:DeleteSession(a:session)
  endif
endfunction

function! s:DeleteSession(...)
  let l:session = ''
  let l:detach = v:true
  if a:0 > 0
    let l:session = a:1
    let l:session_path = xolox#session#name_to_path(l:session)
    if xolox#session#is_tab_scoped()
      let l:detach = t:this_session == l:session_path
    else
      let l:detach = v:this_session == l:session_path
    endif
  endif
  exec 'DeleteSession ' . l:session
  if l:detach
    call session_wrapper#DetachSession()
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
