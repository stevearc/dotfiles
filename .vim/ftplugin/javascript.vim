let b:ale_enabled = 0
let b:neoformat_enabled_javascript = ['prettier']

" vim-javascript flow syntax highlighting
let g:javascript_plugin_flow = 1

source ~/.vim/config/lsp_default_bindings.vim

augroup jsfmt
  autocmd! * <buffer>
  " This calls out to Neoformat, but only if @format is in the jsdoc
  autocmd BufWritePre <buffer> call prettier#SmartFormat()
augroup END
