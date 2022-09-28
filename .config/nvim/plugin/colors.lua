vim.opt.background = "dark"

local group = vim.api.nvim_create_augroup("StevearcColors", {})

-- Tokyo Night
vim.api.nvim_create_autocmd("ColorScheme", {
  desc = "Custom Tokyo Night settings",
  pattern = "tokyonight",
  group = group,
  callback = function()
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
    util.highlight("NotifyERRORBorder", { fg = util.darken(c.error, 0.8) })
    util.highlight("NotifyWARNBorder", { fg = util.darken(c.warning, 0.8) })
    util.highlight("NotifyINFOBorder", { fg = util.darken(c.green, 0.8) })
    util.highlight("NotifyDEBUGBorder", { fg = util.darken(c.info, 0.8) })
    util.highlight("NotifyTRACEBorder", { fg = util.darken(c.info, 0.8) })

    util.highlight("NotifyERRORTitle", { fg = c.error })
    util.highlight("NotifyWARNTitle", { fg = c.warn })
    util.highlight("NotifyINFOTitle", { fg = c.green })
    util.highlight("NotifyDEBUGTitle", { fg = c.info })
    util.highlight("NotifyTRACETitle", { fg = c.info })

    util.highlight("NotifyERRORIcon", { fg = c.error })
    util.highlight("NotifyWARNIcon", { fg = c.warn })
    util.highlight("NotifyINFOIcon", { fg = c.green })
    util.highlight("NotifyDEBUGIcon", { fg = c.info })
    util.highlight("NotifyTRACEIcon", { fg = c.info })
    vim.cmd([[highlight link AerialLineNC LspReferenceText]])
    vim.cmd([[highlight link OverseerOutput NormalSB]])
  end,
})
vim.g.tokyonight_style = "night"
vim.g.tokyonight_dark_float = false
vim.g.tokyonight_italic_comments = true
vim.g.tokyonight_italic_keywords = false
vim.g.tokyonight_sidebars = { "qf", "aerial", "terminal" }

local is_tty = os.getenv("XDG_SESSION_TYPE") == "tty" and os.getenv("SSH_TTY") == ""
local colorscheme_set = false
if is_tty then
  vim.opt.termguicolors = false
  vim.cmd("colorscheme darkblue")
else
  vim.opt.termguicolors = true
  safe_require("nightfox", function(nightfox)
    nightfox.setup({
      groups = {
        all = {
          -- Make and/or/not stand out more
          TSKeywordOperator = { link = "TSKeyword" },
          -- The default barbar colors make these impossible to read
          BufferInactiveMod = { link = "BufferVisibleMod" },
          BufferTabpage = { link = "Keyword" },
        },
      },
    })
    vim.cmd("colorscheme duskfox")
    colorscheme_set = true
  end)

  if not colorscheme_set then
    safe_require("tokyonight", function()
      vim.cmd("colorscheme tokyonight")
      colorscheme_set = true
    end)
  end
  safe_require("colorizer").setup()
end
