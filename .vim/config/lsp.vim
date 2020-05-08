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

    sign define LspDiagnosticsErrorSign text=•
    sign define LspDiagnosticsWarningSign text=•
    sign define LspDiagnosticsInformationSign text=.
    sign define LspDiagnosticsHintSign text=.
endif
