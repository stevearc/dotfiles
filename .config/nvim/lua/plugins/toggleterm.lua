return {
  "akinsho/toggleterm.nvim",
  enabled = false,
  keys = {
    { "<C-t>", '<Cmd>exe v:count1 . "ToggleTerm"<CR>' },
    { "<C-t>", '<Cmd>exe v:count1 . "ToggleTerm"<CR>', mode = "t" },
  },
  opts = {},
}
