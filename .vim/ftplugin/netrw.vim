command! -buffer -bar BookmarkGoto call bookmarks#GotoBookmark()
command! -buffer -bar BookmarkDelete call bookmarks#DeleteBookmark()

setlocal noswapfile

nnoremap <leader>db :BookmarkDelete<CR>
nnoremap <leader>gb :BookmarkGoto<CR>
