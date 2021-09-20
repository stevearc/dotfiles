vim.o.termguicolors = true
vim.o.background = "dark"

require("colorizer").setup()

if vim.g.nerd_font ~= false then
  require("nvim-web-devicons").setup({
    default = true,
  })
end

-- Tokyo Night
vim.g.tokyonight_style = "night"
vim.g.tokyonight_dark_float = false
vim.g.tokyonight_italic_comments = true
vim.g.tokyonight_italic_keywords = false
vim.g.tokyonight_sidebars = { "qf", "aerial", "terminal" }

vim.cmd("colorscheme tokyonight")
