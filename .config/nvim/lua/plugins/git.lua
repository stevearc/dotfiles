vim.keymap.set("n", "<leader>gt", function()
  require("gitterm").toggle()
end, { desc = "[G]it [T]erminal interface" })

return {
  "tpope/vim-fugitive",
  dependencies = { "tpope/vim-rhubarb" },
  cmd = { "GitHistory", "Git", "GBrowse" },
  keys = {
    { "<leader>gh", "<cmd>GitHistory<CR>", { mode = "n", desc = "[G]it [H]istory" } },
    { "<leader>gb", "<cmd>Git blame<CR>", { mode = "n", desc = "[G]it [B]lame" } },
    { "<leader>gc", "<cmd>GBrowse!<CR>", { mode = "n", desc = "[G]it [C]opy link" } },
    { "<leader>gc", ":GBrowse!<CR>", { mode = "v", desc = "[G]it [C]opy link" } },
  },
  config = function()
    vim.cmd("command! GitHistory Git! log -- %")
  end,
}
