local M = {}

local default_config = {
  bufferline = {
    enabled = true,
    icon = {
      dividers = { "▍", "" },
      -- dividers = { " ", " " },
      scroll = { "«", "»" },
      pin = "車",
    },
    scope_by_directory = true,
  },
  windows = {
    enabled = true,
    winwidth = function(winid)
      local bufnr = vim.api.nvim_win_get_buf(winid)
      return math.max(vim.api.nvim_buf_get_option(bufnr, "textwidth"), 80)
    end,
    winheight = 10,
  },
  projects = {
    enabled = true,
    filename = "projects.json",
    -- When true, automatically add directories entered as projects
    autoadd = true,
    -- List of lua patterns. If any match the directory, it will be allowed as a project
    allowlist = {},
    -- List of lua patterns. If any match the directory, it will be ignored as a project
    blocklist = {},
    -- Return true to allow a directory as a project
    filter_dir = function(dir)
      return true
    end,
  },
}

M.setup = function(opts)
  local new_conf = vim.tbl_deep_extend("force", default_config, opts or {})
  for k, v in pairs(new_conf) do
    M[k] = v
  end
end

return M
