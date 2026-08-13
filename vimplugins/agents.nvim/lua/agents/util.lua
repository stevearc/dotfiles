local M = {}

M.leave_visual_mode = function()
  local mode = vim.api.nvim_get_mode().mode
  if vim.startswith(string.lower(mode), "v") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  end
end

---Get the start and end line numbers from the current visual selection
---@return {[1]: integer, [2]: integer}
M.range_from_selection = function()
  local start = vim.fn.getpos("v")
  local end_ = vim.fn.getpos(".")
  local start_row = start[2]
  local end_row = end_[2]

  -- A user can start visual selection at the end and move backwards
  -- Normalize the range to start < end
  if end_row < start_row then
    start_row, end_row = end_row, start_row
  end
  return { start_row, end_row }
end

---@class (exact) LocationOpts
---@field context? 'file'|'line'

---@return string
M.get_location = function(opts)
  opts = opts or {}
  if vim.bo.buftype ~= "" then
    error("Cannot get location of non-normal buffer")
  end

  local mode = vim.api.nvim_get_mode().mode
  local is_visual_mode = mode == "v" or mode == "V"
  if opts.context == nil and is_visual_mode then
    opts.context = "line"
  end

  vim.cmd.update()

  local filename = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  if vim.startswith(filename, cwd) then
    filename = filename:sub(cwd:len() + 2)
  else
    filename = vim.fn.fnamemodify(filename, ":~")
  end

  if opts.context ~= "line" then
    return "@" .. filename
  end

  if is_visual_mode then
    local range = M.range_from_selection()
    if range[1] == range[2] then
      return string.format("%s:%d", filename, range[1])
    else
      return string.format("%s:%d-%d", filename, range[1], range[2])
    end
  else
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    return string.format("%s:%d", filename, lnum)
  end
end

return M
