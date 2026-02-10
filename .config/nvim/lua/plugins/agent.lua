return {
  {
    "stevearc/claude.nvim",
    lazy = true,
    keys = {
      { "<leader>ii", function() require("claude").run_action() end, desc = "Select and run claude action" },
      {
        "<leader>iw",
        function() require("claude").run_action("toggle_float") end,
        desc = "Open claude buffer in a floating window",
      },
      {
        "<leader>if",
        function() require("claude").run_action("autofill") end,
        mode = { "n", "v" },
        desc = "Auto implement some code",
      },
      {
        "<leader>ic",
        function() require("claude").run_action("send_location") end,
        mode = { "n", "v" },
        desc = "Send cursor location to claude",
      },
      { "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:~")) end, desc = "[Y]ank [F]ilename" },
    },
    opts = {},
  },
}
