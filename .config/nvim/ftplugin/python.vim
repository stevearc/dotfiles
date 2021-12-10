" Abbreviations
iabbr <buffer> inn is not None
iabbr <buffer> ipmort import
iabbr <buffer> improt import

setlocal shiftwidth=4 tabstop=4 softtabstop=4 tw=88

function! s:Run() abort
  write
  silent !clear
  botright split
  terminal python %
endfunction
nnoremap <leader>e <cmd>call <sid>Run()<CR>
