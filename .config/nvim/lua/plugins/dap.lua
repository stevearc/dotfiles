return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "leoluz/nvim-dap-go", config = true },
      "rcarriga/nvim-dap-ui",
      { "theHamsta/nvim-dap-virtual-text", config = true },
      { "stevearc/overseer.nvim" },
    },
    keys = {
      { "<leader>dc", "<cmd>lua require'dap'.continue()<CR>", mode = "n", desc = "[D]ebug [C]ontinue" },
      { "<leader>dj", "<cmd>lua require'dap'.step_over()<CR>", mode = "n", desc = "[D]ebug step over" },
      { "<leader>di", "<cmd>lua require'dap'.step_into()<CR>", mode = "n", desc = "[D]ebug step [I]nto" },
      { "<leader>do", "<cmd>lua require'dap'.step_out()<CR>", mode = "n", desc = "[D]ebug step [O]ut" },
      { "<leader>dl", "<cmd>lua require'dap'.run_last()<CR>", mode = "n", desc = "[D]ebug run [L]ast" },
      { "<leader>dr", "<cmd>lua require'dap'.repl.open()<CR>", mode = "n", desc = "[D]ebug open [R]epl" },
      { "<leader>dq", "<cmd>lua require'dap'.terminate()<CR>", mode = "n", desc = "[D]ebug [Q]uit" },
      { "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", mode = "n", desc = "[D]ebug set [B]reakpoint" },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition" }, function(cond)
            if cond then
              require("dap").set_breakpoint(cond)
            end
          end)
        end,
        mode = "n",
        desc = "[D]ebug set conditional [B]reakpoint",
      },
    },
    config = function()
      -- dap.set_log_level("DEBUG")
      vim.fn.sign_define("DapBreakpoint", { text = "•", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "?", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "⁋", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = " ", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "X", texthl = "DiagnosticError", linehl = "", numhl = "" })

      local dapui = require("dapui")
      local dap = require("dap")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      require("overseer").enable_dap(true)
      require("dap.ext.vscode").load_launchjs(nil, { node = { "typescript", "javascript" } })
    end,
  },
}
