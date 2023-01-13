return {
  "EdenEast/nightfox.nvim",
  priority = 1000,
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
      },
    },
  },
  config = function(_, opts)
    require("nightfox").setup(opts)
    vim.cmd.colorscheme({ args = { "duskfox" } })
  end,
}
