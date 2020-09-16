nnoremap <silent> - :Defx `expand('%:p:h')` -search=`expand('%:p')` -vertical-preview -preview-height=100 -preview-width=80<CR>

nnoremap <leader>w :Defx -split=vertical -winwidth=50 -direction=topleft -toggle<CR>
nnoremap <leader>W :Defx `expand('%:p:h')` -search=`expand('%:p')` -split=vertical -winwidth=50 -direction=topleft -toggle<CR>
