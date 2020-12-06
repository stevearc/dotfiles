function! execute#Run(binary) abort
  :w
  :silent !clear
  exec ":botright split | terminal " . a:binary . " " . @%
endfunction
