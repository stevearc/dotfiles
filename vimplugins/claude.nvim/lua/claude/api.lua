local M = {}

--- Set annotations to display as virtual lines and in the quickfix list
---@param annotations claude.AnnotationLocation[]
M.annotations_set = function(annotations)
  require("claude.annotations").set(annotations)
end

--- Remove all annotations, clearing extmarks and the quickfix list
M.annotations_clear = function()
  require("claude.annotations").clear()
end

--- Return the current list of annotations
---@return claude.AnnotationLocation[]
M.annotations_get = function()
  return require("claude.annotations").get()
end

---@class claude.EditorInfo
---@field width integer
---@field height integer

---@return claude.EditorInfo
M.get_editor_info = function()
  return {
    width = vim.o.columns,
    height = vim.o.lines,
  }
end

---Set text in the quickfix. Lines with locations should be prefixed with `<filename>:<lnum>|`
---@param content string
M.setqflist = function(content)
  local lines
  if vim.fn.filereadable(content) == 1 then
    lines = vim.fn.readfile(content)
  else
    lines = vim.split(content, "\n")
  end
  local items = vim.fn.getqflist({
    lines = lines,
    efm = "%f:%l|%m",
  }).items
  vim.fn.setqflist(items)
  local winid = vim.api.nvim_get_current_win()
  vim.cmd.copen({ count = math.floor(vim.o.lines / 2) })
  vim.api.nvim_set_current_win(winid)
end

---@class claude.CurrentContext
---@field filename string
---@field lnum integer
---@field col integer

---@param winid integer
---@return claude.CurrentContext
local function make_context(winid)
  local cursor = vim.api.nvim_win_get_cursor(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  return {
    filename = vim.api.nvim_buf_get_name(bufnr),
    lnum = cursor[1],
    col = cursor[2],
  }
end

--- Get the filename and cursor position of the current window.
--- Falls back to the first window with a normal buffer if the current buffer
--- has a non-empty buftype.
---@return claude.CurrentContext?
M.get_current_context = function()
  if vim.bo.buftype == "" then
    return make_context(0)
  end

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if vim.bo[bufnr].buftype == "" then
      return make_context(winid)
    end
  end
end

---@class claude.BufferInfo
---@field bufnr integer
---@field name string
---@field buftype string
---@field filetype string
---@field modified boolean
---@field loaded boolean
---@field line_count integer -- 0 if not loaded

---@param bufnr integer
---@return claude.BufferInfo
local function make_buffer_info(bufnr)
  local loaded = vim.api.nvim_buf_is_loaded(bufnr)
  return {
    bufnr = bufnr,
    name = vim.api.nvim_buf_get_name(bufnr),
    buftype = vim.bo[bufnr].buftype,
    filetype = loaded and vim.bo[bufnr].filetype or "",
    modified = loaded and vim.bo[bufnr].modified or false,
    loaded = loaded,
    line_count = loaded and vim.api.nvim_buf_line_count(bufnr) or 0,
  }
end

--- Return a list of open files (listed buffers with buftype "")
---@return claude.BufferInfo[]
M.list_open_buffers = function()
  local results = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      table.insert(results, make_buffer_info(bufnr))
    end
  end
  return results
end

--- Return buffer info for specific buffer numbers
---@param buffers integer[]
---@return claude.BufferInfo[]
M.get_buffer_info = function(buffers)
  local results = {}
  for _, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      table.insert(results, make_buffer_info(bufnr))
    end
  end
  return results
end

--- Get all diagnostics from all open buffers with buftype ""
---@return vim.Diagnostic[]
M.get_all_diagnostics = function()
  local results = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
      vim.list_extend(results, vim.diagnostic.get(bufnr))
    end
  end
  return results
end

return M
