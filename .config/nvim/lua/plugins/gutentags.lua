local function is_plugged_in()
  local is_mac = vim.uv.os_uname().sysname == "Darwin"
  if is_mac then
    local ret = vim.system({ "pmset", "-g", "ps" }, { timeout = 1000 }):wait()
    if ret.code == 0 and ret.stdout and ret.stdout:find("AC Power") then
      return true
    else
      return false
    end
  else
    return true
  end
end

---@param root string
---@return nil|string
local function load_rev(root)
  local file = root .. "/tags.rev"
  if not vim.uv.fs_stat(file) then
    return
  end
  local f = assert(io.open(file, "r"))
  local rev = vim.trim(f:read("*a"))
  f:close()
  return rev
end

---@param root string
---@param rev string
local function save_rev(root, rev)
  local file = root .. "/tags.rev"
  local f = assert(io.open(file, "w"))
  f:write(rev)
  f:close()
end

---@param root string
---@return string
local function get_current_rev(root)
  local ret = vim.system({ "git", "rev-parse", "HEAD" }, { cwd = root, timeout = 1000 }):wait()
  if ret.code == 0 and ret.stdout then
    return vim.trim(ret.stdout)
  else
    return "ERROR"
  end
end

local function update_project_tags()
  if not is_plugged_in() then
    return
  end
  local root = vim.fs.root(0, ".git")
  if not root then
    return
  end
  local last_updated_rev = load_rev(root)
  local current_rev = get_current_rev(root)
  if last_updated_rev == current_rev then
    return
  end
  local ok = pcall(vim.cmd.GutentagsUpdate, { bang = true })
  if ok then
    save_rev(root, current_rev)
  end
end

return {
  "ludovicchabant/vim-gutentags",
  cond = function() return vim.fn.executable("ctags") == 1 end,
  init = function()
    -- vim.g.gutentags_enabled = false
    vim.g.gutentags_generate_on_new = false
    vim.g.gutentags_file_list_command = "rg --files"

    local aug = vim.api.nvim_create_augroup("Gutentags", { clear = true })
    vim.api.nvim_create_autocmd("DirChanged", {
      desc = "Update tags on directory change",
      group = aug,
      callback = update_project_tags,
    })
    local timer = vim.uv.new_timer()
    -- maybe update project tags 10 seconds after startup, then every 4 minutes
    timer:start(10 * 1000, 240 * 1000, vim.schedule_wrap(update_project_tags))
  end,
}
