local config = require("claude.config")

local M = {}

---@class claude.ReviewComment
---@field id integer
---@field filename string
---@field start_lnum integer
---@field end_lnum integer
---@field text string
---@field stale boolean
---@field bufnr? integer
---@field range_extmark_id? integer
---@field display_extmark_id? integer

---@type claude.ReviewComment[]
local comments = {}
local review_text = ""
local next_id = 1
local ns = vim.api.nvim_create_namespace("claude_review_comments")
local tracked_buffers = {}

vim.api.nvim_set_hl(
  0,
  "ClaudeReviewComment",
  { default = true, link = "DiagnosticVirtualTextInfo" }
)
vim.api.nvim_set_hl(0, "ClaudeReviewRange", { default = true, link = "Visual" })

---@param filename string
---@return string
local function normalize_filename(filename)
  return vim.fs.normalize(vim.fn.fnamemodify(filename, ":p"))
end

---@param comment claude.ReviewComment
---@return integer?
local function get_bufnr(comment)
  if comment.bufnr and vim.api.nvim_buf_is_valid(comment.bufnr) then
    return comment.bufnr
  end
  local bufnr = vim.fn.bufadd(comment.filename)
  if bufnr > 0 then
    comment.bufnr = bufnr
    return bufnr
  end
end

---@param bufnr integer
local function track_buffer(bufnr)
  if tracked_buffers[bufnr] then
    return
  end
  tracked_buffers[bufnr] = true
  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      tracked_buffers[bufnr] = nil
    end,
    on_lines = function(_, _, _, firstline, lastline, new_lastline)
      if new_lastline >= lastline then
        return
      end
      for _, comment in ipairs(comments) do
        if
          comment.bufnr == bufnr
          and firstline <= comment.start_lnum - 1
          and lastline >= comment.end_lnum
        then
          -- Keep the collapsed extmark at the nearest surviving line, but make
          -- loss of the entire reviewed range visible to the reviewer.
          comment.stale = true
        end
      end
    end,
  })
end

---@param text string
---@param width integer
---@return string[]
local function wrap_text(text, width)
  local result = {}
  for _, paragraph in ipairs(vim.split(text, "\n", { plain = true })) do
    if paragraph == "" then
      table.insert(result, "")
    else
      local line = ""
      for word in paragraph:gmatch("%S+") do
        if line == "" then
          line = word
        elseif #line + #word + 1 <= width then
          line = line .. " " .. word
        else
          table.insert(result, line)
          line = word
        end
      end
      table.insert(result, line)
    end
  end
  return result
end

---@param text string
---@return string
local function normalize_text(text)
  return table.concat(
    vim.tbl_map(function(line)
      return line:gsub("[ \t]+$", "")
    end, vim.split(text, "\n", { plain = true })),
    "\n"
  )
end

---@param bufnr integer
---@return integer
local function display_width(bufnr)
  local width = vim.bo[bufnr].textwidth
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    width = vim.api.nvim_win_get_width(winid) - 2
    break
  end
  return math.max(width > 0 and width or 80, 20)
end

---@param comment claude.ReviewComment
local function sync(comment)
  local bufnr = get_bufnr(comment)
  if not bufnr or not comment.range_extmark_id then
    return
  end
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  local pos =
    vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, comment.range_extmark_id, { details = true })
  if #pos == 0 then
    comment.stale = true
    return
  end
  local details = pos[3]
  comment.start_lnum = pos[1] + 1
  -- Extmark end_row is zero-based and exclusive, which conveniently equals
  -- the one-based inclusive final line for line-oriented comment ranges.
  comment.end_lnum = math.max(comment.start_lnum, details.end_row or (pos[1] + 1))
end

---@param comment claude.ReviewComment
local function render(comment)
  local bufnr = get_bufnr(comment)
  if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  sync(comment)
  local width = config.review.wrap and display_width(bufnr) or math.max(vim.bo[bufnr].textwidth, 80)
  local virt_lines = {}
  for _, line in ipairs(wrap_text(comment.text, width)) do
    table.insert(virt_lines, { { line, "ClaudeReviewComment" } })
  end
  comment.display_extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, comment.end_lnum - 1, 0, {
    id = comment.display_extmark_id,
    right_gravity = false,
    virt_lines = virt_lines,
    virt_lines_above = false,
    sign_text = comment.stale and "!" or "●",
    sign_hl_group = "ClaudeReviewComment",
  })
