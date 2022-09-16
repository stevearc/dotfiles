local three = require("three")
local M = {}

---Get the saved data for this extension
---@return any
M.on_save = function()
  return three.save_state()
end

---Restore the extension state
---@param data The value returned from on_save
M.on_load = function(data)
  three.restore_state(data)
end

return M
