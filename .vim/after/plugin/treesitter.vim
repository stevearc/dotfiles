lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = vim.g.treesitter_languages,
  highlight = {
    -- I found this caused lag in some files
    enable = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<leader>v",
      node_incremental = "<leader>v",
    },
  },
  indent = {
    -- This is causing problems in lua
    enable = false,
  },
}
EOF
