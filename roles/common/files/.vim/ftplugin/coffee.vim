autocmd BufWritePost * silent make!
autocmd QuickFixCmdPost * nested cwindow | redraw!
setl foldmethod=indent
setl nofoldenable

map <leader>m :CoffeeWatch vert<cr>
vmap <leader>m :CoffeeCompile vert<cr>
