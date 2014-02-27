autocmd BufWritePost *.coffee silent make!
autocmd QuickFixCmdPost *.coffee nested cwindow | redraw!
setl foldmethod=indent
setl nofoldenable
let coffee_make_options = '-o /tmp'

map <leader>m :CoffeeWatch vert<cr>
vmap <leader>m :CoffeeCompile vert<cr>
