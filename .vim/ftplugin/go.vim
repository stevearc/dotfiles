nnoremap <buffer> <Leader>i <Plug>(go-info)
nnoremap <buffer> <Leader>gd <Plug>(go-doc)
nnoremap <buffer> <Leader>gv <Plug>(go-doc-vertical)

nnoremap <buffer> <leader>b <Plug>(go-build)
nnoremap <buffer> <leader>dt <Plug>(go-test)

nnoremap <buffer> gd <Plug>(go-def)
nnoremap <buffer> <Leader>ds <Plug>(go-def-split)
nnoremap <buffer> <Leader>dv <Plug>(go-def-vertical)

" Use go's autocomplete instead of C-P
let g:autocomplete_cmd = "\<C-X>\<C-O>"
" Conflicts with syntastic
let g:go_auto_type_info = 0
