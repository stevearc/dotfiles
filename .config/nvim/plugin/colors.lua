local stevearc = require("stevearc")
vim.opt.termguicolors = true
vim.opt.background = "dark"

require("colorizer").setup()

if vim.g.nerd_font ~= false then
  require("nvim-web-devicons").setup({
    default = true,
  })
end

-- Tokyo Night
function stevearc.tokyonight()
  local config = require("tokyonight.config")
  local c = require("tokyonight.colors").setup(config)
  local util = require("tokyonight.util")
  util.highlight("BufferTabpage", { bg = c.bg_statusline, fg = c.blue })
  util.highlight("BufferTabpageFill", { bg = c.bg_statusline, fg = c.none })
  -- I HATE undercurls
  util.highlight("DiagnosticUnderlineError", { style = "underline", sp = c.error })
  util.highlight("DiagnosticUnderlineWarn", { style = "underline", sp = c.warn })
  util.highlight("DiagnosticUnderlineInfo", { style = "underline", sp = c.info })
  util.highlight("DiagnosticUnderlineHint", { style = "underline", sp = c.hint })
  util.highlight("SpellBad", { sp = c.error, style = "underline" })
  util.highlight("SpellCap", { sp = c.warning, style = "underline" })
  util.highlight("SpellLocal", { sp = c.info, style = "underline" })
  util.highlight("SpellRare", { sp = c.hint, style = "underline" })
end
vim.g.tokyonight_style = "night"
vim.g.tokyonight_dark_float = false
vim.g.tokyonight_italic_comments = true
vim.g.tokyonight_italic_keywords = false
vim.g.tokyonight_sidebars = { "qf", "aerial", "terminal" }

vim.cmd([[autocmd ColorScheme tokyonight lua require'stevearc'.tokyonight()]])

if os.getenv("XDG_SESSION_TYPE") == "tty" then
  vim.opt.termguicolors = false
  vim.cmd("colorscheme darkblue")
else
  vim.cmd("colorscheme tokyonight")
end
