fun! Subgrep(args) abort
  exec "vimgrep /" . a:args . "/ " . b:netrw_curdir . '/**'
  call quickerfix#Open('c')
endf

command! -buffer -bar -nargs=+ Subgrep call Subgrep('<args>')
command! -buffer -bar BookmarkGoto call bookmarks#GotoBookmark()
command! -buffer -bar BookmarkDelete call bookmarks#DeleteBookmark()

setlocal noswapfile

nnoremap <buffer> <leader>db :BookmarkDelete<CR>
nnoremap <buffer> gb :BookmarkGoto<CR>
nnoremap <buffer> <leader>c :exec 'Explore ' . getcwd()<CR>

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
