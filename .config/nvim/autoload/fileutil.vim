function! fileutil#GetMatchingLines(pattern) abort
  let lines = []
  let n = 1
  while n < line("$")
    let line = getline(n)
    let match = matchlist(line, a:pattern)
    if !empty(match)
      call add(lines, match)
    endif
    let n = n + 1
  endwhile
  return lines
endfunction

function! fileutil#GetMatchingLine(pattern) abort
  let n = 1
  while n < line("$")
    let line = getline(n)
    let match = matchlist(line, a:pattern)
    if !empty(match)
      return match
    endif
    let n = n + 1
  endwhile
  return []
endfunction
