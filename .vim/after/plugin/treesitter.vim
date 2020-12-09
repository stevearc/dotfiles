lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = vim.g.treesitter_languages,
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
    disable = {"lua"}
  },
}
EOF
