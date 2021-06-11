if g:use_barbar
  let bufferline = get(g:, 'bufferline', {})
  let bufferline.closable = v:false
  let bufferline.animation = v:false
  let bufferline.icons = 'numbers'

  " Move to previous/next
  nnoremap <silent> H :BufferPrevious<CR>
  nnoremap <silent> L :BufferNext<CR>
  " Re-order to previous/next
  nnoremap <silent> <C-H> :BufferMovePrevious<CR>
  nnoremap <silent> <C-L> :BufferMoveNext<CR>
  " Goto buffer in position...
  nnoremap <silent> <leader>1 :BufferGoto 1<CR>
  nnoremap <silent> <leader>2 :BufferGoto 2<CR>
  nnoremap <silent> <leader>3 :BufferGoto 3<CR>
  nnoremap <silent> <leader>4 :BufferGoto 4<CR>
  nnoremap <silent> <leader>5 :BufferGoto 5<CR>
  nnoremap <silent> <leader>6 :BufferGoto 6<CR>
  nnoremap <silent> <leader>7 :BufferGoto 7<CR>
  nnoremap <silent> <leader>8 :BufferGoto 8<CR>
  nnoremap <silent> <leader>9 :BufferGoto 9<CR>
  nnoremap <silent> <leader>` :BufferLast<CR>
  nnoremap <silent> <leader>c :BufferClose<CR>
else
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
  nnoremap <leader>` :$tabnext<CR>

  " Navigate tabs with H and L
  " We can't rebind <Tab> because that's equivalent to <C-i> and we want to keep
  " the <C-i>/<C-o> navigation :/
  nnoremap L gt
  nnoremap H gT

  nnoremap <C-w><C-b> :tab split<CR>
  nnoremap <C-w><C-t> :$tabnew<CR>
  nnoremap <C-H> :tabm -<CR>
  nnoremap <C-L> :tabm +<CR>
endif
