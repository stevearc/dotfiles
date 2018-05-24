" Configure vim-session

" Don't save help buffers
set sessionoptions-=help

" Don't save quickfix buffers
set sessionoptions-=qf

" Don't autoload sessions on startup
let g:session_autoload = 'no'
" Don't prompt to save on exit
let g:session_autosave = 'no'
let g:session_autosave_periodic = 1
let g:session_verbose_messages = 0
let g:session_command_aliases = 1
let g:session_menu = 0
let g:session_name_suggestion_function = "session_wrapper#vcs_feature_branch"

" Helpful wrappers around vim-session
function! s:OverwriteQuickSave()
  let name = xolox#session#find_current_session()
  if !empty(name)
    " If we have a current session name, disable the save callback and remap
    " <leader>ss to save with no prompt.
    aug SessionSaveTrigger
      au!
    aug END
    nnoremap <leader>ss :wa<CR>:SaveSession<CR>
  endif
endfunction
augroup SessionSaveTrigger
  au!
  au BufWrite,BufRead * :call s:OverwriteQuickSave()
augroup END
call add(g:ctrlp_extensions, 'session_wrapper')

function! s:QuickLoad()
  let names = xolox#session#get_names(0)
  for name in names
    if name == 'quicksave'
      SessionOpen quicksave
      SessionDelete! quicksave
    endif
  endfor
endfunction
aug QuickLoad
  au!
  au VimEnter * nested call s:QuickLoad()
aug END

nnoremap <leader>ss :wa<CR>:SaveSession
nnoremap <leader>so :call session_wrapper#QuickOpen()<CR>
nnoremap <leader>sd :call session_wrapper#SafeDelete()<CR>
nnoremap <leader>zz :wa<CR>:SaveSession! quicksave<CR>:qa<CR>
