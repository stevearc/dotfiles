command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])

nnoremap <silent> <C-N> <cmd>lua require'qf_helper'.navigate(1)<CR>
nnoremap <silent> <C-P> <cmd>lua require'qf_helper'.navigate(-1)<CR>
nnoremap <leader>q <cmd>lua require'qf_helper'.toggle('c')<CR>
nnoremap <leader>l <cmd>lua require'qf_helper'.toggle('l')<CR>

lua require('qf_helper').setup({})
