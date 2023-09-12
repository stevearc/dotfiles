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

local code_blocks = [[
(fenced_code_block (code_fence_content) @block)
]]

M.update_code_highlights = function(bufnr)
  if vim.fn.has("nvim-0.10") == 0 then
    return
  end
  local ns = vim.api.nvim_create_namespace("MarkdownStyle")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown", {})
  if not ok then
    return
  end
  local query = vim.treesitter.query.parse("markdown", code_blocks)

  local root = parser:parse()[1]:root()
  pcall(vim.tbl_add_reverse_lookup, query.captures)
  for _, match in query:iter_matches(root, bufnr) do
    local block = match[query.captures.block]
    vim.api.nvim_buf_set_extmark(bufnr, ns, block:start(), 0, {
      line_hl_group = "NormalFloat",
      end_row = block:end_() - 1,
    })
  end
end

return M
