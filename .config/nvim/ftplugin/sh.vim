" For $VARS and $vars in treesitter highlighting
hi link TSConstant Identifier
hi link TSVariable Identifier

" Use the built-in basic formatter instead of shfmt
let b:neoformat_enabled_sh = []
let b:neoformat_run_all_formatters = 1
let b:neoformat_basic_format_retab = 1
let b:neoformat_basic_format_trim = 1
augroup shfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('sh', 'Neoformat')
augroup END

nnoremap <leader>e :call execute#Run('bash')<cr>
