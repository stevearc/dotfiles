local default_options = {
  on_create = function() end,
  review = {
    wrap = true,
    wrap_navigation = true,
    default_register = '"',
    submit_prompt = "Address the following code review comments:\n\n%s",
  },
}

---@class agents.Config
---@field on_create fun(proc: AgentsProcess)
local M = {}

---@class (exact) agents.SetupOpts
---@field on_create? fun(proc: AgentsProcess)
---@field review? {wrap?:boolean, wrap_navigation?:boolean, default_register?:string, submit_prompt?:string}

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

---@cast M agents.Config
return M
