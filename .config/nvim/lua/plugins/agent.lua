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
    opts = {
      on_create = function(proc)
        local window = require("claude.window")
        local bufnr = proc.bufnr

        vim.keymap.set("t", "<C-i>", function() vim.cmd.close() end, { buffer = bufnr })

        if Snacks then
          vim.keymap.set("t", "@", function()
            vim.api.nvim_win_close(0, true)
            Snacks.picker.buffers({
              layout = { preview = false },
              on_close = function()
                window.open_float(bufnr)
                vim.api.nvim_feedkeys("i", "n", true)
              end,
              confirm = function(picker, item)
                picker:close()
                if item and item.file then
                  local filename = item.file
                  local cwd = vim.fn.getcwd()
                  if vim.startswith(filename, cwd) then
                    filename = filename:sub(cwd:len() + 2)
                  end
                  proc:send_text("@" .. filename .. " ")
                end
              end,
            })
          end, { buffer = bufnr })
        end
      end,
    },
  },
}
