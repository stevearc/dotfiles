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
      vim.fn.sign_define("DapBreakpoint", { text = " ", texthl = "Special", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = " ", texthl = "Special", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "⁋ ", texthl = "Special", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = " ", texthl = "Special", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "X", texthl = "DiagnosticError", linehl = "", numhl = "" })

      local dapui = require("dapui")
      local dap = require("dap")
      -- dap.set_log_level("DEBUG")
      dapui.setup({
        layouts = {
          {
            elements = {
              -- Provide IDs as strings or tables with "id" and "size" keys
              {
                id = "scopes",
                size = 0.25,
              },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              "repl",
              -- TODO need to figure out how to make this play nice with window resizing
              -- "console",
            },
            size = 10,
            position = "bottom",
          },
        },
      })
      local function close()
        dapui.close()
        require("nvim-dap-virtual-text").refresh()
      end
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = close
      dap.listeners.before.event_exited["dapui_config"] = close
      dap.listeners.on_session["dapui_config"] = function(_, new_session)
        if not new_session then
          close()
        end
      end

      require("overseer").enable_dap(true)
    end,
  },
}
