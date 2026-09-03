vim.keymap.set(
  "v",
  "gQ",
  ":g/[^[:space:]].*$/norm Q<CR>",
  { desc = "Add cursor to each non-blank line in visual selection" }
)

local mc = setmetatable({}, {
  __index = function(_, key)
    return function(...) return require("multicursor-nvim")[key](...) end
  end,
})
return {
  "jake-stewart/multicursor.nvim",
  enabled = vim.fn.has("nvim-0.13") == 0,

  keys = {
    {
      "Q",
      function()
        if vim.v.count == 0 then
          mc.toggleCursor()
        else
          mc.searchAllAddCursors()
        end
      end,
      desc = "toggle cursor (with count: add at all search matches)",
    },
    { "Q", mc.visualToCursors, mode = "v", desc = "place a cursor at each line of the visual selection" },
    { "gQ", mc.restoreCursors, desc = "restore deleted cursors" },
    {
      "q=",
      function()
        if vim.v.count == 1 or (vim.v.count == 0 and not mc.cursorsEnabled()) then
          mc.enableCursors()
        elseif vim.v.count == 2 or vim.v.count == 0 then
          mc.disableCursors()
        end
      end,
      desc = "toggle cursor following (1: enable, 2: disable)",
    },
  },

  config = function()
    mc = require("multicursor-nvim")
    mc.setup()

    vim.keymap.set("n", "<C-l>", function()
      if mc.hasCursors() then
        mc.clearCursors()
      else
        -- Default <C-l> handler.
      end
    end)
  end,
}
