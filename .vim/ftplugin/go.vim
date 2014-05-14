nmap <Leader>i <Plug>(go-info)
nmap <Leader>gd <Plug>(go-doc)
nmap <Leader>gv <Plug>(go-doc-vertical)

nmap <leader>b <Plug>(go-build)
nmap <leader>dt <Plug>(go-test)

nmap gd <Plug>(go-def)
nmap <Leader>ds <Plug>(go-def-split)
nmap <Leader>dv <Plug>(go-def-vertical)

" Use go's autocomplete instead of C-P
let g:autocomplete_cmd = "\<C-X>\<C-O>"
" Conflicts with syntastic
let g:go_auto_type_info = 0
