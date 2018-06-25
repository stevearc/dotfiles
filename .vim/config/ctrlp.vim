" CTRLP
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_switch_buffer = 'eTvh'
" Use ctrl-p only if we're not using command-t
if empty(globpath(&runtimepath, "plugin/command-t.vim", 1))
  let g:ctrlp_map = '<leader>t'
else
  nnoremap <leader>t :CommandT<CR>
endif
let g:ctrlp_tabpage_position = 'last'
let g:ctrlp_by_filename = 1
let g:ctrlp_extensions = ['line']
if executable('ag')
  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
elseif executable('ack')
  let g:ctrlp_user_command = 'ack --nocolor -f %s'
endif

nnoremap <leader>b :CtrlPBuffer<CR>
nnoremap <leader>v :CtrlPLine %<CR>
