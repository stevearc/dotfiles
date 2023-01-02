vim.opt.background = "dark"

local priority = {
  { mod = "nightfox", name = "duskfox" },
  {
    mod = "tokyonight",
  },
}

local colorschemes = {
  nightfox = function(nightfox)
    nightfox.setup({
      groups = {
        all = {
          -- Make and/or/not stand out more
          ["@keyword.operator"] = { link = "@keyword" },
          -- Make markdown links stand out
          ["@text.reference"] = { link = "@keyword" },
          ["@text.emphasis"] = { style = "italic" },
          ["@text.strong"] = { style = "bold" },
          ["@text.literal"] = { style = "" }, -- Don't italicize
        },
      },
    })
  end,
  tokyonight = function(tokyonight)
    tokyonight.setup({
      style = "night",
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        floats = "normal",
      },
      sidebars = vim.list_extend({ "qf", "help", "terminal" }, vim.g.sidebar_filetypes),
      on_highlights = function(highlights, c)
        for _, defn in pairs(highlights) do
          if defn.undercurl then
            defn.undercurl = false
            defn.underline = true
          end
        end
        highlights.AerialLineNC = { link = "LspReferenceText" }
        highlights.OverseerOutput = { link = "NormalSB" }
        highlights.TabLine = { fg = c.comment, bg = c.bg_statusline }
        highlights.TabLineSel = { fg = c.bg, bg = c.blue }
        highlights.TabLineModifiedSel = { fg = c.bg, bg = c.warning }
        highlights.TabLineIndexSel = { fg = c.bg, bg = c.blue, bold = true }
        highlights.TabLineIndexModifiedSel = { fg = c.bg, bg = c.warning, bold = true }
        highlights.TabLineDivider = { fg = c.blue }
        highlights.TabLineDividerSel = { fg = c.blue, bg = c.blue }
        highlights.TabLineDividerVisible = { fg = c.blue }
        highlights.TabLineDividerModifiedSel = { fg = c.warning, bg = c.warning }
      end,
    })
  end,
}

local is_tty = os.getenv("XDG_SESSION_TYPE") == "tty" and os.getenv("SSH_TTY") == ""
if is_tty then
  vim.opt.termguicolors = false
  vim.cmd("colorscheme darkblue")
else
  vim.opt.termguicolors = true

  local chosen
  for _, config in ipairs(priority) do
    local ok, mod = pcall(require, config.mod)
    if ok then
      colorschemes[config.mod](mod)
      if not chosen then
        chosen = config.name or config.mod
      end
    end
  end
  if chosen then
    vim.cmd(string.format("colorscheme %s", chosen))
  end
end
