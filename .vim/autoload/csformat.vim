if (exists('g:loaded_csformat') && g:loaded_csformat)
  finish
endif
let g:loaded_csformat = 1
let s:csformat_config = []

function! csformat#SmartFormat()
  for line in s:csformat_config
    if line == strpart(expand('%:p'), 0, len(line))
      call csformat#FormatPreserveCursor()
      return
    endif
  endfor
endfunction

function! csformat#FormatPreserveCursor()
  let s:pos = getpos('.')
  let s:view = winsaveview()
  OmniSharpCodeFormat
  call setpos('.', s:pos)
  call winrestview(s:view)
endfunction

function! csformat#LoadRC()
  let s:cache = $HOME . '/.csformat.vim'
  if filereadable(s:cache)
    for line in readfile(s:cache)
      call add(s:csformat_config, line)
    endfor
  endif
endfunction

call csformat#LoadRC()
