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
if vim.fn.has("nvim-0.10") == 0 then
  for _, lvl in ipairs({ "Error", "Warn", "Info", "Hint" }) do
    local hl = "DiagnosticSign" .. lvl
    local highlight_lnum = lvl == "Error" or lvl == "Warn"
    vim.fn.sign_define(hl, { text = icons[lvl], texthl = hl, linehl = "", numhl = highlight_lnum and hl or "" })
  end
end

vim.diagnostic.config({
  float = {
    source = true,
    border = "rounded",
    severity_sort = true,
  },
  virtual_text = {
    severity = { min = vim.diagnostic.severity.W },
    source = "if_many",
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
