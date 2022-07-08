---@class FiletypeConfig
---@field abbr? table<string, string> Insert-mode abbreviations
---@field bindings? table Buffer-local keymaps
---@field bufvar? table<string, any> Buffer-local variables
---@field callback? fun(bufnr: integer)
---@field opt? table<string, any> Buffer-local or window-local options

local M = {}

local builtin_win_opt_values = {
  arabic = false,
  breakindent = false,
  breakindentopt = "",
  cursorcolumn = false,
  concealcursor = "",
  conceallevel = 0,
  cursorbind = false,
  cursorline = false,
  cursorlineopt = "number,line",
  diff = false,
  fillchars = "",
  foldcolumn = "0",
  foldenable = true,
  foldexpr = "0",
  foldignore = "#",
  foldlevel = 0,
  foldmarker = "{{{,}}}",
  foldmethod = "manual",
  foldminlines = 1,
  foldnestmax = 20,
  foldtext = "foldtext()",
  linebreak = false,
  list = false,
  listchars = "tab:> ,trail:-,nbsp:+",
  number = false,
  numberwidth = 4,
  previewwindow = false,
  relativenumber = false,
  rightleft = false,
  rightleftcmd = "search",
  scroll = 0,
  scrollbind = false,
  scrolloff = 0,
  showbreak = "",
  sidescrolloff = 0,
  signcolumn = "auto",
  spell = false,
  statusline = "",
  virtualedit = "",
  winblend = 0,
  winhighlight = "",
  winfixheight = false,
  winfixwidth = false,
  wrap = true,
}

local window_opts = {}
for k in pairs(builtin_win_opt_values) do
  window_opts[k] = true
end

---@type table<string, FiletypeConfig>
local configs = {}

---@type table<string, any>
local default_win_opts = {}

---Set the config for a filetype
---@param name string
---@param config FiletypeConfig
M.set = function(name, config)
  configs[name] = config
end

---Get a filetype config
---@param name string
---@return FiletypeConfig|nil
M.get = function(name)
  return configs[name]
end

local function merge_callbacks(fn1, fn2)
  if not fn1 and not fn2 then
    return nil
  end
  if fn1 then
    if fn2 then
      return function(...)
        fn1(...)
        fn2(...)
      end
    else
      return fn1
    end
  else
    return fn2
  end
end

local function merge_bindings(b1, b2)
  if not b1 then
    return b2
  elseif not b2 then
    return b1
  end
  return vim.list_extend(b1, b2)
end

---Extend the configuration for a filetype, overriding values that conflict
---@param name string
---@param new_config FiletypeConfig
M.extend = function(name, new_config)
  local conf = configs[name] or {}
  conf.abbr = vim.tbl_deep_extend("force", conf.abbr or {}, new_config.abbr or {})
  conf.opt = vim.tbl_deep_extend("force", conf.opt or {}, new_config.opt or {})
  conf.bufvar = vim.tbl_deep_extend("force", conf.bufvar or {}, new_config.bufvar or {})
  conf.callback = merge_callbacks(conf.callback, new_config.callback)
  conf.bindings = merge_bindings(conf.bindings, new_config.bindings)
end

---Set many configs all at once
---@param confs table<string, FiletypeConfig>
M.set_all = function(confs)
  for k, v in pairs(confs) do
    configs[k] = v
  end
end

---Extend many configs all at once
---@param confs table<string, FiletypeConfig>
M.extend_all = function(confs)
  for k, v in pairs(confs) do
    M.extend(k, v)
  end
end

---@param name string
---@param winid integer
---@return string[]
local function _apply_win(name, winid)
  local conf = configs[name]
  if not conf then
    return {}
  end
  local ret = {}
  if conf.opt then
    for k, v in pairs(conf.opt) do
      if window_opts[k] then
        local ok, err = pcall(vim.api.nvim_win_set_option, winid, k, v)
        if ok then
          table.insert(ret, k)
        else
          vim.notify(
            string.format("Error setting window option %s = %s: %s", k, vim.inspect(v), err),
            vim.log.levels.ERROR
          )
        end
      end
    end
  end
  return ret
end

