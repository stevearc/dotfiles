local root_config = require("three.config")
local util = require("three.util")

local config = setmetatable({}, {
  __index = function(_, key)
    return root_config.projects[key]
  end,
})

local M = {}

local projects
local loaded = false

local function get_cache_file()
  return util.join(vim.fn.stdpath("cache"), config.filename)
end

local function format_project(project)
  local home = os.getenv("HOME")
  local idx, chars = string.find(project, home)
  if idx == 1 then
    return "~" .. string.sub(project, idx + chars)
  else
    return project
  end
end

---@param dirs string[]
local function save_projects(dirs)
  local filename = get_cache_file()
  local file = io.open(filename, "w")
  if file then
    file:write(vim.json.encode({
      projects = dirs,
    }))
    file:close()
  end
end

---@return string[]
local function load_projects()
  local filename = get_cache_file()
  local file = io.open(filename, "r")
  if not file then
    return {}
  end
  local ok, data = pcall(file.read, file)
  local data = ok and vim.json.decode(data)
  file:close()
  if not data then
    return {}
  end
  local ret = vim.tbl_filter(function(dir)
    return vim.fn.isdirectory(dir) == 1
  end, data.projects)
  if #ret ~= #data.projects then
    save_projects(ret)
  end
  return ret
end

local function load()
  if not loaded then
    projects = load_projects()
    loaded = true
  end
end

---@param patterns string[]
---@param needle string
local function any_match(patterns, needle)
  for _, pattern in ipairs(patterns) do
    if needle:match(pattern) then
      return true
    end
  end
  return false
end

---@param project string
M.add_project = function(project)
  load()
  if not vim.tbl_isempty(config.allowlist) then
    if not any_match(config.allowlist, project) then
      return
    end
  end
  if any_match(config.blocklist, project) then
    return
  end
  if not config.filter_dir(project) then
    return
  end
  if not vim.tbl_contains(projects, project) then
    table.insert(projects, project)
    table.sort(projects)
    save_projects(projects)
  end
end

---@param project nil|string
M.remove_project = function(project)
  load()
  if not project then
    M.select_project({ prompt = "Delete project" }, function(selected)
      if selected then
        M.remove_project(selected)
      end
    end)
    return
  end
  local idx = util.tbl_index(projects, project)
  if idx then
    table.remove(projects, idx)
    save_projects(projects)
  end
end

---@param opts table See :help vim.ui.select
---@param callback fun(project: nil|string)
M.select_project = function(opts, callback)
  load()
  opts = vim.tbl_extend("keep", opts or {}, { prompt = "Select project", format_item = format_project })
  vim.ui.select(projects, opts, callback)
end

---@param project nil|string
M.open_project = function(project)
  if not project then
    M.select_project({ prompt = "Open project" }, function(selected)
      if selected then
        M.open_project(selected)
      end
    end)
    return
  end

  local is_tab_empty = true
  if root_config.bufferline.enabled then
    local state = require("three.bufferline.state")
    local ts = state[0]
    is_tab_empty = vim.tbl_isempty(ts.buffers)
  else
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(winid) then
        local bufnr = vim.api.nvim_win_get_buf(winid)
        if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= "" then
          is_tab_empty = false
          break
        end
      end
    end
  end

  if not is_tab_empty then
    vim.cmd("tabnew")
  end
  vim.cmd("tcd " .. project)
end

---@return string[]
M.list_projects = function()
  load()
  return projects
end

M.setup = function(config)
  local group = vim.api.nvim_create_augroup("three.projects", {})
  if config.autoadd then
    if vim.v.vim_did_enter == 1 then
      recent_dirs.record_dir(vim.loop.cwd())
    end
    vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
      desc = "three.nvim: record project directory",
      group = group,
      callback = function()
        M.add_project(vim.v.event.cwd or vim.loop.cwd())
      end,
    })
  end
  config.allowlist = vim.tbl_map(util.glob_to_pattern, config.allowlist)
  config.blocklist = vim.tbl_map(util.glob_to_pattern, config.blocklist)
end

return M
