require("compe").setup({
  enabled = true,
  autocomplete = true,
  debug = false,
  documentation = true,
  min_length = 1,
  source = {
    buffer = true,
    vsnip = true,
    nvim_lsp = true,
    nvim_lua = true,
    neorg = true,
  },
})
