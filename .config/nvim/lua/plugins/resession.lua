local visible_buffers = {}
return {
  "stevearc/resession.nvim",
  event = "VeryLazy",
  opts = {
    autosave = {
      enabled = true,
      notify = false,
    },
    -- tab_buf_filter = function(tabpage, bufnr)
    --   local dir = vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabpage))
    --   return vim.startswith(vim.api.nvim_buf_get_name(bufnr), dir)
    -- end,
    buf_filter = function(bufnr)
      if not require("resession").default_buf_filter(bufnr) then
        return false
      end
      return visible_buffers[bufnr] or require("three").is_buffer_in_any_tab(bufnr)
    end,
    extensions = { quickfix = {}, colorscheme = {} },
  },
  config = function(_, opts)
    local resession = require("resession")
    local aug = vim.api.nvim_create_augroup("StevearcResession", {})
    resession.setup(opts)

    resession.add_hook("pre_save", function()
      visible_buffers = {}
      for _, winid in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(winid) then
          visible_buffers[vim.api.nvim_win_get_buf(winid)] = winid
        end
      end
    end)

    vim.keymap.set("n", "<leader>ss", resession.save, { desc = "[S]ession [S]ave" })
    vim.keymap.set("n", "<leader>st", function() resession.save_tab() end, { desc = "[S]ession save [T]ab" })
    vim.keymap.set("n", "<leader>so", resession.load, { desc = "[S]ession [O]pen" })
    vim.keymap.set(
      "n",
      "<leader>sl",
      function() resession.load(nil, { reset = false }) end,
      { desc = "[S]ession [L]oad without reset" }
    )
    vim.keymap.set("n", "<leader>sd", resession.delete, { desc = "[S]ession [D]elete" })
    vim.api.nvim_create_user_command("SessionDetach", function() resession.detach() end, {})
    vim.keymap.set("n", "ZZ", function()
      vim.cmd("wa")
      resession.save("__quicksave__", { notify = false })
      vim.api.nvim_create_augroup("StevearcResession", {})
      vim.cmd("qa")
    end)

    if vim.fn.argc() == 0 and vim.tbl_contains(resession.list(), "__quicksave__") then
      vim.defer_fn(function()
        resession.load("__quicksave__", { attach = false })
        local ok, err = pcall(resession.delete, "__quicksave__")
        if not ok then
          vim.notify(string.format("Error deleting quicksave session: %s", err), vim.log.levels.WARN)
        end
      end, 50)
    end

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = aug,
      callback = function() resession.save("last") end,
    })
  end,
}
