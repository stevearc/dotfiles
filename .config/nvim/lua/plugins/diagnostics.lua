vim.diagnostic.config({
  float = {
    source = "always",
  },
  virtual_text = {
    severity = { min = vim.diagnostic.severity.W },
    source = "if_many",
  },
  severity_sort = true,
})

if vim.g.nerd_font then
  vim.cmd([[
      sign define DiagnosticSignError text=   numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=  numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=• numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=• numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
else
  vim.cmd([[
      sign define DiagnosticSignError text=• numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=• numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInformation text=. numhl=DiagnosticSignInformation texthl=DiagnosticSignInformation
      sign define DiagnosticSignHint text=. numhl=DiagnosticSignHint texthl=DiagnosticSignHint
    ]])
end
return {}
