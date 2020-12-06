function! smartformat#Format(filetype, command) abort
  if !g:smartformat_enabled
    return
  endif
  for line in get(g:no_format_dirs, a:filetype, [])
    if line == strpart(expand('%:p'), 0, len(line))
      return
    endif
  endfor
  for line in get(g:no_format_dirs, '_', [])
    if line == strpart(expand('%:p'), 0, len(line))
      return
    endif
  endfor
  exec a:command
endfunction
