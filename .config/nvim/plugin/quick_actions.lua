local p = require("p")

p.require("quick_action", function(quick_action)
  quick_action.set_keymap("n", "<CR>", "menu")
  quick_action.add("menu", {
    name = "Show diagnostics",
    condition = function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
      return not vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum }))
    end,
    action = function()
      vim.diagnostic.open_float(0, { scope = "line", border = "rounded" })
    end,
  })
end)
