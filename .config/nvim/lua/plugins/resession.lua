local lazy = require("lazy")
lazy.require("resession", function(resession)
  local aug = vim.api.nvim_create_augroup("StevearcResession", {})
  resession.setup({
    autosave = {
      enabled = true,
      notify = false,
    },
    tab_buf_filter = function(tabpage, bufnr)
      local dir = vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabpage))
      return vim.startswith(vim.api.nvim_buf_get_name(bufnr), dir)
    end,
    extensions = { aerial = {}, overseer = {}, quickfix = {}, three = {}, config_local = {} },
  })
  vim.keymap.set("n", "<leader>ss", resession.save, { desc = "[S]ession [S]ave" })
  vim.keymap.set("n", "<leader>st", function()
    resession.save_tab()
  end, { desc = "[S]ession save [T]ab" })
  vim.keymap.set("n", "<leader>so", resession.load, { desc = "[S]ession [O]pen" })
  vim.keymap.set("n", "<leader>sl", function()
    resession.load(nil, { reset = false })
  end, { desc = "[S]ession [L]oad without reset" })
  vim.keymap.set("n", "<leader>sd", resession.delete, { desc = "[S]ession [D]elete" })
  vim.api.nvim_create_user_command("SessionDetach", function()
    resession.detach()
  end, {})
  vim.keymap.set("n", "ZZ", function()
    resession.save("__quicksave__", { notify = false })
    vim.cmd("wa")
    vim.cmd("qa")
  end)

  vim.api.nvim_create_autocmd("VimEnter", {
    group = aug,
    callback = function()
      if vim.tbl_contains(resession.list(), "__quicksave__") then
        vim.defer_fn(function()
          resession.load("__quicksave__", { attach = false })
          local ok, err = pcall(resession.delete, "__quicksave__")
          if not ok then
            vim.notify(string.format("Error deleting quicksave session: %s", err), vim.log.levels.WARN)
          end
        end, 50)
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      resession.save("last")
    end,
  })
end)