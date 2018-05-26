let g:coffee_make_options = '-o /tmp'

nnoremap <buffer> <leader>m :CoffeeWatch vert<cr>
vnoremap <buffer> <leader>m :CoffeeCompile vert<cr>

augroup CoffeeMake
  au! * <buffer>
  au BufWritePost <buffer> call CoffeeMake()
  autocmd BufWinEnter <buffer> setlocal foldmethod=indent nofoldenable
augroup END
function! CoffeeMake()
    silent make!
    cwindow
    redraw!
endfunction
