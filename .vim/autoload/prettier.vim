if (exists('g:loaded_prettier') && g:loaded_prettier)
  finish
endif
let g:loaded_prettier = 1
let s:prettier_config = []

" Check if there is a directive in the jsdoc
function! prettier#HasDirective(directive)
  let n = 1
  while n < line("$")
    let line = getline(n)
    if match(line, '^\s*\*\s*@' . a:directive . '\s*$') >= 0
      return 1
    elseif match(line, '^\s*/\?\*') == -1
      " If we've reached the end of the jsdocs, return
      return 0
    endif
    let n = n + 1
  endwhile
  return 0
endfunction

" Only run Neoformat on files with @format at the top
function! prettier#SmartFormat()
  if prettier#HasDirective("format")
    Neoformat
  else
    for line in s:prettier_config
      if line == strpart(expand('%:p'), 0, len(line))
        Neoformat
        return
      endif
    endfor
  endif
endfunction

function! prettier#LoadRC()
  let s:cache = $HOME . '/.prettier.vim'
  if filereadable(s:cache)
    for line in readfile(s:cache)
      call add(s:prettier_config, line)
    endfor
  endif
endfunction

call prettier#LoadRC()
