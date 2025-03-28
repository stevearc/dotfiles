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

if vim.fn.has("nvim-0.11") == 1 then
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
else
  vim.diagnostic.config({
    float = {
      source = true,
      border = "rounded",
      severity_sort = true,
    },
    virtual_text = {
      severity = { min = vim.diagnostic.severity.W },
    },
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

  vim.keymap.set(
    "n",
    "[d",
    function() vim.diagnostic.goto_prev({ severity = { min = vim.diagnostic.severity.WARN } }) end
  )
  vim.keymap.set(
    "n",
    "]d",
    function() vim.diagnostic.goto_next({ severity = { min = vim.diagnostic.severity.WARN } }) end
  )
end
