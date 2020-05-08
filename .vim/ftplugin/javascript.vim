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

function! FlowStatusLine()
  let l:percent = get(b:, 'flow_coverage_percent', -1)
  let l:message = get(b:, 'flow_coverage_message', '')
  let l:line = '%f ' . lsp_addons#StatusLine()
  try
    let l:diagnosticsDict = LanguageClient#statusLineDiagnosticsCounts()
  catch
      return l:line
  endtry
  let l:errors = get(l:diagnosticsDict,'E',0)
  if l:percent == -1 || !flow#isCoverageEnabled() || l:errors > 0
    return l:line
  endif
  return l:line . ' [' . l:percent . '%%]'
endfunction

if luaeval('vim.lsp ~= null')
lua << END
  require'nvim_lsp'.flow.setup{
    cmd = {"flow", "lsp"};
    settings = {
      flow = {
        lazyMode = "--lazy";
        showUncovered = true;
        stopFlowOnExit = false;
        useBundledFlow = false;
      }
    }
  }
END
else
  augroup FlowCoverageStatusLine
    autocmd! * <buffer>
    autocmd BufWinEnter <buffer> setlocal statusline=%!FlowStatusLine()
  augroup END

  let g:flow_coverage_enabled = v:true
  nnoremap <buffer> <leader>c :FlowCoverageGlobalToggle<CR>
endif
