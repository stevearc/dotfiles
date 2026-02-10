local M = {}

M.setup = function(opts) end

---@return ClaudeProcess
M.get_proc = function()
  return require("claude.process").get_proc()
end

---@param bufnr integer
---@return integer
local function open_float(bufnr)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  return vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })
end

local function leave_visual_mode()
  local mode = vim.api.nvim_get_mode().mode
  if vim.startswith(string.lower(mode), "v") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  end
end

---@return integer?
local function get_float_win()
  local c = M.get_proc()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == c.bufnr then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        return win
      end
    end
  end
end

---Get the start and end line numbers from the current visual selection
---@return {[1]: integer, [2]: integer}
local function range_from_selection()
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
local function get_location(opts)
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
    local range = range_from_selection()
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

-- TODO copy my action running logic from overseer or oil
local actions = {
  send_location = {
    desc = "Send cursor location to claude",
    mode = { "n", "v" },
    callback = function()
      local location = get_location()
      local c = M.get_proc()
      c:send_text(location .. " ")
      leave_visual_mode()
      open_float(c.bufnr)
      vim.cmd.startinsert()
    end,
  },
  toggle_float = {
    desc = "Open claude buffer in a floating window",
    callback = function()
      local winid = get_float_win()
      if winid then
        vim.api.nvim_win_close(winid, true)
      else
        local c = M.get_proc()
        open_float(c.bufnr)
        vim.cmd.startinsert()
      end
    end,
  },
  autofill = {
    desc = "Auto implement some code",
    mode = { "n", "v" },
    callback = function()
      local location = get_location({ context = "line" })
      leave_visual_mode()
      local c = M.get_proc()
      c:send_text(
        string.format(
          "Implement the missing code in %s. No need to run tests or format the code.",
          location
        ),
        true
      )
    end,
  },
}

---@param action_name? string
M.run_action = function(action_name)
  if not action_name then
    local items = vim.tbl_filter(function(action)
      return not action.cond or action.cond()
    end, actions)
    vim.ui.select(items, {
      format_item = function(item)
        return item.desc
      end,
    }, function(action)
      if action and (not action.cond or action.cond()) then
        action.callback()
      end
    end)
  else
    local action = assert(actions[action_name])
    if action.cond and not action.cond() then
      vim.notify("Cannot " .. action.desc, vim.log.levels.ERROR)
    else
      action.callback()
    end
  end
end

return M
