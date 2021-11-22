local aerial = require("aerial")

vim.g.aerial = {
  default_direction = "prefer_left",
  highlight_on_jump = 200,
  link_folds_to_tree = true,
  link_tree_to_folds = true,
  manage_folds = true,
  nerd_font = vim.g.nerd_font,

  lsp = {
    -- diagnostics_trigger_update = false,
  },
  -- filter_kind = {
  --   ["_"] = { "Class" },
  -- },
  backends = {
    ["_"] = { "treesitter", "lsp", "markdown" },
    -- ["_"] = { "lsp", "treesitter" },
  },
  -- open_automatic = true,
}

aerial.register_attach_cb(function(bufnr)
  local function map(mode, key, result)
    vim.api.nvim_buf_set_keymap(bufnr, mode, key, result, { noremap = true, silent = true })
  end
  map("n", "<leader>a", "<cmd>AerialToggle!<CR>")
  map("n", "{", "<cmd>AerialPrev<CR>")
  map("v", "{", "<cmd>AerialPrev<CR>")
  map("n", "}", "<cmd>AerialNext<CR>")
  map("v", "}", "<cmd>AerialNext<CR>")
  map("n", "[[", "<cmd>AerialPrevUp<CR>")
  map("v", "[[", "<cmd>AerialPrevUp<CR>")
  map("n", "]]", "<cmd>AerialNextUp<CR>")
  map("v", "]]", "<cmd>AerialNextUp<CR>")
end)
