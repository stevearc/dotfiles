" For $VARS and $vars in treesitter highlighting
hi link TSConstant Identifier
hi link TSVariable Identifier
:
function! s:Run() abort
  write
  silent !clear
  botright split
  terminal bash %
endfunction
nnoremap <leader>e <cmd>call <sid>Run()<CR>
