local M = {}

---@class claude.AnnotationLocation
---@field filename string
---@field start_lnum integer
---@field end_lnum integer
---@field comment string

---@type claude.AnnotationLocation[]
local _annotations = {}

---@type integer[]
local _annotated_buffers = {}

local ns = vim.api.nvim_create_namespace("claude_annotations")

vim.api.nvim_set_hl(0, "ClaudeAnnotation", { default = true, link = "DiagnosticVirtualTextInfo" })

---@param bufnr integer
---@param lnum integer
---@return string
local function get_scope_name(bufnr, lnum)
  local ok, aerial = pcall(require, "aerial")
  if ok then
    local symbols = vim.api.nvim_buf_call(bufnr, function()
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return aerial.get_location(false)
    end)
    if #symbols > 0 then
      local parts = vim.tbl_map(function(s)
        return s.name
      end, symbols)
      return table.concat(parts, ".")
    end
  end

  -- Fallback: use trimmed line text
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)
  if lines[1] then
    return vim.trim(lines[1])
  end
  return ""
end

---@param text string
---@param width integer
---@return string[]
local function wrap_text(text, width)
  if width <= 0 then
    return { text }
  end
  local lines = {}
  local line = ""
  for word in text:gmatch("%S+") do
    if line == "" then
      line = word
    elseif #line + 1 + #word <= width then
      line = line .. " " .. word
    else
      table.insert(lines, line)
      line = word
    end
  end
  if line ~= "" then
    table.insert(lines, line)
  end
  return lines
end

---@param annotations claude.AnnotationLocation[]
function M.set(annotations)
  -- Clear previous extmarks
  for _, bufnr in ipairs(_annotated_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end
  _annotated_buffers = {}

  _annotations = annotations

  local qf_items = {}
  for _, ann in ipairs(annotations) do
    local filename = ann.filename
    if not vim.startswith(filename, "/") then
      filename = vim.fn.fnamemodify(filename, ":p")
    end

    local bufnr = vim.fn.bufadd(filename)
    vim.fn.bufload(bufnr)

    local scope_name = get_scope_name(bufnr, ann.start_lnum)

    table.insert(qf_items, {
      bufnr = bufnr,
      lnum = ann.start_lnum,
      col = 1,
      text = scope_name,
    })

    -- Build virtual lines from the comment, wrapping at textwidth
    local tw = vim.bo[bufnr].textwidth
    if tw == 0 then
      tw = 80
    end
    local virt_lines = {}
    for _, line in ipairs(vim.split(ann.comment, "\n")) do
      for _, wrapped in ipairs(wrap_text(line, tw)) do
        table.insert(virt_lines, { { wrapped, "ClaudeAnnotation" } })
      end
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns, ann.start_lnum - 1, 0, {
      virt_lines = virt_lines,
      virt_lines_above = true,
    })

    if not vim.tbl_contains(_annotated_buffers, bufnr) then
      table.insert(_annotated_buffers, bufnr)
    end
  end

  vim.fn.setqflist(qf_items)
  local winid = vim.api.nvim_get_current_win()
  vim.cmd.copen()
  vim.api.nvim_set_current_win(winid)
end

function M.clear()
  M.set({})
end

---@return claude.AnnotationLocation[]
function M.get()
  return _annotations
end

return M
