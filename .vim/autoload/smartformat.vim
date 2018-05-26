if (exists('g:loaded_smartformat') && g:loaded_smartformat)
  finish
endif
let g:loaded_smartformat = 1

function! smartformat#Format(filetype, command)
  for line in get(g:format_dirs, a:filetype, [])
    if line == strpart(expand('%:p'), 0, len(line))
      exec a:command
      return
    endif
  endfor
endfunction
