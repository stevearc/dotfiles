local root_config = require("three.config")
local util = require("three.util")
local config = setmetatable({}, {
  __index = function(_, key)
    return root_config.bufferline[key]
  end,
})

local M = {}

---@class three.TabState
---@field buffers integer[]
---@field buf_info table<integer, three.BufferState>

---@class three.BufferState
---@field bufnr integer
---@field pinned boolean

local tabstate_meta = {
  __newindex = function(t, key, val)
    if key == 0 then
      t[vim.api.nvim_get_current_tabpage()] = val
    else
      rawset(t, key, val)
    end
  end,
  __index = function(t, key)
    if key == 0 then
      return t[vim.api.nvim_get_current_tabpage()]
    else
      local ts = {
        buffers = {},
        buf_info = {},
        scope_by_directory = config.scope_by_directory,
      }
      t[key] = ts
      return ts
    end
  end,
}

---@type table<integer, three.TabState>
local tabstate = setmetatable({}, tabstate_meta)

---@return any
M.save = function()
  local ret = {}
  for _, ts in pairs(tabstate) do
    local serialized = {
      buffers = {},
      scope_by_directory = ts.scope_by_directory,
    }
    table.insert(ret, serialized)
    for _, bufnr in ipairs(ts.buffers) do
      local buf_info = ts.buf_info[bufnr]
      table.insert(serialized.buffers, {
        name = vim.api.nvim_buf_get_name(bufnr),
        pinned = buf_info.pinned,
      })
    end
  end
  return ret
end

---@param state any
M.restore = function(state)
  tabstate = {}
  for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local ts = state[i]
    if ts then
      local new_ts = {
        buffers = {},
        buf_info = {},
        scope_by_directory = ts.scope_by_directory,
      }
      tabstate[tabpage] = new_ts
      for _, buf_info in ipairs(ts.buffers) do
        local bufnr = vim.fn.bufadd(buf_info.name)
        table.insert(new_ts.buffers, bufnr)
        new_ts.buf_info[bufnr] = {
          bufnr = bufnr,
          pinned = buf_info.pinned,
        }
      end
    end
  end
  setmetatable(tabstate, tabstate_meta)
end

---@param ts three.TabState
local function sort_pins_to_left(ts)
  local pinned = {}
  local unpinned = {}
  for _, bufnr in ipairs(ts.buffers) do
    if ts.buf_info[bufnr].pinned then
      table.insert(pinned, bufnr)
    else
      table.insert(unpinned, bufnr)
    end
  end
  ts.buffers = vim.list_extend(pinned, unpinned)
end

local function apply_sorting()
  local ts = tabstate[0]
  sort_pins_to_left(ts)
end

---@param tabpage integer
---@param bufnr integer
---@return boolean
local function should_display(tabpage, bufnr)
  local ts = tabstate[tabpage]
  if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
    if ts.scope_by_directory then
      local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
      local cwd = vim.fn.getcwd(-1, tabnr)
      return util.is_subdir(cwd, vim.api.nvim_buf_get_name(bufnr))
    else
      return true
    end
  end
  return false
end

