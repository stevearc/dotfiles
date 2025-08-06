local mc = setmetatable({}, {
  __index = function(_, key)
    return function(...) return require("multicursor-nvim")[key](...) end
  end,
})
return {
  "jake-stewart/multicursor.nvim",

  keys = {
    { "<leader>jj", mc.toggleCursor, desc = "toggle cursor" },
    { "<leader>jd", mc.duplicateCursors, desc = "duplicate cursors and disable the originals" },
    { "<leader>jr", mc.restoreCursors, desc = "restore deleted cursors" },
    { "<leader>ja", mc.alignCursors, desc = "align cursor columns" },
    { "<leader>je", mc.enableCursors, desc = "enable cursors" },
    { "<leader>jx", mc.disableCursors, desc = "disable cursors" },
    { "<leader>j/", mc.searchAllAddCursors, desc = "add cursor to all search results" },
    {
      "<leader>jn",
      function()
        mc.addCursor()
        vim.cmd.normal({ args = { "n" } })
      end,
      desc = "add cursor and go to next match",
    },
    -- Append/insert for each line of visual selections.
    { "I", mc.insertVisual, mode = "v", desc = "Insert at the beginning of visual selection" },
    { "A", mc.appendVisual, mode = "v", desc = "Append to each line of visual selection" },
    {
      "<leader>jj",
      function() mc.matchCursors("[^[:space:]].*$") end,
      mode = "v",
      desc = "Add cursor to each non-blank line in visual selection",
    },
    {
      "<leader>jm",
      mc.matchCursors,
      mode = "v",
      desc = "Add cursor by matching regex in visual selection",
    },
    { "<leader>js", mc.splitCursors, mode = "v", desc = "Split visual selections by regex" },
  },

  config = function()
    mc = require("multicursor-nvim")
    mc.setup()

    -- Jumplist support
    vim.keymap.set({ "v", "n" }, "<c-i>", mc.jumpForward)
    vim.keymap.set({ "v", "n" }, "<c-o>", mc.jumpBackward)

    vim.keymap.set("n", "<esc>", function()
      if not mc.cursorsEnabled() then
        mc.addCursor()
        mc.enableCursors()
      else
        -- Default <esc> handler.
      end
    end)

    vim.keymap.set("n", "<C-c>", function()
      if mc.hasCursors() then
        mc.clearCursors()
      else
        -- Default <C-c> handler.
      end
    end)
  end,
}
