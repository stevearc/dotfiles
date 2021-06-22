let b:neoformat_enabled_javascript = ['prettier']
setlocal fdm=syntax

" vim-javascript flow syntax highlighting
let g:javascript_plugin_flow = 1

augroup jsfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if @format is in the jsdoc
  autocmd BufWritePre <buffer> call prettier#SmartFormat()
augroup END
