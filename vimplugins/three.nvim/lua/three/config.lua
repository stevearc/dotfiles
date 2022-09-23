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
    autoadd = true,
    allowlist = {},
    blocklist = {},
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
