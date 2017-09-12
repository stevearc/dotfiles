if (exists('g:loaded_prettier') && g:loaded_prettier)
  finish
endif
let g:loaded_prettier = 1

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
  endif
endfunction
