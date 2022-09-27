local M = {}

---@type QuickAction
---@field name string
---@field condition nil|fun(): boolean
---@field action fun()

---@type table<string, QuickAction>
local bindings = {}

local autocmd_id

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
    bindings[lhs] = {}
  end
  table.insert(bindings[lhs], action)
  if not autocmd_id then
    autocmd_id = vim.api.nvim_create_autocmd("FileType", {
      desc = "Set up quick actions in normal buffers",
      pattern = "*",
      callback = function(params)
        if vim.bo[params.buf].buftype ~= "" then
          return
        end
        for lhs in pairs(bindings) do
          vim.keymap.set("n", lhs, function()
            run_action(lhs)
          end, { buffer = params.buf, desc = "Action picker" })
        end
      end,
    })
  end
end

return M
