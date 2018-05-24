setlocal shiftwidth=4 tabstop=4 softtabstop=4

" python-mode options
let g:pymode_run = 0
let g:pymode_lint = 0
let g:pymode_rope_organize_imports_bind = '<leader>o'
let g:pymode_rope_goto_definition_bind = 'gd'
let g:pymode_rope_goto_definition_cmd = 'e'
let g:pymode_rope_complete_on_dot = 0

" python-mode shortcuts
nnoremap <buffer> <leader>a :PymodeLintAuto<CR> zz

" Abbreviations
iabbr <buffer> inn is not None
iabbr <buffer> ipmort import
iabbr <buffer> improt import

" Foxdot
nnoremap <CR> :call system('nc localhost 7088', getline('.'))<CR>
vnoremap <CR> y:call system('nc localhost 7088', @")<CR>
