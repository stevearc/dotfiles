return {
  "EdenEast/nightfox.nvim",
  priority = 1000,
  lazy = true,
  opts = {
    groups = {
      all = {
        -- Make and/or/not stand out more
        ["@keyword.operator"] = { link = "@keyword" },
        -- Make markdown links stand out
        ["@text.reference"] = { link = "@keyword" },
        ["@text.emphasis"] = { style = "italic" },
        ["@text.strong"] = { style = "bold" },
        ["@text.literal"] = { style = "" }, -- Don't italicize
        ["@codeblock"] = { bg = "palette.bg0" },
        ["@neorg.markup.strikethrough"] = { fg = "palette.comment", style = "strikethrough" },
      },
    },
  },
  config = true,
}
