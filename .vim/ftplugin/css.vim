let b:neoformat_enabled_css = ['prettier']

command! SortCSSBraceContents :g#\({\n\)\@<=#.,/}/sort

augroup cssfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> call smartformat#Format('css', 'Neoformat')
augroup END