---@param tabpage integer
---@param bufnr integer
---@return boolean
local function add_buffer(tabpage, bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local ts = tabstate[tabpage]
  if ts.buf_info[bufnr] then
    return false
  end
  table.insert(ts.buffers, bufnr)
  ts.buf_info[bufnr] = {
    bufnr = bufnr,
  }
  apply_sorting()
  return true
end

---@param bufnr integer
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
---@return nil|integer
M.get_relative_buffer = function(bufnr, opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    delta = 1,
    wrap = false,
  })
  local ts = tabstate[0]
  if vim.tbl_isempty(ts.buffers) then
    return nil
  end
  local idx = util.tbl_index(ts.buffers, bufnr)
  if idx then
    idx = idx + opts.delta
    if opts.wrap then
      idx = (idx - 1) % #ts.buffers + 1
    else
      idx = math.max(1, math.min(#ts.buffers, idx))
    end
  else
    idx = 1
  end
  return ts.buffers[idx]
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.next = function(opts)
  local curbuf = vim.api.nvim_get_current_buf()
  local newbuf = M.get_relative_buffer(curbuf, opts)
  if newbuf then
    vim.api.nvim_win_set_buf(0, newbuf)
    util.rerender()
  end
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.prev = function(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    delta = 1,
    wrap = false,
  })
  opts.delta = -1 * opts.delta
  local curbuf = vim.api.nvim_get_current_buf()
  local newbuf = M.get_relative_buffer(curbuf, opts)
  if newbuf then
    vim.api.nvim_win_set_buf(0, newbuf)
    util.rerender()
  end
end

---@param position integer
M.move_buffer = function(position)
  local ts = tabstate[0]
  local bufnr = vim.api.nvim_get_current_buf()
  local idx = util.tbl_index(ts.buffers, bufnr)
  if idx then
    position = math.max(1, math.min(#ts.buffers, position))
    table.remove(ts.buffers, idx)
    table.insert(ts.buffers, position, bufnr)
    apply_sorting()
    util.rerender()
  end
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.move_buffer_relative = function(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    delta = 1,
    wrap = false,
  })
  local ts = tabstate[0]
  local bufnr = vim.api.nvim_get_current_buf()
  local idx = util.tbl_index(ts.buffers, bufnr)
  if idx then
    idx = idx + opts.delta
    if opts.wrap then
      idx = (idx - 1) % #ts.buffers + 1
    else
      idx = math.max(1, math.min(#ts.buffers, idx))
    end
    M.move_buffer(idx)
  end
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.move_right = function(opts)
  M.move_buffer_relative(opts)
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.move_left = function(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    delta = 1,
    wrap = false,
  })
  opts.delta = -1 * opts.delta
  M.move_buffer_relative(opts)
end

---@param opts nil|{delta: nil|integer, wrap: nil|boolean}
local function get_relative_tab(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    delta = 1,
    wrap = false,
  })
  local curtab = vim.api.nvim_get_current_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()
  local idx = util.tbl_index(tabpages, curtab)
  if idx then
    idx = idx + opts.delta
    if opts.wrap then
      idx = (idx - 1) % #tabpages + 1
    else
      idx = math.max(1, math.min(#tabpages, idx))
    end
  else
    idx = 1
  end
  return tabpages[idx]
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.next_tab = function(opts)
  local tabpage = get_relative_tab(opts)
  vim.api.nvim_set_current_tabpage(tabpage)
end

---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.prev_tab = function(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    delta = 1,
    wrap = false,
  })
  opts.delta = -1 * opts.delta
  local tabpage = get_relative_tab(opts)
  vim.api.nvim_set_current_tabpage(tabpage)
end

---@param idx integer
M.jump_to = function(idx)
  local ts = tabstate[0]
  local buf = ts.buffers[idx]
  if buf then
    vim.api.nvim_win_set_buf(0, buf)
    util.rerender()
  else
    vim.notify(string.format("No buffer at index %s", idx), vim.log.levels.WARN)
  end
end

---@param tabpage integer
---@param bufnr integer
---@return boolean
local function remove_buffer_from_tabstate(tabpage, bufnr)
  local ts = tabstate[tabpage]
  local idx = util.tbl_index(ts.buffers, bufnr)
  if idx then
    table.remove(ts.buffers, idx)
    ts.buf_info[bufnr] = nil
    return true
  else
    return false
  end
end

---@param bufnr integer
---@return boolean
local function remove_buffer_from_tabstates(bufnr)
  local any_changes = false
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    any_changes = remove_buffer_from_tabstate(tabpage, bufnr) or any_changes
  end
  return any_changes
end

---@param bufnr integer
local function touch_buffer(bufnr)
  if should_display(0, bufnr) then
    if add_buffer(0, bufnr) then
      util.rerender()
    end
  elseif remove_buffer_from_tabstates(bufnr) then
    util.rerender()
  end
end

---@param tabpage integer
---@param bufnr integer
---@return nil|integer
local function get_fallback_buffer(tabpage, bufnr)
  local replacement = M.get_relative_buffer(bufnr, { delta = -1 })
  if not replacement or replacement == bufnr then
    replacement = M.get_relative_buffer(bufnr, { delta = 1 })
  end

  if replacement == bufnr then
    return nil
  else
    return replacement
  end
end

---@param tabpage integer
---@param bufnr integer
local function remove_buf_from_tab_wins(tabpage, bufnr)
  local ts = tabstate[tabpage]
  if vim.tbl_contains(ts.buffers, bufnr) then
    local fallback = get_fallback_buffer(tabpage, bufnr)
    if fallback then
      for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
        if vim.api.nvim_win_get_buf(winid) == bufnr then
          vim.api.nvim_win_set_buf(winid, fallback)
        end
      end
    end
  end
end

---@param bufnr nil|integer
---@param force nil|boolean
M.close_buffer = function(bufnr, force)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    remove_buf_from_tab_wins(tabpage, bufnr)
    remove_buffer_from_tabstate(tabpage, bufnr)
  end

  local bdelete = "bdelete"
  if force then
    bdelete = bdelete .. "!"
  end
  vim.cmd(bdelete .. " " .. tostring(bufnr))
end

M.toggle_pin = function()
  local ts = tabstate[0]
  local bufnr = vim.api.nvim_get_current_buf()
  if ts.buf_info[bufnr] then
    ts.buf_info[bufnr].pinned = not ts.buf_info[bufnr].pinned
    apply_sorting()
    util.rerender()
  end
end

M.clone_tab = function()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local ts = tabstate[tabpage]
  local bufnr = vim.api.nvim_get_current_buf()
  vim.cmd("tabnew")
  vim.api.nvim_buf_set_option(0, "buflisted", false)
  tabstate[0] = vim.deepcopy(ts)
  vim.api.nvim_set_current_buf(bufnr)
end

local function other_normal_window_exists()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local curwin = vim.api.nvim_get_current_win()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if util.is_normal_win(winid) and curwin ~= winid then
      return true
    end
  end
  return false
end

---Close the current window, or if this is the last (normal) window open, close the current buffer
M.smart_close = function()
  local curwin = vim.api.nvim_get_current_win()
  -- if we're in a non-normal or floating window: close
  if not util.is_normal_win(0) then
    vim.cmd("close")
    return
  end

  -- You can tag a window for smart_close to always close the buffer by setting the window
  -- variable vim.w.smart_close_buffer = true
  local ok, close_buffer = pcall(vim.api.nvim_win_get_var, curwin, "smart_close_buffer")
  if ok and close_buffer then
    local bufnr = vim.api.nvim_get_current_buf()
    if other_normal_window_exists() then
      vim.cmd("close")
    elseif #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("tabclose")
    end
    M.close_buffer(bufnr)
  elseif other_normal_window_exists() then
    vim.cmd("close")
  else
    M.close_buffer()
  end
end

M.hide_buffer = function(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  remove_buf_from_tab_wins(0, bufnr)
  remove_buffer_from_tabstate(0, bufnr)
end

M.create_autocmds = function(group)
  vim.api.nvim_create_autocmd({ "BufNew", "TermOpen", "BufEnter" }, {
    pattern = "*",
    group = group,
    callback = function(params)
      touch_buffer(params.buf)
    end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "buflisted",
    group = group,
    callback = function(params)
      touch_buffer(params.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    pattern = "*",
    group = group,
    callback = function(params)
      if remove_buffer_from_tabstates(params.buf) then
        util.rerender()
      end
    end,
  })
end

M.display_all_buffers = function()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if should_display(0, bufnr) then
      add_buffer(0, bufnr)
    end
  end
end

---@return boolean
M.toggle_scope_by_dir = function()
  local ts = tabstate[0]
  M.set_scope_by_dir(not ts.scope_by_directory)
  return ts.scope_by_directory
end

---@param scope_by_dir boolean
M.set_scope_by_dir = function(scope_by_dir)
  local ts = tabstate[0]
  ts.scope_by_directory = scope_by_dir
  if scope_by_dir then
    local to_remove = vim.tbl_filter(function(bufnr)
      return not should_display(0, bufnr)
    end, ts.buffers)
    for _, bufnr in ipairs(to_remove) do
      remove_buffer_from_tabstate(0, bufnr)
    end
  else
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) then
        local bufnr = vim.api.nvim_win_get_buf(winid)
        if should_display(0, bufnr) then
          add_buffer(0, bufnr)
        end
      end
    end
  end
  util.rerender()
end

return setmetatable(M, {
  __newindex = function(_, key)
    error(string.format("Cannot set '%s' on three.bufferline.state", key))
  end,
  __index = function(_, key)
    local ts = tabstate[key]
    if ts then
      -- Make sure all the buffers are valid
      ts.buffers = vim.tbl_filter(function(bufnr)
        return vim.api.nvim_buf_is_valid(bufnr)
      end, ts.buffers)
    end
    return ts
  end,
})
