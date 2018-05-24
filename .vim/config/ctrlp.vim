" CTRLP
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_switch_buffer = 'eTvh'
let g:ctrlp_lazy_update = 1
let g:ctrlp_map = '<leader>t'
let g:ctrlp_by_filename = 1
let g:ctrlp_extensions = []
if executable('ag')
  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif

nnoremap <leader>b :CtrlPBuffer<CR>
