local p = require("p")

p.require("quick_action", function(quick_action)
  quick_action.set_keymap("n", "<CR>", "menu")
  quick_action.add("menu", {
    name = "Show diagnostics",
    condition = function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
      return not vim.tbl_isempty(
        vim.diagnostic.get(0, { lnum = lnum, severity = { min = vim.diagnostic.severity.WARN } })
      )
    end,
    action = function()
      vim.diagnostic.open_float(0, { scope = "line", border = "rounded" })
    end,
  })

  quick_action.add("menu", {
    name = "Pick color",
    condition = function()
      local pickers = require("ccc.config").get("pickers")
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lnum = cursor[1]
      local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
      local parse_col = 1
      while true do
        local start, end_, RGB
        for _, picker in ipairs(pickers) do
          local s_, e_, rgb = picker:parse_color(line, parse_col)
          if s_ and s_ <= cursor[2] + 1 and e_ and e_ >= cursor[2] + 1 then
            return true
          elseif s_ and (start == nil or s_ < start) then
            start = s_
            end_ = e_
            RGB = rgb
          end
        end
        if RGB == nil then
          break
        end
        parse_col = end_ + 1
      end
      return false
    end,
    action = function()
      vim.cmd("CccPick")
    end,
  })
end)

return {}
