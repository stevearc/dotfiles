" Configuration for LSP

" lua vim.lsp.set_log_level('trace')

if g:nerd_font
  sign define LspDiagnosticsSignError text=  numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError
  sign define LspDiagnosticsSignWarning text=  numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning
  sign define LspDiagnosticsSignInformation text=• numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation
  sign define LspDiagnosticsSignHint text=• numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint
else
  sign define LspDiagnosticsSignError text=• numhl=LspDiagnosticsSignError texthl=LspDiagnosticsSignError
  sign define LspDiagnosticsSignWarning text=• numhl=LspDiagnosticsSignWarning texthl=LspDiagnosticsSignWarning
  sign define LspDiagnosticsSignInformation text=. numhl=LspDiagnosticsSignInformation texthl=LspDiagnosticsSignInformation
  sign define LspDiagnosticsSignHint text=. numhl=LspDiagnosticsSignHint texthl=LspDiagnosticsSignHint
endif
