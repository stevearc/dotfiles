return {
  {
    "stefandtw/quickfix-reflector.vim",
    event = "QuickFixCmdPost *",
  },
  {
    "stevearc/qf_helper.nvim",
    cmd = { "Cclear", "Lclear" },
    keys = {
      { "<C-N>", "<cmd>QNext<CR>", mode = "n" },
      { "<C-P>", "<cmd>QPrev<CR>", mode = "n" },
      { "<leader>q", "<cmd>QFToggle!<CR>", mode = "n" },
      { "<leader>l", "<cmd>LLToggle!<CR>", mode = "n" },
    },
    config = function()
      vim.cmd([[
command! -bar Cclear call setqflist([])
command! -bar Lclear call setloclist(0, [])
]])
      require("qf_helper").setup()
    end,
  },
}
