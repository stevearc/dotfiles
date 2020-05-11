if luaeval('vim.lsp == null')
  augroup RecheckCoverage
    autocmd! *
    autocmd InsertLeave,BufReadPost,BufWritePost *.js call flow#recheckCoverage()
  augroup end

  let g:flow_coverage_uncovered_sign_texthl = get(g:, 'flow_coverage_uncovered_sign_texthl', 'ALEErrorSign')
  exe 'sign define FlowUntyped text=U texthl=' . g:flow_coverage_uncovered_sign_texthl

  command! -buffer -bar FlowCoverageEnable call flow#enableCoverage()
  command! -buffer -bar FlowCoverageDisable call flow#disableCoverage()
  command! -buffer -bar FlowCoverageToggle call flow#toggleCoverage()
  command! -buffer -bar FlowCoverageGlobalEnable call flow#enableGlobalCoverage()
  command! -buffer -bar FlowCoverageGlobalDisable call flow#disableGlobalCoverage()
  command! -buffer -bar FlowCoverageGlobalToggle call flow#toggleGlobalCoverage()
endif
