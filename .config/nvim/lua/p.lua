local M = {}
local raw_require = require

-- Map of lua modules to name of lazy package
local lazy_mods = {}
local patched_require = function(path)
  -- If module is already loaded, return it (performance optimization)
  local ret = package.loaded[path]
  if ret then
    return ret
  end
  for pat, package in pairs(lazy_mods) do
    if path:match(pat) then
      M.load(package)
      break
    end
  end
  return raw_require(path)
end

_G.require = patched_require

local default_opts = {
  disable = false,
}
local gopts = vim.deepcopy(default_opts)

-- Set of packages that have been loaded
M.loaded = {}
-- Configurations for lazy packages
local lazy_packages = {}
function lazy_packages.get_or_create(package)
  local ret = lazy_packages[package]
  if not ret then
    ret = {
      autocmd_ids = {},
      dependencies = {},
      modules = {},
      commands = {},
      keymaps = {},
      pre_config = {},
      post_config = {},
      req = nil,
    }
    lazy_packages[package] = ret
  end
  return ret
end
-- map of filetype to list of lazy packages
local lazy_filetypes = setmetatable({}, {
  __index = function(t, key)
    local newlist = {}
    rawset(t, key, newlist)
    return newlist
  end,
})
local filetype_autocmd_id

---@param filetype string
local function maybe_load_filetype(filetype)
  for _, subtype in ipairs(vim.split(filetype, ".", { plain = true, trimempty = true })) do
    for _, pkg in ipairs(lazy_filetypes[subtype]) do
      M.load(pkg)
    end
  end
end

---@param req nil|string|string[]
---@param post_configs nil|string|fun()|string[]|fun()[] Function or name of lua module that returns a function. Called after packadd
local function call_post_config(req, post_configs)
  if not post_configs then
    return
  end
  local function do_setup(...)
    if type(post_configs) ~= "table" then
      post_configs = { post_configs }
    end
    for _, cb in ipairs(post_configs) do
      if type(cb) == "string" then
        local found_cb, mod_cb = pcall(require, cb)
        if found_cb then
          mod_cb(...)
        else
          vim.notify(string.format("Error requiring post_config callback '%s'", cb))
        end
      else
        cb(...)
      end
    end
  end
  if not req then
    do_setup()
  elseif type(req) == "string" then
    M.require(req, do_setup)
  else
    M.require(unpack(req), do_setup)
  end
end

---@param package string
---@return boolean
local function packadd(package)
  -- print("Loading", package)
  local ok, err = pcall(vim.cmd.packadd, { args = { package }, bang = not vim.v.vim_did_enter })
  if not ok then
    vim.notify_once(string.format("Error loading package %s: %s", package, err), vim.log.levels.ERROR)
  end
  return ok
end

---@param package string
---@param opts table
---    commands nil|string[]
---    modules nil|string[] List of patterns that match lua modules. When require-d, lazy load.
---    keymaps nil|table[] List of {mode, lhs, rhs, [opts]}
---    filetypes nil|string[]
---    autocmds nil|table<string, table> Mapping of autocmd names to autocmd configs
---    dependencies nil|string[] Packages that must be loaded first
---    pre_config nil|fun() Function to be called before packadd
---    req nil|string|string[] module(s) to require and pass in to post_config
---    post_config nil|string|fun() Function or name of lua module that returns a function. Called after packadd
local function lazy(package, opts)
  if gopts.disable then
    if opts.dependencies then
      for _, dep in ipairs(opts.dependencies) do
        M.load(dep)
      end
    end
    packadd(package)
    for _, conf in ipairs(opts.keymaps or {}) do
      local mode, lhs, rhs, keyopts = unpack(conf)
      vim.keymap.set(mode, lhs, rhs, keyopts)
    end
    call_post_config(opts.req, opts.post_config)
    return
  elseif M.loaded[package] then
    if opts.dependencies then
      for _, dep in ipairs(opts.dependencies) do
        M.load(dep)
      end
    end
    if opts.pre_config then
      vim.notify(
        string.format("Cannot run pre_config for package %s: package already loaded", package),
        vim.log.levels.WARN
      )
    end
    call_post_config(opts.req, opts.post_config)
    for _, conf in ipairs(opts.keymaps or {}) do
      local mode, lhs, rhs, keyopts = unpack(conf)
      vim.keymap.set(mode, lhs, rhs, keyopts)
    end
    return
  end

  local autocmd_ids = {}
  if opts.autocmds then
    for autocmd, conf in pairs(opts.autocmds) do
      local autocmd_id = vim.api.nvim_create_autocmd(
        autocmd,
        vim.tbl_extend("keep", conf, {
          desc = string.format("Lazily load %s", package),
          callback = function()
            M.load(package)
          end,
        })
      )
      table.insert(autocmd_ids, autocmd_id)
    end
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
          maybe_load_filetype(params.match)
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

  local config = lazy_packages.get_or_create(package)
  vim.list_extend(config.autocmd_ids, autocmd_ids)
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

  maybe_load_filetype(vim.bo.filetype)
