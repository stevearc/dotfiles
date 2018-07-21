function! bookmarks#GotoBookmark(...) abort
  if a:0 > 0
    exe "NetrwKeepj e " . fnameescape(a:1)
  else
    call chooser#Choose('Bookmark', get(g:, 'netrw_bookmarklist', []), 'bookmarks#GotoBookmark', {})
  endif
endfunction

function! bookmarks#DeleteBookmark(...) abort
  if a:0 > 0
    let idx = index(g:netrw_bookmarklist, a:1)
    call netrw#Call("MergeBookmarks")
    exe "NetrwKeepj call remove(g:netrw_bookmarklist, " . idx . ")"
  else
    call chooser#Choose('Bookmark', get(g:, 'netrw_bookmarklist', []), 'bookmarks#DeleteBookmark', {})
  endif
endfunction
