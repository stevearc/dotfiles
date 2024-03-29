return {
  "folke/tokyonight.nvim",
  lazy = true,
  priority = 1000,
  opts = {
    style = "night",
    styles = {
      comments = { italic = false },
      keywords = { italic = false },
      floats = "normal",
    },
    sidebars = { "qf", "help", "terminal", "dagger", "aerial", "OverseerList", "neotest-summary" },
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
  },
  config = true,
}