end

---@param comment claude.ReviewComment
local function attach(comment)
  local bufnr = get_bufnr(comment)
  if
    not bufnr
    or (not vim.api.nvim_buf_is_loaded(bufnr) and vim.fn.filereadable(comment.filename) == 0)
  then
    comment.stale = true
    return
  end
  vim.fn.bufload(bufnr)
  track_buffer(bufnr)
  local last = vim.api.nvim_buf_line_count(bufnr)
  comment.start_lnum = math.max(1, math.min(comment.start_lnum, last))
  comment.end_lnum = math.max(comment.start_lnum, math.min(comment.end_lnum, last))
  comment.range_extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, comment.start_lnum - 1, 0, {
    id = comment.range_extmark_id,
    end_row = comment.end_lnum,
    end_col = 0,
    hl_group = "ClaudeReviewRange",
    hl_eol = true,
    right_gravity = false,
    end_right_gravity = true,
  })
  render(comment)
end

---@param comment claude.ReviewComment
local function snapshot(comment)
  sync(comment)
  return vim.deepcopy(comment)
end

---@return claude.ReviewComment[]
local function sorted()
  local result = {}
  for _, comment in ipairs(comments) do
    table.insert(result, snapshot(comment))
  end
  table.sort(result, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    end
    if a.start_lnum ~= b.start_lnum then
      return a.start_lnum < b.start_lnum
    end
    if a.end_lnum ~= b.end_lnum then
      return a.end_lnum < b.end_lnum
    end
    return a.id < b.id
  end)
  return result
end

---@param opts {filename:string, start_lnum:integer, end_lnum:integer, text:string, id?:integer, stale?:boolean}
---@return claude.ReviewComment|nil, string?
function M.add(opts)
  if type(opts.text) ~= "string" then
    return nil, "Comment text cannot be empty"
  end
  opts.text = normalize_text(opts.text)
  if vim.trim(opts.text) == "" then
    return nil, "Comment text cannot be empty"
  end
  if not opts.filename or opts.filename == "" then
    return nil, "Comments require a named file buffer"
  end
  if type(opts.start_lnum) ~= "number" or type(opts.end_lnum) ~= "number" then
    return nil, "Comment range is invalid"
  end
  local comment = {
    id = opts.id or next_id,
    filename = normalize_filename(opts.filename),
    start_lnum = opts.start_lnum,
    end_lnum = opts.end_lnum,
    text = opts.text,
    stale = opts.stale or false,
  }
  next_id = math.max(next_id, comment.id + 1)
  table.insert(comments, comment)
  attach(comment)
  return snapshot(comment)
end

---@param id integer
---@param text string
---@return claude.ReviewComment|nil, string?
function M.edit(id, text)
  if type(text) ~= "string" then
    return nil, "Comment text cannot be empty"
  end
  text = normalize_text(text)
  if vim.trim(text) == "" then
    return nil, "Comment text cannot be empty"
  end
  for _, comment in ipairs(comments) do
    if comment.id == id then
      comment.text = text
      render(comment)
      return snapshot(comment)
    end
  end
  return nil, "Comment not found"
end

---@param id integer
---@return claude.ReviewComment|nil, string?
function M.delete(id)
  for i, comment in ipairs(comments) do
    if comment.id == id then
      local value = snapshot(comment)
      local bufnr = get_bufnr(comment)
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        if comment.range_extmark_id then
          vim.api.nvim_buf_del_extmark(bufnr, ns, comment.range_extmark_id)
        end
        if comment.display_extmark_id then
          vim.api.nvim_buf_del_extmark(bufnr, ns, comment.display_extmark_id)
        end
      end
      table.remove(comments, i)
      return value
    end
  end
  return nil, "Comment not found"
end

function M.clear()
  for i = #comments, 1, -1 do
    M.delete(comments[i].id)
  end
  review_text = ""
end

---@return string
function M.get_review_text()
  return review_text
end

---@param text string
---@return boolean, string?
function M.set_review_text(text)
  if type(text) ~= "string" then
    return false, "Review text must be a string"
  end
  review_text = normalize_text(text)
  return true
