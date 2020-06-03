source ~/.vim/config/lsp_default_bindings.vim

augroup jsonfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('json', 'Neoformat')
augroup END

