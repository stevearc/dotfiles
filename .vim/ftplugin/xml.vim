let b:neoformat_enabled_xml = ['xmllint']

augroup xmlfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('xml', 'Neoformat')
augroup END
