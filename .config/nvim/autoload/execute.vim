function! execute#Run(binary) abort
  write
  silent !clear
  exec ":botright split | terminal " . a:binary . " " . @%
endfunction
