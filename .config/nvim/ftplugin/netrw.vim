fun! s:Sgrep(args) abort
  exec "silent vimgrep /" . a:args . "/ " . b:netrw_curdir . '/**'
  lua require'qf_helper'.open('c', {enter=true})
endf

command! -buffer -bar -nargs=+ Sgrep call <sid>Sgrep('<args>')

setlocal noswapfile

nnoremap <buffer> <leader>C :exec 'Explore ' . getcwd()<CR>

" If tree view
if w:netrw_liststyle == 3
  " <cr> on files opens in P window
  augroup netrw_treeopts
    autocmd! * <buffer>
    autocmd BufWinEnter <buffer> let g:netrw_browse_split = 4
  augroup END
  let g:netrw_browse_split = 4
else
  augroup netrw_flat
    autocmd! * <buffer>
    autocmd BufWinEnter <buffer> let g:netrw_browse_split = 0
  augroup END
  let g:netrw_browse_split = 0
endif
