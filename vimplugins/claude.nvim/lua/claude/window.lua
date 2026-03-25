local M = {}

---@return integer width, integer height, integer col, integer row
local function get_float_dimensions()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  return width, height, col, row
end

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
  local width, height, col, row = get_float_dimensions()

  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("ClaudeFloatResize", {}),
    callback = function()
      if not vim.api.nvim_win_is_valid(winid) then
        return true
      end
      local w, h, c, r = get_float_dimensions()
      vim.api.nvim_win_set_config(winid, {
        relative = "editor",
        width = w,
        height = h,
        col = c,
        row = r,
      })
    end,
  })

  return winid
end

return M
