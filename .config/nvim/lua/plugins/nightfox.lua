return {
  "EdenEast/nightfox.nvim",
  priority = 1000,
  lazy = true,
  opts = {
    groups = {
      all = {
        ["@markup.italic"] = { style = "italic" },
        -- Make and/or/not stand out more
        ["@keyword.operator"] = { link = "@keyword" },
        -- -- Make markdown links stand out
        ["@text.reference"] = { link = "@keyword" },
        ["@text.literal"] = { style = "" }, -- Don't italicize
        ["@codeblock"] = { bg = "palette.bg0" },
        ["QuickFixLine"] = { bg = "palette.sel1" },
      },
    },
  },
}
