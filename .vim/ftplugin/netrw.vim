command! -buffer -bar BookmarkGoto call bookmarks#GotoBookmark()
command! -buffer -bar BookmarkDelete call bookmarks#DeleteBookmark()

nnoremap <leader>db :BookmarkDelete<CR>
nnoremap <leader>gb :BookmarkGoto<CR>
