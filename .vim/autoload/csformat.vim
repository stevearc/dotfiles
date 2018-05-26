if (exists('g:loaded_csformat') && g:loaded_csformat)
  finish
endif
let g:loaded_csformat = 1

function! csformat#FormatPreserveCursor()
  let s:pos = getpos('.')
  let s:view = winsaveview()
  OmniSharpCodeFormat
  call setpos('.', s:pos)
  call winrestview(s:view)
endfunction
