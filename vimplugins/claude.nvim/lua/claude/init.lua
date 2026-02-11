local M = {}

---@param opts? claude.SetupOpts
M.setup = function(opts)
  require("claude.config").setup(opts)
end

---@return ClaudeProcess
M.get_proc = function()
  return require("claude.process").get_proc()
end

-- TODO copy my action running logic from overseer or oil
local actions = {
  send_location = {
    desc = "Send cursor location to claude",
    mode = { "n", "v" },
    callback = function()
      local util = require("claude.util")
      local window = require("claude.window")
      local location = util.get_location()
      local c = M.get_proc()
      c:send_text(location .. " ")
      util.leave_visual_mode()
      window.open_float(c.bufnr)
      vim.cmd.startinsert()
    end,
  },
  toggle_float = {
    desc = "Open claude buffer in a floating window",
    callback = function()
      local window = require("claude.window")
      local winid = window.get_float_win()
      if winid then
        vim.api.nvim_win_close(winid, true)
      else
        local c = M.get_proc()
        window.open_float(c.bufnr)
        vim.cmd.startinsert()
      end
    end,
  },
  autofill = {
    desc = "Auto implement some code",
    mode = { "n", "v" },
    callback = function()
      local util = require("claude.util")
      local location = util.get_location({ context = "line" })
      util.leave_visual_mode()
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
