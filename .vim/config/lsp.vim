" Configuration for LSP
if luaeval('vim.lsp == null')
    let g:nvim_lsp = 1
    let g:LanguageClient_autoStart = 1
    let g:LanguageClient_diagnosticsList = 'Location'
    let g:LanguageClient_loggingFile = expand('~/.LanguageClient.log')

    let g:LanguageClient_serverCommands = {
    \ 'javascript': ['flow', 'lsp', '--from', 'vim', '--lazy'],
    \ 'javascript.jsx': ['flow', 'lsp', '--from', 'vim', '--lazy'],
    \ 'php': ['hh', 'lsp', '--from', 'vim'],
    \ 'python': ['pyls'],
    \ 'rust': ['rls'],
    \ 'sh': ['bash-language-server', 'start'],
    \ }

    let g:LanguageClient_diagnosticsDisplay = {
    \ 1: {
    \   "name": "Error",
    \   "texthl": "ALEError",
    \   "signText": "•",
    \   "signTexthl": "ALEErrorSign",
    \   "virtualTexthl": "Error",
    \ },
    \ 2: {
    \   "name": "Warning",
    \   "texthl": "ALEWarning",
    \   "signText": "•",
    \   "signTexthl": "ALEWarningSign",
    \   "virtualTexthl": "Todo",
    \ },
    \ 3: {
    \   "name": "Info",
    \   "texthl": "ALEInfo",
    \   "signText": ".",
    \   "signTexthl": "ALEInfoSign",
    \   "virtualTexthl": "Todo",
    \ },
    \ 4: {
    \   "name": "Hint",
    \   "texthl": "ALEInfo",
    \   "signText": ".",
    \   "signTexthl": "ALEInfoSign",
    \   "virtualTexthl": "Todo",
    \ },
    \}
else
    let g:LanguageClient_autoStart = 0
    " lua vim.lsp.set_log_level('trace')

    highlight link LspDiagnosticsError ALEVirtualTextError
    highlight link LspDiagnosticsErrorSign ALEErrorSign
    highlight link LspDiagnosticsWarning ALEVirtualTextWarning
    highlight link LspDiagnosticsWarningSign ALEWarningSign
    highlight link LspDiagnosticsInformation ALEVirtualTextInfo
    highlight link LspDiagnosticsInformationSign ALEInfoSign
    highlight link LspDiagnosticsHint ALEVirtualTextInfo
    highlight link LspDiagnosticsHintSign ALEInfoSign

    " solarized8 doesn't support ALEVirtualText
    highlight link ALEVirtualTextError ALEError
    highlight link ALEVirtualTextWarning ALEWarning
    highlight link ALEVirtualTextInfo ALEInfo

    sign define LspDiagnosticsErrorSign text=• numhl=ALEErrorSignLineNr
    sign define LspDiagnosticsWarningSign text=• numhl=ALEWarningSignLineNr
    sign define LspDiagnosticsInformationSign text=. numhl=ALEInfoSignLineNr
    sign define LspDiagnosticsHintSign text=. numhl=ALEInfoSignLineNr


    lua << END
      require'nvim_lsp'.bashls.setup{}
      require'nvim_lsp'.gdscript.setup{}
      require'nvim_lsp'.clangd.setup{}
      require'nvim_lsp'.html.setup{}
      require'nvim_lsp'.jsonls.setup{}
      require'nvim_lsp'.pyls.setup{}
      require'nvim_lsp'.rust_analyzer.setup{}
      require'nvim_lsp'.tsserver.setup{
        filetypes = {"typescript", "typescriptreact", "typescript.tsx"};
      }
      require'nvim_lsp'.vimls.setup{}
      require'nvim_lsp'.yamlls.setup{}

      require'nvim_lsp'.flow.setup{
        cmd = {"flow", "lsp", "--lazy"};
        settings = {
          flow = {
            coverageSeverity = "warn";
            showUncovered = true;
            stopFlowOnExit = false;
            useBundledFlow = false;
          }
        }
      }
END
endif
