local function expand_qf_context(num_before, num_after)
  local curpos = vim.api.nvim_win_get_cursor(0)[1]
  local newpos
  local qf_list = vim.fn.getqflist({ all = 0 })
  local items = {}
  for i, item in ipairs(qf_list.items) do
    local low = math.max(0, item.lnum - 1 - num_before)
    if not vim.api.nvim_buf_is_loaded(item.bufnr) then
      vim.fn.bufload(item.bufnr)
    end
    local filename = vim.fs.basename(vim.api.nvim_buf_get_name(item.bufnr))
    local header = string.rep("─", 8) .. filename
    table.insert(items, { text = header, valid = 0 })

    local lines = vim.api.nvim_buf_get_lines(item.bufnr, low, item.lnum + num_after, false)
    for j, line in ipairs(lines) do
      if j + low == item.lnum then
        table.insert(items, item)
        if i == curpos then
          newpos = #items
        end
      else
        table.insert(items, { bufnr = item.bufnr, lnum = low + j, text = line, valid = 0 })
      end
    end
  end

  vim.fn.setqflist({}, "r", { items = items, title = qf_list.title, context = qf_list.context })
  if qf_list.winid then
    vim.api.nvim_win_set_cursor(qf_list.winid, { newpos, 0 })
    vim.api.nvim_win_set_height(qf_list.winid, math.min(20, #items))
  end
end

local function collapse_qf_context()
  local curpos = vim.api.nvim_win_get_cursor(0)[1]
  local qf_list = vim.fn.getqflist({ all = 0 })
  local items = {}
  local last_item
  for i, item in ipairs(qf_list.items) do
    if item.valid == 1 then
      table.insert(items, item)
      if i <= curpos then
        last_item = #items
      end
    end
  end
  vim.tbl_filter(function(item) return item.valid == 1 end, qf_list.items)
  vim.fn.setqflist({}, "r", { items = items, title = qf_list.title, context = qf_list.context })
  if qf_list.winid then
    if last_item then
      vim.api.nvim_win_set_cursor(qf_list.winid, { last_item, 0 })
    end
    vim.api.nvim_win_set_height(qf_list.winid, math.max(4, math.min(10, #items)))
  end
end

require("ftplugin").extend("qf", {
  keys = {
    { ">", function() expand_qf_context(2, 2) end },
    { "<", function() collapse_qf_context() end },
  },
})

local function get_filename_from_item(item)
  local fs = require("oil.fs")
  if item.valid == 1 then
    if item.module and item.module ~= "" then
      return item.module
    elseif item.bufnr > 0 then
      local bufname = vim.api.nvim_buf_get_name(item.bufnr)
      return fs.shorten_path(bufname)
    else
      return "<unknown>"
    end
  else
    return "<unknown>"
  end
end

local _col_width_cache = {}
local function get_cached_qf_col_width(id, items)
  local key = string.format("%d|%d", id, #items)
  if not _col_width_cache[key] then
    local max_len = 7
    for _, item in ipairs(items) do
      max_len = math.max(max_len, vim.api.nvim_strwidth(get_filename_from_item(item)))
    end

    _col_width_cache[key] = max_len + 1
  end
  return _col_width_cache[key]
end

-- TODO make the header lines programmatic (maybe? could mess up cursor position calculations)
-- better way to set headers
function _G.qftf(info)
  local items
  local ret = {}
  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end
  local delimiter = "┃"
  local col_width = get_cached_qf_col_width(info.id, items)
  local fname_format = "%-" .. col_width .. "s"
  for i = info.start_idx, info.end_idx do
    local item = items[i]
    if item.valid == 1 then
      local pieces = { fname_format:format(get_filename_from_item(item)) }
      table.insert(pieces, string.format("%5s", item.lnum))
      -- TODO add type
      table.insert(pieces, item.text)
      table.insert(ret, table.concat(pieces, delimiter))
    elseif vim.startswith(item.text, "─") then
      -- Headers when expanded QF list
      local pieces = { string.rep("─", col_width), string.rep("─", 5), string.rep("─", 8) }
      table.insert(ret, table.concat(pieces, "╋"))
    else
      local pieces = { string.rep(" ", col_width), string.rep(" ", 5), item.text }
      table.insert(ret, table.concat(pieces, delimiter))
    end
  end
  return ret
end

vim.o.qftf = "v:lua.qftf"
