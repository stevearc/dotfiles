-- To customize, add a local_projects.lua file to the runtimepath/lua directory and inside of it add
-- require('projects')['/path/to/proj'] = { autoformat = false }

local M = {
  ["_"] = {
    autoformat = true, -- true|false|'directive'
    autoformat_threshold = 10000,
    prettier_prefix = "yarn --silent ",
    ts_prettier_format = true,
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
      local bufnr = key
      key = vim.api.nvim_buf_get_name(bufnr)
      if key == "" or vim.api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
        key = vim.fn.getcwd()
      end
    end

    local proj = rawget(self, key)
    local maxlen = 0
    if not proj then
      for dir, config in pairs(self) do
        if string.len(dir) > maxlen and string.sub(key, 0, string.len(dir)) == dir then
          maxlen = string.len(dir)
          proj = config
        end
      end
    end

    return proj or self._
  end,
})

return M
