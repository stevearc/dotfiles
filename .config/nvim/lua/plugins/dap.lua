local p = require("p")
return function(dap)
  p.load("nvim-dap-go")
  p.load("nvim-dap-ui")
  p.load("nvim-dap-virtual-text")
  -- dap.set_log_level("DEBUG")
  vim.keymap.set("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<CR>")
  vim.keymap.set("n", "<leader>dB", function()
    vim.ui.input({ prompt = "Breakpoint condition" }, function(cond)
      if cond then
        dap.set_breakpoint(cond)
      end
    end)
  end)

  vim.fn.sign_define("DapBreakpoint", { text = "•", texthl = "DiagnosticError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "*", texthl = "DiagnosticError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapLogPoint", { text = "⁋", texthl = "", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "→", texthl = "", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointRejected", { text = "🛑", texthl = "", linehl = "", numhl = "" })
  p.require("dapui", function(dapui)
    dapui.setup()
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end)
  p.require("dap-go").setup()
  p.require("nvim-dap-virtual-text").setup()
  require("dap.ext.vscode").load_launchjs()
end
