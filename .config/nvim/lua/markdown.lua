local M = {}

---@return nil|TSNode
local function get_task_list_marker()
  local node = vim.treesitter.get_node()
  while node and node:type() ~= "list_item" do
    node = node:parent()
  end
  if not node then
    return
  end
  for child in node:iter_children() do
    if child:type():match("^task_list_marker") then
      return child
    end
  end
end

---@param replacement string
local function replace_marker(replacement)
  local marker = get_task_list_marker()
  if not marker then
    return
  end
  local range = vim.treesitter.get_range(marker, 0)
  local start_row, start_col, _, end_row, end_col, _ = unpack(range)
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { replacement })
end

M.task_mark_done = function()
  replace_marker("[x]")
end

M.task_mark_undone = function()
  replace_marker("[ ]")
end

return M
