-- To customize, add a local_projects.lua file to the runtimepath/lua directory and inside of it add
-- require('projects')['/path/to/proj'] = { autoformat = false }

local defaults = {
  autoformat = true, -- true|false|'directive'
  autoformat_threshold = 10000,
  prettier_prefix = "yarn --silent ",
  ts_prettier_format = true,
  lualine_message = function() return '' end,
  find_files = function(opts)
    opts = opts or {}
    opts.previewer = false
    require('telescope.builtin').find_files(opts)
  end
}

local M = {
  ["_"] = defaults,
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

    local dirs = vim.tbl_keys(M)
    table.sort(dirs)
    local proj = vim.deepcopy(defaults)
    for _,dir in ipairs(dirs) do
      if string.sub(key, 0, string.len(dir)) == dir then
        proj = vim.tbl_deep_extend('force', proj, M[dir])
      end
    end


    return proj
  end,
})

return M
