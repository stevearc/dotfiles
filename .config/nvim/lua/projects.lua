-- To customize, add a local_projects.lua file to the runtimepath/lua directory and inside of it add
-- require('projects')['/path/to/proj'] = { autoformat = false }

local M = {
  ["_"] = {
    autoformat = true, -- true|false|'directive'
    autoformat_threshold = 10000,
    prettier_prefix = "yarn --silent ",
  },
}

local loaded_local = false
setmetatable(M, {
  __index = function(self, key)
    if not loaded_local then
      pcall(require, "local_projects")
      loaded_local = true
    end
    if type(key) == "number" then
      key = vim.api.nvim_buf_get_name(key)
      if key == "" then
        key = vim.fn.getcwd()
      end
    end

    local proj = rawget(self, key)
    local maxlen = 0
    if not proj then
      for dir, config in pairs(self) do
        if string.find(key, dir) == 1 and string.len(dir) > maxlen then
          maxlen = string.len(dir)
          proj = config
        end
      end
    end

    return proj or self._
  end,
})

return M
