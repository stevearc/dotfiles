let g:flow#autoclose = 1

augroup jsfmt
  autocmd!
  " This calls out to Neoformat, but only if @format is in the jsdoc
  autocmd BufWritePre *.js,*.jsx call prettier#SmartFormat()
augroup END
