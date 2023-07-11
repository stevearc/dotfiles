return {
  "stevearc/conjoin.nvim",
  cond = vim.fn.executable("conjoin") == 1
    and vim.fn.isdirectory(vim.fn.expand("~/dotfiles/vimplugins/conjoin.nvim")) == 1,
  opts = {},
}
