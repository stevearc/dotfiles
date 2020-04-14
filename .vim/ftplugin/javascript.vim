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

function! MyStatusLine()
  let l:percent = get(b:, 'flow_coverage_percent', -1)
  let l:message = get(b:, 'flow_coverage_message', '')
  if l:percent == -1 || !flow#isCoverageEnabled()
    return '%f'
  endif
  let line = '%f [' . l:percent . '%%]'
  return line
endfunction
augroup FlowCoverageStatusLine
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> setlocal statusline=%!MyStatusLine()
augroup END

let g:flow_coverage_enabled = v:true
nnoremap <buffer> <leader>c :FlowCoverageGlobalToggle<CR>
