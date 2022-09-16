local M = {}

M.wrap = function(fn, ...)
  local args = { ... }
  return function(...)
    return fn(unpack(args), ...)
  end
end

---Defer loading of this function
---@param mod string Name of three.nvim module
---@param fn string Name of function to wrap
local function lazy(mod, fn)
  return function(...)
    return require(string.format("three.%s", mod))[fn](...)
  end
end

M.save_state = lazy("bufferline.state", "save")
M.restore_state = lazy("bufferline.state", "restore")
---@param bufnr integer
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
---@return nil|integer
M.get_relative_buffer = lazy("bufferline.state", "get_relative_buffer")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.next = lazy("bufferline.state", "next")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.prev = lazy("bufferline.state", "prev")
---@param position integer
M.move_buffer = lazy("bufferline.state", "move_buffer")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.move_buffer_relative = lazy("bufferline.state", "move_buffer_relative")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.move_right = lazy("bufferline.state", "move_right")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.move_left = lazy("bufferline.state", "move_left")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.next_tab = lazy("bufferline.state", "next_tab")
---@param opts table
---    delta nil|integer
---    wrap nil|boolean
M.prev_tab = lazy("bufferline.state", "prev_tab")
---@param idx integer
M.jump_to = lazy("bufferline.state", "jump_to")
---@param bufnr nil|integer
---@param force nil|boolean
M.close_buffer = lazy("bufferline.state", "close_buffer")
---Toggle the pinned status of the current buffer
M.toggle_pin = lazy("bufferline.state", "toggle_pin")
---Clone the current tab into a new tab
M.clone_tab = lazy("bufferline.state", "clone_tab")
---Close the current window or buffer
M.smart_close = lazy("bufferline.state", "smart_close")
---Hide the current buffer from the current tab
M.hide_buffer = lazy("bufferline.state", "hide_buffer")
---@return boolean
M.toggle_scope_by_dir = lazy("bufferline.state", "toggle_scope_by_dir")
---@param scope_by_dir boolean
M.set_scope_by_dir = lazy("bufferline.state", "set_scope_by_dir")

M.toggle_win_resize = lazy("windows", "toggle_enabled")
M.set_win_resize = lazy("windows", "set_enabled")

M.setup = function(opts)
  local config = require("three.config")
  config.setup(opts)
  if config.bufferline.enabled then
    require("three.bufferline").setup(config.bufferline)
  end
  if config.windows.enabled then
    require("three.windows").setup(config.windows)
  end
end

return M
