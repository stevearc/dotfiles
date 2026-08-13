return {
  {
    "stevearc/agents.nvim",
    lazy = true,
    keys = {
      { "<leader>ii", function() require("agents").run_action() end, desc = "Select and run agent action" },
      {
        "<leader>iw",
        function() require("agents").run_action("toggle_float") end,
        desc = "Open agent buffer in a floating window",
      },
      {
        "<leader>if",
        function() require("agents").run_action("autofill") end,
        mode = { "n", "v" },
        desc = "Auto implement some code",
      },
      {
        "<leader>ic",
        function() require("agents").run_action("send_location") end,
        mode = { "n", "v" },
        desc = "Send cursor location to agent",
      },
      {
        "<leader>ia",
        function() require("agents").comment_add() end,
        mode = { "n", "v" },
        desc = "Add review comment",
      },
      { "<leader>iA", function() require("agents").review_edit() end, desc = "Edit review summary" },
      { "<leader>ie", function() require("agents").comment_edit() end, desc = "Edit review comment" },
      { "<leader>id", function() require("agents").comment_delete() end, desc = "Delete review comment" },
      { "<leader>in", function() require("agents").comment_next() end, desc = "Next review comment" },
      { "<leader>ip", function() require("agents").comment_prev() end, desc = "Previous review comment" },
      { "<leader>iy", function() require("agents").comments_yank() end, desc = "Yank review comments" },
      { "<leader>ir", function() require("agents").comments_send() end, desc = "Send review comments" },
      { "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:~")) end, desc = "[Y]ank [F]ilename" },
    },
    opts = {
      on_create = function(proc)
        local window = require("agents.window")
        local bufnr = proc.bufnr

        vim.keymap.set("t", "<C-i>", function() vim.cmd.close() end, { buffer = bufnr })

        if Snacks then
          vim.keymap.set("t", "<C-f>", function()
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
