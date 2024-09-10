local M = {}

---@param replacement string
local function replace_marker(replacement)
  local line = vim.api.nvim_get_current_line()
  local prefix, box = line:match("^(%s*[-*] )(%[.%])")
  if not prefix or not box then
    return
  end
  local cur = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_text(0, cur[1] - 1, prefix:len(), cur[1] - 1, prefix:len() + box:len(), { replacement })
end

---@param new_status string
M.task_mutate = function(new_status)
  return function() replace_marker("[" .. new_status .. "]") end
end

return M
