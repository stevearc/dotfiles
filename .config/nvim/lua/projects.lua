-- To customize, add a local_projects.lua file to the runtimepath/lua directory and inside of it add
-- require('projects')['/path/to/proj'] = { autoformat = false }

local defaults = {
  autoformat = true, -- true|false|'directive'
  autoformat_threshold = 10000,
  prettier_prefix = "yarn --silent ",
  ts_prettier_format = true,
  lsp_settings = {},
}

local M = {
  ["_"] = defaults,
}

function M.add(dir, value)
  local existing = rawget(M, dir)
  if not existing then
    M[dir] = value
  else
    M[dir] = vim.tbl_deep_extend("force", existing, value)
  end
end

local dirs

setmetatable(M, {
  __new_index = function(self, key, value)
    if key == 0 then
      key = vim.fn.getcwd()
    end
    rawset(self, key, value)
    dirs = nil
  end,
  __index = function(self, key)
    if type(key) == "number" then
      local bufnr = key
      key = vim.api.nvim_buf_get_name(bufnr)
      if key == "" or vim.api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
        key = vim.fn.getcwd()
      else
        key = vim.fn.fnamemodify(key, ":p")
      end
    end

    if not dirs then
      dirs = vim.tbl_keys(M)
      table.sort(dirs)
    end

    local proj = vim.deepcopy(defaults)
    for _, dir in ipairs(dirs) do
      if string.sub(key, 0, string.len(dir)) == dir then
        proj = vim.tbl_deep_extend("force", proj, M[dir])
      end
    end

    return proj
  end,
})

return M
