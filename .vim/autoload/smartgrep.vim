function! smartgrep#grep(word) abort
  cclose
  if !empty(fugitive#extract_git_dir(expand('%:p')))
    exec 'silent Ggrep! ' . a:word
  elseif executable('ag') || executable('ack')
    exec 'silent grep! ' . a:word
  else
    exec 'silent grep! -IR ' . a:word . ' .'
  endif
  call quickerfix#Open('c')
endfunction
