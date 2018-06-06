" Set grep program and map leader-g to grep the hovered word in the current workspace

if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --nocolor
else
endif

nnoremap <leader>g :call smartgrep#grep(expand('<cword>'))<CR>
