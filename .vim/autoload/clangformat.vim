if (exists('g:loaded_clangformat') && g:loaded_clangformat)
  finish
endif
let g:loaded_clangformat = 1
let s:include_dirs = []

function! clangformat#SmartFormat()
  for line in s:include_dirs
    if line == strpart(expand('%:p'), 0, len(line))
      Neoformat
      return
    endif
  endfor
endfunction

function! clangformat#LoadRC()
  let s:cache = $HOME . '/.clangformat.vim'
  if filereadable(s:cache)
    for line in readfile(s:cache)
      call add(s:include_dirs, line)
    endfor
  endif
endfunction

call clangformat#LoadRC()
