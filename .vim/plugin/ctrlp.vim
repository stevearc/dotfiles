let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_switch_buffer = 'eTvh'
let g:ctrlp_map = '<leader>t'
let g:ctrlp_by_filename = 1
let g:ctrlp_extensions = ['session_wrapper']

let g:ctrlp_user_command = {
  \ 'types': {
    \ 'git': ['.git', 'git ls-files --cached --others --exclude-standard %s'],
    \ 'hg': ['.hg', 'hg --cwd %s locate -I .'],
    \ },
  \ }

if executable('rg')
  let g:ctrlp_user_command['fallback'] = 'rg %s -l --color never -g ""'
elseif executable('ag')
  let g:ctrlp_user_command['fallback'] = 'ag %s -l --nocolor -g ""'
elseif executable('ack')
  let g:ctrlp_user_command['fallback'] = 'ack --nocolor -f %s'
endif

nnoremap <leader>b :CtrlPBuffer<CR>
