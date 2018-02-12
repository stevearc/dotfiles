let g:flow#autoclose = 1

nnoremap <buffer> K :FlowTypeAtPos<CR>
nnoremap <buffer> <leader>c :FlowCoverageToggle<CR>
nnoremap <buffer> gd :FlowGetDef<CR>zz

augroup jsfmt
  autocmd!
  " This calls out to Neoformat, but only if @format is in the jsdoc
  autocmd BufWritePre *.js,*.jsx call prettier#SmartFormat()
augroup END
