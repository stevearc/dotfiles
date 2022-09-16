local root_config = require("three.config")
local state = require("three.bufferline.state")
local util = require("three.util")

local config = setmetatable({}, {
  __index = function(_, key)
    return root_config.bufferline[key]
  end,
})

local M = {}

local MAX_PADDING = 10

local function hl(name)
  return "%#" .. name .. "#"
end

local function update_names(ts)
  local names = util.get_unique_names(vim.tbl_map(function(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    return name == "" and string.format("buffer %d", bufnr) or name
  end, ts.buffers))
  for i, name in ipairs(names) do
    local bufnr = ts.buffers[i]
    local buf_info = ts.buf_info[bufnr]
    buf_info.name = name
  end
end

local function format_buffer(buf_data)
  local pieces = {}
  table.insert(pieces, hl("TabLineDivider" .. buf_data.status))
  table.insert(pieces, config.icon.dividers[1])
  local padding = buf_data.width - buf_data.min_width
  table.insert(pieces, string.rep(" ", math.ceil(padding / 2)))
  table.insert(pieces, hl("TabLineIndex" .. buf_data.status))
  table.insert(pieces, buf_data.prefix)
  local mod = buf_data.is_modified and "Modified" or ""
  table.insert(pieces, hl("TabLine" .. mod .. buf_data.status))
  table.insert(pieces, buf_data.name)
  table.insert(pieces, buf_data.suffix)
  table.insert(pieces, string.rep(" ", math.floor(padding / 2)))
  if buf_data.pinned then
    table.insert(pieces, config.icon.pin)
  end
  table.insert(pieces, hl("TabLineDivider" .. buf_data.status))
  table.insert(pieces, config.icon.dividers[2])
  return table.concat(pieces, "")
end

local function get_buf_layout_data(idx, bufnr, buf_info, status)
  local prefix = tostring(idx) .. " "
  local suffix = " "
  local min_width = vim.api.nvim_strwidth(config.icon.dividers[1])
    + vim.api.nvim_strwidth(config.icon.dividers[2])
    + vim.api.nvim_strwidth(prefix)
    + vim.api.nvim_strwidth(buf_info.name)
    + vim.api.nvim_strwidth(suffix)
  if buf_info.pinned then
    min_width = min_width + vim.api.nvim_strwidth(config.icon.pin)
  end
  return {
    is_modified = vim.api.nvim_buf_get_option(bufnr, "modified"),
    pinned = buf_info.pinned,
    min_width = min_width,
    width = min_width,
    prefix = prefix,
    suffix = suffix,
    name = buf_info.name,
    status = status,
  }
end

local function scroll_back_from(buf_data, idx, width)
  local rem = width
  local leftmost = idx
  for i = idx, 1, -1 do
    local data = buf_data[i]
    if data.width > rem then
      break
    end
    leftmost = i
    rem = rem - data.width
  end
  return leftmost
end

---@return integer the leftmost index to start rendering at
local function scroll_buffers(buf_data, focus, width)
  if vim.tbl_isempty(focus.visible_indexes) then
    -- If none of the listed buffers are visible, just scroll to the start
    return 1
  end
  -- Scroll as far left as possible while still trying to keep all the visible buffers in-frame
  local leftmost = scroll_back_from(buf_data, focus.visible_indexes[#focus.visible_indexes], width)
  -- If all of the visible buffers are in-frame, we're good
  if leftmost <= focus.visible_indexes[1] then
    return leftmost
  end

  if focus.current_idx then
    -- If the focused buffer is listed, go as far back as possible while keeping it in-frame
    return scroll_back_from(buf_data, focus.current_idx, width)
  end

  return focus.visible_indexes[1]
end

local function create_chunk(buf_data)
  local width = buf_data[1].width
  local ret = {}
  local max_pad = MAX_PADDING
  for _, v in ipairs(buf_data) do
    if v.width == width then
      table.insert(ret, v)
      local padding = (v.width - v.min_width)
      max_pad = math.min(max_pad, MAX_PADDING - padding)
    else
      max_pad = math.max(0, math.min(max_pad, v.width - width))
      break
    end
  end
  return ret, max_pad
end

local function add_padding(buf_data, width)
  local by_size = vim.list_extend({}, buf_data)
  table.sort(by_size, function(a, b)
    if a.width == b.width then
      return a.min_width < b.min_width
    else
      return a.width < b.width
    end
  end)

  local iter = 1
  while width > 0 and not vim.tbl_isempty(by_size) do
    -- TODO could optimize this by doing the operations in-place
    local chunk, max_pad = create_chunk(by_size)
    local total_boost = math.min(width, #chunk * max_pad)
    local boost = math.floor(total_boost / #chunk)
    local mod = total_boost % #chunk

    for _, data in ipairs(chunk) do
      data.width = data.width + boost
      width = width - boost
      if mod > 0 then
        mod = mod - 1
        data.width = data.width + 1
        width = width - 1
      end
    end
    while not vim.tbl_isempty(by_size) and (by_size[1].width - by_size[1].min_width) == MAX_PADDING do
      table.remove(by_size, 1)
    end
    iter = iter + 1
    if iter > 20 then
      vim.api.nvim_err_writeln("[three.nvim] Infinite loop in add_padding (please report)")
      break
    end
  end
end

---@param max_width integer
---@return string
local function format_buffers(max_width)
  -- Start width by accounting for final divider
  max_width = max_width - vim.api.nvim_strwidth(config.icon.dividers[2])
  local focus = {
    current_idx = nil,
    visible_indexes = {},
  }
  local cur_buf = vim.api.nvim_get_current_buf()
  local buf_status = util.defaultdict("")
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    buf_status[bufnr] = bufnr == cur_buf and "Sel" or "Visible"
  end
  local ts = state[0]
  if vim.tbl_isempty(ts.buffers) then
    return ""
  end
  update_names(ts)
  local buf_data = {}
  local total_width = 0
  for i, bufnr in ipairs(ts.buffers) do
    local status = buf_status[bufnr]
    local data = get_buf_layout_data(i, bufnr, ts.buf_info[bufnr], status)
    table.insert(buf_data, data)
    if status == "Sel" then
      focus.current_idx = i
      table.insert(focus.visible_indexes, i)
    elseif status == "Visible" then
      table.insert(focus.visible_indexes, i)
    end
    total_width = total_width + data.width
  end

  local prefix = ""
  local suffix = ""
  if total_width > max_width then
    -- Perform width calculations assuming we have to show scroll icons
    local scroll_width = max_width
      - vim.api.nvim_strwidth(config.icon.scroll[1])
      - vim.api.nvim_strwidth(config.icon.scroll[2])
    local start_idx = scroll_buffers(buf_data, focus, scroll_width)
    local slice_width = 0
    local slice = {}
    for i = start_idx, #buf_data do
      local data = buf_data[i]
      if slice_width + data.width > max_width then
        break
      end
      table.insert(slice, data)
      slice_width = slice_width + data.width
    end
    if start_idx > 1 then
      prefix = config.icon.scroll[1]
    end
    if start_idx + #slice < #buf_data then
      suffix = config.icon.scroll[2]
    end
    buf_data = slice
    total_width = slice_width
  end

  total_width = total_width + vim.api.nvim_strwidth(prefix)
  total_width = total_width + vim.api.nvim_strwidth(suffix)
  if total_width < max_width then
    add_padding(buf_data, max_width - total_width)
  end

  return hl("TabLineScrollIndicator")
    .. prefix
    .. table.concat(
      vim.tbl_map(function(data)
        return format_buffer(data)
      end, buf_data),
      ""
    )
    .. hl("TabLineScrollIndicator")
    .. suffix
end

---@return string
---@return integer
local function format_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()
  local cwds = vim.tbl_map(function(tabpage)
    local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
    return vim.fn.fnamemodify(vim.fn.getcwd(-1, tabnr), ":p:h")
  end, tabpages)
  cwds = util.get_unique_names(cwds)
  local curtab = vim.api.nvim_get_current_tabpage()
  local cwd = cwds[util.tbl_index(tabpages, curtab)]
  local pieces = { cwd }
  if #tabpages > 1 then
    table.insert(pieces, string.format(" %d/%d", util.tbl_index(tabpages, curtab), #tabpages))
  end
  local formatted = table.concat(pieces, "") .. " "
  return hl("TabLineDir") .. formatted, vim.api.nvim_strwidth(formatted)
end

M.render = function()
  local tabpages_str, tabpages_width = format_tabpage()
  local remaining_width = vim.o.columns - tabpages_width
  local buffers_str = format_buffers(remaining_width)
  local pieces = {
    tabpages_str,
    hl("TabLineFill"),
    buffers_str,
    hl("TabLineFill"),
  }
  return table.concat(pieces, "") .. "%="
end

return M
