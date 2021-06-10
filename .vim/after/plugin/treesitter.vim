lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = vim.g.treesitter_languages,
  highlight = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<leader>v",
      node_incremental = "<leader>v",
    },
  },
  indent = {
    enable = true,
  },
}
EOF
