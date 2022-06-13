" Configure vim-session

set sessionoptions=buffers,curdir,tabpages,winsize

let g:session_directory = stdpath('data') . '/sessions'
" Don't autoload sessions on startup
let g:session_autoload = 'no'
" Don't prompt to save on exit
if exists('g:started_by_firenvim') || empty(nvim_list_uis())
  finish
endif
let g:session_autosave = 'yes'
let g:session_autosave_to = 'last'
let g:session_autosave_periodic = 1
let g:session_autosave_silent = 1
let g:session_verbose_messages = 0
let g:session_command_aliases = 1
let g:session_menu = 0
let g:session_name_suggestion_function = "session_wrapper#vcs_feature_branch"

aug QuickLoad
  au!
  au VimEnter * nested call s:QuickLoad()
aug END

function! s:GetSaveCmd() abort
  let name = xolox#session#find_current_session()
  if empty(name)
    call feedkeys(":SaveSession ")
  else
    SaveSession
  endif
endfunction

function! s:QuickLoad() abort
  if !exists(':OpenSession')
    return
  endif
  let names = xolox#session#get_names(0)
  if !empty(argv())
    return
  endif
  for name in names
    if name == '__quicksave__'
      SessionOpen __quicksave__
      SessionDelete! __quicksave__
      call session_wrapper#DetachSession()
      break
    endif
  endfor
endfunction

function! s:QuickSave()
  wa
  SaveSession! __quicksave__
  qa
endfunction

nnoremap <leader>ss <cmd>wa<CR><cmd>call <sid>GetSaveCmd()<CR>
nnoremap <leader>so <cmd>call session_wrapper#QuickOpen(0)<CR>
nnoremap <leader>sb <cmd>call session_wrapper#QuickOpen(1)<CR>
nnoremap <leader>sd <cmd>call session_wrapper#SafeDelete()<CR>
nnoremap ZZ <cmd>call <sid>QuickSave()<CR>
command! SessionDetach call session_wrapper#DetachSession()
command! DetachSession call session_wrapper#DetachSession()
