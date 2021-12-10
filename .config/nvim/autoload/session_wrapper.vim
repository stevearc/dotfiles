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
  let s:detach_after_open = a:detach
  let l:sessions = xolox#session#get_names(0)
  call luaeval("vim.ui.select(_A, {prompt='Open session', kind='session'}, function(s) vim.fn['session_wrapper#OnChooseSession'](s) end)", l:sessions)
endfunction

function! session_wrapper#OnChooseSession(session)
  if a:session == v:null
    return
  endif
  exe ':OpenSession ' . a:session
  if s:detach_after_open || a:session ==# 'last'
    call session_wrapper#DetachSession()
  endif
endfunction

function! session_wrapper#SafeDelete()
  let l:names = xolox#session#get_names(0)
  if len(l:names) > 1
    call luaeval("vim.ui.select(_A, {prompt='Delete session', kind='session'}, function(s) vim.fn['session_wrapper#OnChooseDeleteSession'](s) end)", l:names)
  elseif len(l:names) == 1
    call session_wrapper#OnChooseDeleteSession(l:names[0])
  else
    echo 'No sessions to delete'
  endif
endfunction

function! session_wrapper#OnChooseDeleteSession(session)
  if a:session == v:null
    return
  endif
  if confirm('Delete ' . a:session . '? ', '&Yes\n&No\n') == 1
    call s:DeleteSession(a:session)
  endif
endfunction

function! s:DeleteSession(session)
  let session_path = xolox#session#name_to_path(a:session)
  if xolox#session#is_tab_scoped()
    let detach = t:this_session == session_path
  else
    let detach = v:this_session == session_path
  endif
  exec 'DeleteSession ' . a:session
  if detach
    call session_wrapper#DetachSession()
  endif
endfunction

function! session_wrapper#vcs_feature_branch()
  let [kind, directory] = xolox#session#suggestions#find_vcs_repository()
  if kind ==# 'hg'
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