end

M.setup = function(opts)
  gopts = vim.tbl_deep_extend("keep", opts or {}, default_opts)
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
  table.insert(lazy_packages.get_or_create(package).keymaps, { modes, lhs, rhs, opts })
  vim.keymap.set(modes, lhs, function()
    M.load(package)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, true, true), "t", false)
  end, opts)
end

---@param package string
M.load = function(package, ...)
  if select("#", ...) > 0 then
    M.load(package)
    for _, p in ipairs({ ... }) do
      M.load(p)
    end
    return M
  end
  local opts = lazy_packages[package]
  if not opts then
    if not M.loaded[package] then
      packadd(package)
      M.loaded[package] = true
    end
    return M
  end
  lazy_packages[package] = nil
  M.loaded[package] = true
  for _, autocmd_id in ipairs(opts.autocmd_ids) do
    vim.api.nvim_del_autocmd(autocmd_id)
  end
  for _, dep in ipairs(opts.dependencies) do
    M.load(dep)
  end
  for _, mod in ipairs(opts.modules) do
    lazy_mods[mod] = nil
  end
  for _, cmd in ipairs(opts.commands) do
    vim.api.nvim_del_user_command(cmd)
  end
  for _, conf in ipairs(opts.keymaps) do
    local mode, lhs, rhs, keyopts = unpack(conf)
    vim.keymap.del(mode, lhs, keyopts)
    vim.keymap.set(mode, lhs, rhs, keyopts)
  end
  for _, cb in ipairs(opts.pre_config) do
    cb()
  end
  if not packadd(package) then
    return M
  end
  call_post_config(opts.req, opts.post_config)
  return M
end

---@param opts table
---    keymaps nil|table[] List of {mode, lhs, rhs, [opts]}
---    req nil|string|string[] module(s) to require and pass in to post_config
---    post_config nil|string|fun() Function or name of lua module that returns a function. Called after packadd
M.multi = function(...)
  local packages = { ... }
  table.remove(packages)
  local opts = select(select("#", ...), ...)

  local all_loaded = not vim.tbl_isempty(packages)
  for _, package in ipairs(packages) do
    all_loaded = all_loaded and M.loaded[package]
  end

  if opts.keymaps then
    local function do_load()
      for _, conf in ipairs(opts.keymaps) do
        local modes, lhs, _, keyopts = unpack(conf)
        vim.keymap.del(modes, lhs, keyopts)
        vim.keymap.set(unpack(conf))
      end
      for _, package in ipairs(packages) do
        M.load(package)
        if not M.loaded[package] then
          return
        end
      end
      call_post_config(opts.req, opts.post_config)
    end

    for _, conf in ipairs(opts.keymaps) do
      if all_loaded then
        vim.keymap.set(unpack(conf))
      else
        local modes, lhs, _, keyopts = unpack(conf)
        vim.keymap.set(modes, lhs, function()
          do_load()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, true, true), "t", false)
        end, keyopts)
      end
    end
  end
  if all_loaded then
    call_post_config(opts.req, opts.post_config)
  end
end

---Require one or more modules
---@example
--- p.require("foo").setup({})
--- p.require("foo", "bar", function(foo, bar)
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
      -- lazy.require("module").setup()
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
