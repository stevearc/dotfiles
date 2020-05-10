source ~/.vim/config/lsp_default_bindings.vim

let b:neoformat_enabled_cpp = ['clangformat']

augroup cppfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if file is in a whitelisted directory
  autocmd BufWritePre <buffer> call smartformat#Format('cpp', 'Neoformat')
augroup END
