local M = {}
local raw_require = require

-- Map of lua modules to name of lazy package
local lazy_mods = {}
local patched_require = function(path)
  for pat, package in pairs(lazy_mods) do
    if path:match(pat) then
      M.load(package)
      break
    end
  end
  return raw_require(path)
end

_G.require = patched_require

-- Set of packages that have been loaded
M.loaded = {}
-- Configurations for lazy packages
local lazy_packages = setmetatable({}, {
  __index = function(t, key)
    local newval = {
      dependencies = {},
      modules = {},
      commands = {},
      keymaps = {},
      pre_config = {},
      post_config = {},
      req = nil,
    }
    rawset(t, key, newval)
    return newval
  end,
})
-- map of filetype to list of lazy packages
local lazy_filetypes = setmetatable({}, {
  __index = function(t, key)
    local newlist = {}
    rawset(t, key, newlist)
    return newlist
  end,
})
local filetype_autocmd_id

---@param package string
---@param opts table
---    commands nil|string[]
---    modules nil|string[] List of patterns that match lua modules. When require-d, lazy load.
---    keymaps nil|table[] List of {mode, lhs, rhs, [opts]}
---    filetypes nil|string[]
---    dependencies nil|string[] Packages that must be loaded first
---    pre_config nil|fun()
---    post_config nil|fun()
local function lazy(package, opts)
  if M.loaded[package] then
    if opts.pre_config then
      vim.notify(
        string.format("Cannot run pre_config for package %s: package already loaded", package),
        vim.log.levels.WARN
      )
    end
    if opts.post_config then
      local module
      if opts.req then
        local ok, mod = pcall(require, opts.req)
        if ok then
          module = mod
        end
      end
      opts.post_config(module)
    end
    return
  end
  if opts.commands then
    for _, cmd in ipairs(opts.commands) do
      vim.api.nvim_create_user_command(cmd, function(args)
        M.load(package)
        local commands = vim.api.nvim_get_commands({ builtin = false })
        local def = commands[cmd]
        local run_cmd = { cmd = cmd, args = args.fargs }
        if def.register then
          run_cmd.reg = args.reg
        end
        if def.bang then
          run_cmd.bang = args.bang
        end
        if def.count then
          run_cmd.count = args.count
        end
        if def.range then
          run_cmd.range = args.range
        end
        vim.api.nvim_cmd(run_cmd, {})
      end, {
        nargs = "*",
        bar = true,
        bang = true,
        range = true,
        complete = "file",
      })
    end
  end

  if opts.modules then
    for _, mod in ipairs(opts.modules) do
      if not _G.package.loaded[mod] then
        lazy_mods[mod] = package
      end
    end
  end

  if opts.filetypes then
    if not filetype_autocmd_id then
      filetype_autocmd_id = vim.api.nvim_create_autocmd("FileType", {
        desc = "Lazy load packages",
        pattern = "*",
        callback = function(params)
          local ft = params.match
          for _, subtype in ipairs(vim.split(ft, ".", { plain = true, trimempty = true })) do
            for _, pkg in ipairs(lazy_filetypes[subtype]) do
              M.load(pkg)
            end
          end
        end,
      })
    end
    if type(opts.filetypes) == "string" then
      opts.filetypes = { opts.filetypes }
    end
    for _, ft in ipairs(opts.filetypes) do
      table.insert(lazy_filetypes[ft], package)
    end
  end

  if opts.keymaps then
    for _, conf in ipairs(opts.keymaps) do
      M.keymap(package, unpack(conf))
    end
  end

  local config = lazy_packages[package]
  vim.list_extend(config.dependencies, opts.dependencies or {})
  vim.list_extend(config.modules, opts.modules or {})
  vim.list_extend(config.commands, opts.commands or {})
  vim.list_extend(config.keymaps, opts.keymaps or {})
  if opts.pre_config then
    table.insert(config.pre_config, opts.pre_config)
  end
  if opts.post_config then
    table.insert(config.post_config, opts.post_config)
  end
  if config.req and opts.req and config.req ~= opts.req then
    vim.notify(string.format("Cannot overwrite lazy req '%s' with '%s'", config.req, opts.req), vim.log.levels.ERROR)
  else
    config.req = config.req or opts.req
  end
end

---@param package string
---@param modes string|string[]
---@param lhs string
---@param rhs any
---@param opts nil|table
M.keymap = function(package, modes, lhs, rhs, opts)
  if M.loaded[package] then
    vim.keymap.set(modes, lhs, rhs, opts)
    return
  end
  table.insert(lazy_packages[package].keymaps, { modes, lhs, rhs, opts })
  vim.keymap.set(modes, lhs, function()
    M.load(package)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, true, true), "t", false)
  end, opts)
end

---@param package string
local function packadd(package)
  local ok, err = pcall(vim.cmd.packadd, { args = { package }, bang = not vim.v.vim_did_enter })
  if not ok then
    vim.notify_once(string.format("Error loading package %s: %s", package, err), vim.log.levels.ERROR)
  end
end

---@param package string
M.load = function(package)
  local opts = lazy_packages[package]
  if not opts then
    if not M.loaded[package] then
      packadd(package)
      M.loaded[package] = true
    end
    return
  end
  lazy_packages[package] = nil
  M.loaded[package] = true
  for _, dep in ipairs(opts.dependencies) do
    M.load(dep)
  end
  for _, mod in ipairs(opts.modules) do
    lazy_mods[mod] = nil
  end
  for _, cmd in ipairs(opts.commands) do
    -- FIXME have to do this to play nice with remote plugins
    -- vim.api.nvim_del_user_command(cmd)
  end
  for _, conf in ipairs(opts.keymaps) do
    local mode, lhs, rhs, keyopts = unpack(conf)
    vim.keymap.del(mode, lhs, keyopts)
    vim.keymap.set(mode, lhs, rhs, keyopts)
  end
  for _, cb in ipairs(opts.pre_config) do
    cb()
  end
  packadd(package)
  local module
  local call_post_config = true
  if opts.req then
    local ok, mod = pcall(require, opts.req)
    if ok then
      module = mod
    else
      vim.notify_once(string.format("Missing module: %s", opts.req), vim.log.levels.WARN)
      call_post_config = false
    end
  end
  if call_post_config then
    for _, cb in ipairs(opts.post_config) do
      cb(module)
    end
  end
end

---Require one or more modules
---@example
--- safe_require("foo").setup({})
--- safe_require("foo", "bar", function(foo, bar)
---   foo.setup({arg = bar})
--- end)
M.require = function(...)
  local args = { ... }
  local mods = {}
  local first_mod
  for _, arg in ipairs(args) do
    if type(arg) == "function" then
      arg(unpack(mods))
      break
    end
    local ok, mod = pcall(patched_require, arg)
    if ok then
      if not first_mod then
        first_mod = mod
      end
      table.insert(mods, mod)
    else
      vim.notify_once(string.format("Missing module: %s", arg), vim.log.levels.WARN)
      -- Return a dummy item that returns functions, so we can do things like
      -- safe_require("module").setup()
      local dummy = {}
      setmetatable(dummy, {
        __call = function()
          return dummy
        end,
        __index = function()
          return dummy
        end,
      })
      return dummy
    end
  end
  return first_mod
end

setmetatable(M, {
  __call = function(_, ...)
    return lazy(...)
  end,
})

return M
