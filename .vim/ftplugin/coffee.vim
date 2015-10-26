setl foldmethod=indent
setl nofoldenable
let g:coffee_make_options = '-o /tmp'

nnoremap <buffer> <leader>m :CoffeeWatch vert<cr>
vnoremap <buffer> <leader>m :CoffeeCompile vert<cr>

augroup CoffeeMake
  au!
  au BufWritePost <buffer> call CoffeeMake()
augroup END
function! CoffeeMake()
    silent make!
    cwindow
    redraw!
endfunction
