if (exists('g:loaded_smartgrep') && g:loaded_smartgrep)
  finish
endif
let g:loaded_smartgrep = 1

function! smartgrep#grep(word)
  cclose
  if !empty(fugitive#extract_git_dir(expand('%:p')))
    exec 'silent Ggrep! ' . a:word
  elseif executable('ag') || executable('ack')
    exec 'silent grep! ' . a:word
  else
    exec 'silent grep! -IR ' . a:word . ' .'
  endif
  call quickfix#QFToggle('c')
endfunction

