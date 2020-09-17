augroup jsonfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('json', 'Neoformat')
augroup END

