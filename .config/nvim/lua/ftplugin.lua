---@class FiletypeConfig
---@field buf? table<string, any>
---@field win? table<string, any>
---@field callback? fun(bufnr: integer)
---@field bindings? table

local M = {}

local configs = {}

---@param name string
---@param config FiletypeConfig
M.set = function(name, config)
  configs[name] = config
end

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

---@param name string
---@param new_config FiletypeConfig
M.extend = function(name, new_config)
  local conf = configs[name] or {}
  conf.buf = vim.tbl_deep_extend('force', conf.buf or {}, new_config.buf or {})
  conf.win = vim.tbl_deep_extend('force', conf.win or {}, new_config.win or {})
  conf.callback = merge_callbacks(conf.callback, new_config.callback)
  conf.bindings = merge_bindings(conf.bindings, new_config.bindings)
end

---@param configs table<string, FiletypeConfig>
M.set_all = function(confs)
  for k,v in pairs(confs) do
    configs[k] = v
  end
end

---@param name string
---@param winid integer
M.apply_win = function(name, winid)
  local pieces = vim.split(name, '.', true)
  if #pieces > 1 then
    for _,ft in ipairs(pieces) do
      M.apply_win(ft, winid)
    end
    return
  end
  -- TODO restore default options
  local conf = configs[name]
  if not conf then
    return
  end
  if conf.win then
    for k,v in pairs(conf.win) do
      vim.api.nvim_win_set_option(winid, k, v)
    end
  end
end

---@param name string
---@param bufnr integer
M.apply = function(name, bufnr)
  local pieces = vim.split(name, '.', true)
  if #pieces > 1 then
    for _,ft in ipairs(pieces) do
      M.apply(ft, bufnr)
    end
    return
  end
  local conf = configs[name]
  if not conf then
    return
  end
  if conf.buf then
    for k,v in pairs(conf.buf) do
      vim.api.nvim_buf_set_option(bufnr, k, v)
    end
  end
  if conf.bindings then
    for _,defn in ipairs(conf.bindings) do
      local mode, lhs, rhs, opts = unpack(defn)
      opts = vim.tbl_deep_extend('force', opts or {}, {
        buffer = bufnr,
      })
      vim.keymap.set(mode, lhs, rhs, opts)
    end
  end
  if conf.win then
    local winids = vim.tbl_filter(function(win)
      return vim.api.nvim_win_get_buf(win) == bufnr
    end, vim.api.nvim_list_wins())
    for _, winid in ipairs(winids) do
      M.apply_win(name, winid)
    end
  end
  if conf.callback then
    conf.callback(bufnr, winid)
  end
end

M.create_autocmds = function(group)
  vim.api.nvim_create_autocmd('FileType', {
    desc = 'Set filetype-specific options',
    pattern = '*',
    group = group,
    callback = function(params)
      M.apply(params.match, params.buf)
    end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    desc = 'Set filetype-specific window options',
    pattern = '*',
    group = group,
    callback = function(params)
      local winid = vim.api.nvim_get_current_win()
      local bufnr = vim.api.nvim_win_get_buf(winid)
      local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
      M.apply_win(filetype, winid)
    end,
  })
end

return M
