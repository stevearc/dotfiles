
" Fast tab navigation
nnoremap <leader>1 1gt
nnoremap <leader>2 2gt
nnoremap <leader>3 3gt
nnoremap <leader>4 4gt
nnoremap <leader>5 5gt
nnoremap <leader>6 6gt
nnoremap <leader>7 7gt
nnoremap <leader>8 8gt
nnoremap <leader>9 9gt

" Navigate tabs with H and L
" We can't rebind <Tab> because that's equivalent to <C-i> and we want to keep
" the <C-i>/<C-o> navigation :/
nnoremap L gt
nnoremap H gT

nnoremap <C-w><C-b> :tab split<CR>
nnoremap <C-w><C-t> :$tabnew<CR>
nnoremap <C-H> :tabm -<CR>
nnoremap <C-L> :tabm +<CR>
