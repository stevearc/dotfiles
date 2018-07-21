function! smartformat#Format(filetype, command) abort
  for line in get(g:format_dirs, a:filetype, [])
    if line == strpart(expand('%:p'), 0, len(line))
      exec a:command
      return
    endif
  endfor
endfunction