end

---@return claude.ReviewComment[]
function M.get()
  return sorted()
end

---@return string
function M.format()
  local result = { "# Code review" }
  if vim.trim(review_text) ~= "" then
    table.insert(result, "")
    vim.list_extend(result, vim.split(review_text, "\n", { plain = true }))
  end
  local current_file
  local cwd = normalize_filename(vim.fn.getcwd())
  for _, comment in ipairs(sorted()) do
    if current_file ~= comment.filename then
      current_file = comment.filename
      local name = current_file
      if vim.startswith(name, cwd .. "/") then
        name = name:sub(#cwd + 2)
      end
      table.insert(result, "")
      table.insert(result, "## " .. name)
    end
    table.insert(result, "")
    local location = comment.start_lnum == comment.end_lnum and ("Line " .. comment.start_lnum)
      or string.format("Lines %d-%d", comment.start_lnum, comment.end_lnum)
    table.insert(result, "### " .. location .. (comment.stale and " (STALE)" or ""))
    table.insert(result, "")
    vim.list_extend(result, vim.split(comment.text, "\n", { plain = true }))
  end
  return table.concat(result, "\n")
end

---@param filename string
---@param lnum integer
---@return claude.ReviewComment[]
function M.at(filename, lnum)
  filename = normalize_filename(filename)
  return vim.tbl_filter(function(comment)
    sync(comment)
    return comment.filename == filename and lnum >= comment.start_lnum and lnum <= comment.end_lnum
  end, comments)
end

---@param bufnr integer
---@param start_lnum integer
---@param end_lnum integer
---@return fun()
function M.preview_range(bufnr, start_lnum, end_lnum)
  local id = vim.api.nvim_buf_set_extmark(bufnr, ns, start_lnum - 1, 0, {
    end_row = end_lnum,
    end_col = 0,
    hl_group = "Visual",
    hl_eol = true,
  })
  return function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_del_extmark(bufnr, ns, id)
    end
  end
end

---@param current_filename string
---@param current_lnum integer
---@param direction integer
---@return claude.ReviewComment?
function M.navigate(current_filename, current_lnum, direction)
  local items = sorted()
  if #items == 0 then
    return
  end
  current_filename = normalize_filename(current_filename)
  local index
  for i, item in ipairs(items) do
    if
      direction > 0
      and (
        item.filename > current_filename
        or (item.filename == current_filename and item.start_lnum > current_lnum)
      )
    then
      index = i
      break
    end
    if
      direction < 0
      and (
        item.filename < current_filename
        or (item.filename == current_filename and item.start_lnum < current_lnum)
      )
    then
      index = i
    end
  end
  if not index then
    if not config.review.wrap_navigation then
      return
    end
    index = direction > 0 and 1 or #items
  end
  return items[index]
end

function M.restore(data)
  M.clear()
  if type(data) ~= "table" then
    return
  end
  for _, item in ipairs(data) do
    if
      type(item) == "table"
      and type(item.id) == "number"
      and type(item.filename) == "string"
      and type(item.text) == "string"
    then
      local valid_range = type(item.start_lnum) == "number" and type(item.end_lnum) == "number"
      M.add(vim.tbl_extend("force", item, {
        start_lnum = valid_range and item.start_lnum or 1,
        end_lnum = valid_range and item.end_lnum or 1,
        stale = item.stale or not valid_range,
      }))
    end
  end
end

---@param filename string
---@return string?
local function context_hash(filename)
  if vim.fn.filereadable(filename) ~= 1 then
    return nil
  end
  local ok, lines = pcall(vim.fn.readfile, filename)
  return ok and vim.fn.sha256(table.concat(lines, "\n")) or nil
end

function M.serialize()
  local data = {}
  for _, comment in ipairs(sorted()) do
    table.insert(data, {
      id = comment.id,
      filename = comment.filename,
      start_lnum = comment.start_lnum,
      end_lnum = comment.end_lnum,
      text = comment.text,
      stale = comment.stale,
      original_context_hash = context_hash(comment.filename),
    })
  end
  return { version = 1, review_text = review_text, comments = data }
end

M.namespace = ns
return M
