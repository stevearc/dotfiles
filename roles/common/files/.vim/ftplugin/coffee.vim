autocmd BufWritePost *.coffee silent make!
autocmd QuickFixCmdPost *.coffee nested cwindow | redraw!
setl foldmethod=indent
setl nofoldenable

map <leader>m :CoffeeWatch vert<cr>
vmap <leader>m :CoffeeCompile vert<cr>
