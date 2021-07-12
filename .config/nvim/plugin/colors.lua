local stevearc = require("stevearc")
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
vim.g.tokyonight_italic_comments = true
vim.g.tokyonight_italic_keywords = false
vim.g.tokyonight_sidebars = { "qf", "aerial", "terminal" }

function stevearc:tokyonight()
  local config = require("tokyonight.config")
  local colors = require("tokyonight.colors").setup(config)
  local util = require("tokyonight.util")
  local barbar_theme = {
    Current = {
      base = { bg = colors.fg_gutter, fg = colors.fg },
      Index = { bg = colors.fg_gutter, fg = colors.blue1 },
      Mod = { bg = colors.fg_gutter, fg = colors.warning },
      Sign = { bg = colors.fg_gutter, fg = colors.blue1 },
      Target = { bg = colors.fg_gutter, fg = colors.red },
    },
    Visible = {
      base = { bg = colors.none, fg = colors.fg },
      Index = { bg = colors.none, fg = colors.blue1 },
      Mod = { bg = colors.none, fg = colors.warning },
      Sign = { bg = colors.none, fg = colors.blue1 },
      Target = { bg = colors.none, fg = colors.red },
    },
    Inactive = {
      base = { bg = colors.none, fg = colors.dark5 },
      Index = { bg = colors.none, fg = colors.dark5 },
      Mod = { bg = colors.none, fg = util.darken(colors.warning, 0.7) },
      Sign = { bg = colors.none, fg = colors.border_highlight },
      Target = { bg = colors.none, fg = colors.red },
    },
    Tabpages = {
      base = { bg = colors.none, fg = colors.none },
    },
    Tabpage = {
      Fill = { bg = colors.none, fg = colors.border_highlight },
    },
  }
  for mode, pieces in pairs(barbar_theme) do
    for piece, hl in pairs(pieces) do
      local group = string.format("Buffer%s%s", mode, piece == "base" and "" or piece)
      util.highlight(group, hl)
    end
  end
end

-- Solarized
vim.g.solarized_extra_hi_groups = true
vim.g.solarized_statusline = "flat"

function stevearc:solarized8()
  -- solarized8 is missing some colors for LSP
  vim.cmd([[hi link LspDiagnosticsDefaultError ALEError]])
  vim.cmd([[hi link LspDiagnosticsSignError ALEErrorSign]])
  vim.cmd([[hi link LspDiagnosticsDefaultWarning ALEWarning]])
  vim.cmd([[hi link LspDiagnosticsSignWarning ALEWarningSign]])
  vim.cmd([[hi link LspDiagnosticsDefaultInformation ALEInfo]])
  vim.cmd([[hi link LspDiagnosticsSignInformation ALEInfoSign]])
  vim.cmd([[hi link LspDiagnosticsDefaultHint ALEInfo]])
  vim.cmd([[hi link LspDiagnosticsSignHint ALEInfoSign]])

  vim.cmd([[hi JustUnderline gui=undercurl cterm=undercurl]])
  vim.cmd([[hi link LspDiagnosticsUnderlineError JustUnderline]])
  vim.cmd([[hi link LspDiagnosticsUnderlineWarning JustUnderline]])
  vim.cmd([[hi link LspDiagnosticsUnderlineInformation JustUnderline]])
  vim.cmd([[hi link LspDiagnosticsUnderlineHint JustUnderline]])

  -- I don't like the underlined virtual text
  vim.cmd([[hi ALEError gui=NONE cterm=NONE]])
  vim.cmd([[hi ALEInfo gui=NONE cterm=NONE]])
  vim.cmd([[hi ALEWarning gui=NONE cterm=NONE]])
end

vim.cmd([[autocmd ColorScheme tokyonight lua require'stevearc'.tokyonight()]])
vim.cmd([[autocmd ColorScheme solarized8 lua require'stevearc'.solarized8()]])

vim.cmd("colorscheme tokyonight")
