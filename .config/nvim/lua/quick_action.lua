local M = {}

---@type QuickAction
---@field name string
---@field condition nil|fun(): boolean
---@field action fun()

---@type table<string, QuickAction>
local bindings = {}

---@param lhs string
local function run_action(lhs)
  local actions = vim.tbl_filter(function(action)
    return not action.condition or action.condition()
  end, bindings[lhs])

  if #actions == 0 then
    return
  elseif #actions == 1 then
    actions[1].action()
  else
    vim.ui.select(actions, {
      prompt = "Action",
      format_item = function(action)
        return action.name
      end,
    }, function(action)
      if action then
        action.action()
      end
    end)
  end
end

---@param lhs string
---@param action QuickAction
M.add = function(lhs, action)
  lhs = lhs:lower()
  if not bindings[lhs] then
    vim.keymap.set("n", lhs, function()
      run_action(lhs)
    end, { desc = "Action picker" })
    bindings[lhs] = {}
  end
  table.insert(bindings[lhs], action)
end

return M
