vim.diagnostic.config({
  float = {
    source = "always",
    border = "rounded",
    severity_sort = true,
  },
  virtual_text = {
    severity = { min = vim.diagnostic.severity.W },
    source = "if_many",
  },
  severity_sort = true,
})

if vim.g.nerd_font then
  vim.cmd([[
      sign define DiagnosticSignError text=󰅚   numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=󰀪  numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInfo text=• texthl=DiagnosticSignInfo
      sign define DiagnosticSignHint text=• texthl=DiagnosticSignHint
    ]])
else
  vim.cmd([[
      sign define DiagnosticSignError text=• numhl=DiagnosticSignError texthl=DiagnosticSignError
      sign define DiagnosticSignWarn text=• numhl=DiagnosticSignWarn texthl=DiagnosticSignWarn
      sign define DiagnosticSignInfo text=. texthl=DiagnosticSignInfo
      sign define DiagnosticSignHint text=. texthl=DiagnosticSignHint
    ]])
end

vim.keymap.set("n", "[d", function()
  vim.diagnostic.goto_prev({ severity = { min = vim.diagnostic.severity.WARN } })
end)
vim.keymap.set("n", "]d", function()
  vim.diagnostic.goto_next({ severity = { min = vim.diagnostic.severity.WARN } })
end)
