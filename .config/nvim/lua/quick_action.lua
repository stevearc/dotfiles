local M = {}

---@class QuickAction
---@field name string
---@field condition nil|fun(): boolean
---@field action fun()

---@type table<string, QuickAction[]>
local registered_actions = {}

---@param name string
---@param fallback nil|string
M.run_action = function(name, fallback)
  name = name:lower()
  local actions = vim.tbl_filter(function(action)
    if not action.condition then
      return true
    end
    local ok, active = pcall(action.condition)
    if not ok then
      vim.notify_once(
        string.format("Error while checking condition for action %s: %s", name, active),
        vim.log.levels.ERROR
      )
      return false
    else
      return active
    end
  end, registered_actions[name])

  if #actions == 0 then
    if fallback then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(fallback, true, true, true), "n", false)
    end
    return
  elseif #actions == 1 then
    actions[1].action()
  else
    vim.ui.select(actions, {
      prompt = "Action",
      format_item = function(action) return action.name end,
    }, function(action)
      if action then
        action.action()
      end
    end)
  end
end

---@param mode string|string[]
---@param lhs string
---@param name string
---@param opts table
M.set_keymap = function(mode, lhs, name, opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    desc = string.format("Run action %s", name),
  })
  vim.keymap.set(mode, lhs, function() M.run_action(name, lhs) end, opts)
end

---@param name string
---@param action QuickAction
M.add = function(name, action)
  name = name:lower()
  if not registered_actions[name] then
    registered_actions[name] = {}
  end
  table.insert(registered_actions[name], action)
end

return M
