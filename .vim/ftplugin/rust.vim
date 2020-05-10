source ~/.vim/config/lsp_default_bindings.vim

se makeprg=cargo\ $*

augroup rustfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('rust', 'Neoformat')
augroup END
