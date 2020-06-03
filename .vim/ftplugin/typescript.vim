setlocal formatprg=prettier\ --stdin\ --stdin-filepath\ %
source ~/.vim/config/lsp_default_bindings.vim

augroup tsfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('typescript', 'Neoformat')
augroup END
