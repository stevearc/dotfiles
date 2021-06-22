" Check if there is a directive in the top comments
function! hackfmt#HasDirective(directive) abort
  let n = 2
  while n < line("$")
    let line = getline(n)
    if match(line, '^\s*//\s*@' . a:directive . '\s*$') >= 0
      return 1
    elseif match(line, '^\s*/\?//') == -1
      " If we've reached the end of the jsdocs, return
      return 0
    endif
    let n = n + 1
  endwhile
  return 0
endfunction

" Only run Neoformat on files with @format at the top
function! hackfmt#SmartFormat() abort
  if hackfmt#HasDirective("format")
    Neoformat
  else
    call smartformat#Format('php', 'Neoformat')
  endif
endfunction
