local default_options = {
  on_create = function() end,
}

---@class claude.Config
---@field on_create fun(proc: ClaudeProcess)
local M = {}

---@class (exact) claude.SetupOpts
---@field on_create? fun(proc: ClaudeProcess)

local has_setup = false
M.setup = function(opts)
  has_setup = true
  opts = opts or {}
  local newconf = vim.tbl_deep_extend("force", default_options, opts)

  for k, v in pairs(newconf) do
    M[k] = v
  end
end

setmetatable(M, {
  -- If the user hasn't called setup() yet, make sure we correctly set up the config object so there
  -- aren't random crashes.
  __index = function(self, key)
    if not has_setup then
      M.setup()
    end
    return rawget(self, key)
  end,
})

---@cast M claude.Config
return M
