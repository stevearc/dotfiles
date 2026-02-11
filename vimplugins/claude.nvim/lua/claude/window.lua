local M = {}

---@return integer?
M.get_float_win = function()
  local c = require("claude").get_proc()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == c.bufnr then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        return win
      end
    end
  end
end

---@param bufnr integer
---@return integer
M.open_float = function(bufnr)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  return vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })
end

return M
