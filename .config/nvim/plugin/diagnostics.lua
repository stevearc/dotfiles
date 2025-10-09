local icons = vim.g.nerd_font and {
  Error = "󰅚 ",
  Warn = "󰀪 ",
  Info = "•",
  Hint = "•",
} or {
  Error = "•",
  Warn = "•",
  Info = ".",
  Hint = ".",
}
vim.diagnostic.config({
  float = {
    source = true,
    severity_sort = true,
  },
  jump = {
    severity = { min = vim.diagnostic.severity.W },
  },
  virtual_text = {
    severity = { min = vim.diagnostic.severity.W },
  },
  underline = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.Error,
      [vim.diagnostic.severity.WARN] = icons.Warn,
      [vim.diagnostic.severity.INFO] = icons.Info,
      [vim.diagnostic.severity.HINT] = icons.Hint,
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
      [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
    },
  },
})

vim.api.nvim_create_user_command(
  "Diagnostics",
  function() vim.diagnostic.setqflist({ severity = { min = vim.diagnostic.severity.W } }) end,
  { desc = "Show all diagnostics in the quickfix" }
)

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = vim.api.nvim_create_augroup("StevearcDiagnostics", {}),
  callback = function()
    local qflist = vim.fn.getqflist({ title = 1 })
    if qflist.title == "Diagnostics" then
      vim.diagnostic.setqflist({ open = false, severity = { min = vim.diagnostic.severity.W } })
    end
  end,
})
