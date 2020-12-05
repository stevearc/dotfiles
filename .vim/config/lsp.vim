" Configuration for LSP

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