---Apply window options
---@param name string
---@param winid integer
M.apply_win = function(name, winid)
  local ok, prev_overrides = pcall(vim.api.nvim_win_get_var, winid, "__ftplugin_overrides")
  local pieces = vim.split(name, ".", true)
  local win_overrides = {}
  if #pieces > 1 then
    for _, ft in ipairs(pieces) do
      vim.list_extend(win_overrides, _apply_win(ft, winid))
    end
  else
    win_overrides = _apply_win(name, winid)
  end

  -- Restore previous window overrides to the global value
  -- TODO should we instead revert ALL window options?
  if ok and prev_overrides then
    for _, opt in ipairs(prev_overrides) do
      if not vim.tbl_contains(win_overrides, opt) then
        -- Revert to the default if we have one
        if default_win_opts[opt] then
          vim.api.nvim_win_set_option(winid, opt, default_win_opts[opt])
        else
          -- Otherwise try to revert to the global value (if present)
          local has_global, global = pcall(vim.api.nvim_get_option, opt)
          if has_global then
            vim.api.nvim_win_set_option(winid, opt, global)
          end
        end
      end
    end
  end
  vim.api.nvim_win_set_var(winid, "__ftplugin_overrides", win_overrides)
end

---Apply all filetype configs for a buffer
---@param name string
---@param bufnr integer
M.apply = function(name, bufnr)
  local pieces = vim.split(name, ".", true)
  if #pieces > 1 then
    for _, ft in ipairs(pieces) do
      M.apply(ft, bufnr)
    end
    return
  end
  local conf = configs[name]
  if not conf then
    return
  end
  if conf.abbr then
    vim.api.nvim_buf_call(bufnr, function()
      for k, v in pairs(conf.abbr) do
        vim.cmd(string.format("iabbr <buffer> %s %s", k, v))
      end
    end)
  end
  if conf.opt then
    for k, v in pairs(conf.opt) do
      if not window_opts[k] then
        local ok, err = pcall(vim.api.nvim_buf_set_option, bufnr, k, v)
        if not ok then
          vim.notify(
            string.format("Error setting buffer option %s = %s: %s", k, vim.inspect(v), err),
            vim.log.levels.ERROR
          )
        end
      end
    end
    local winids = vim.tbl_filter(function(win)
      return vim.api.nvim_win_get_buf(win) == bufnr
    end, vim.api.nvim_list_wins())
    for _, winid in ipairs(winids) do
      M.apply_win(name, winid)
    end
  end
  if conf.bufvar then
    for k, v in pairs(conf.bufvar) do
      vim.api.nvim_buf_set_var(bufnr, k, v)
    end
  end
  if conf.bindings then
    for _, defn in ipairs(conf.bindings) do
      local mode, lhs, rhs, opts = unpack(defn)
      opts = vim.tbl_deep_extend("force", opts or {}, {
        buffer = bufnr,
      })
      vim.keymap.set(mode, lhs, rhs, opts)
    end
  end
  if conf.callback then
    conf.callback(bufnr)
  end
end

---@class FiletypeOpts
---@field augroup? string|integer Autogroup to use when creating the autocmds
---@field default_win_opts? table<string, any> Default window-local option values to revert to when leaving a window

---Create autocommands that will apply the configs
---@param opts? FiletypeOpts
M.setup = function(opts)
  local conf = vim.tbl_deep_extend("keep", opts or {}, {
    augroup = nil,
    default_win_opts = {},
  })
  -- Pick up the existing option values
  for k in pairs(builtin_win_opt_values) do
    if conf.default_win_opts[k] == nil then
      local ok, global_val = pcall(vim.api.nvim_get_option, k)
      if ok then
        conf.default_win_opts[k] = global_val
      else
        local local_ok, local_val = pcall(vim.api.nvim_win_get_option, 0, k)
        if local_ok then
          conf.default_win_opts[k] = local_val
        end
      end
    end
  end
  default_win_opts = vim.tbl_deep_extend("force", builtin_win_opt_values, conf.default_win_opts)

  vim.api.nvim_create_autocmd("FileType", {
    desc = "Set filetype-specific options",
    pattern = "*",
    group = conf.augroup,
    callback = function(params)
      M.apply(params.match, params.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    desc = "Set filetype-specific window options",
    pattern = "*",
    group = conf.augroup,
    callback = function(params)
      local winid = vim.api.nvim_get_current_win()
      local bufnr = vim.api.nvim_win_get_buf(winid)
      local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
      M.apply_win(filetype, winid)
    end,
  })
end

return M
