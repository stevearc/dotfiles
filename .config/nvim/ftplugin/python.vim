" Abbreviations
iabbr <buffer> inn is not None
iabbr <buffer> ipmort import
iabbr <buffer> improt import

setlocal shiftwidth=4 tabstop=4 softtabstop=4 tw=88

lua <<EOF
function stevearc.py_autoimport()
  vim.cmd('write')
  vim.cmd('silent !autoimport ' .. vim.api.nvim_buf_get_name(0))
  vim.cmd('edit')
  vim.lsp.buf.formatting()
end
EOF
if executable('autoimport')
  nnoremap <leader>o <cmd>lua stevearc.py_autoimport()<CR>
endif

function! s:Run() abort
  write
  silent !clear
  botright split
  terminal python %
endfunction
nnoremap <leader>e <cmd>call <sid>Run()<CR>
