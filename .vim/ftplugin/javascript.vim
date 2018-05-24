let g:flow#autoclose = 1

nnoremap <buffer> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <buffer> <leader>c :FlowCoverageToggle<CR>
nnoremap <buffer> gd :call LanguageClient#textDocument_definition()<CR>zz
nnoremap <buffer> gD :FlowGetDefTab<CR>zz

augroup jsfmt
  autocmd!
  " This calls out to Neoformat, but only if @format is in the jsdoc
  autocmd BufWritePre *.js,*.jsx call prettier#SmartFormat()
augroup END
