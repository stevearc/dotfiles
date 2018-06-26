let b:ale_linters = ['clangtidy']

augroup cppfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if file is in a whitelisted directory
  autocmd BufWritePre <buffer> call smartformat#Format('cpp', 'Neoformat')
augroup END
