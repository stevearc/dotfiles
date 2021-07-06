command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])

nnoremap <silent> <C-N> <cmd>QNext<CR>
nnoremap <silent> <C-P> <cmd>QPrev<CR>
nnoremap <silent> <leader>q <cmd>QFToggle!<CR>
nnoremap <silent> <leader>l <cmd>LLToggle!<CR>

lua require('qf_helper').setup({})
