setl foldmethod=indent
setl nofoldenable
let coffee_make_options = '-o /tmp'

map <buffer> <leader>m :CoffeeWatch vert<cr>
vmap <buffer> <leader>m :CoffeeCompile vert<cr>

" DISABLED until I figure out how to make cjsx behave
" au BufWritePost <buffer> call CoffeeMake()
" function! CoffeeMake()
"     silent make
"     cwindow
"     redraw!
" endfunction
