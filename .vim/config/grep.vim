if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor
  " Map leader-g to grep the hovered word in the current workspace
  nnoremap <leader>g :grep <cword> <CR><CR> :copen <CR>
elseif executable('ack')
  set grepprg=ack\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ack --nocolor -f %s'
  " Map leader-g to grep the hovered word in the current workspace
  nnoremap <leader>g :grep <cword> <CR><CR> :copen <CR>
else
  " Map leader-g to grep the hovered word in the current workspace
  nnoremap <leader>g :grep -IR <cword> * <CR><CR> :copen <CR>
endif
