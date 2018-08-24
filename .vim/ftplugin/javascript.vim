let b:ale_linters = ['flow']
let b:neoformat_enabled_javascript = ['prettier']

" vim-javascript flow syntax highlighting
let g:javascript_plugin_flow = 1


let g:flow#autoclose = 1

nnoremap <buffer> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <buffer> <leader>c :FlowCoverageToggle<CR>
nnoremap <buffer> gd m':call LanguageClient#textDocument_definition()<CR>zz
nnoremap <buffer> gD m':$tab split<CR>:call LanguageClient#textDocument_definition()<CR>zz

augroup jsfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if @format is in the jsdoc
  autocmd BufWritePre <buffer> call prettier#SmartFormat()
augroup END
