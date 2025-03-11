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

local timer = vim.uv.new_timer()

---@param root string
local function update_tags(root)
  local ok, overseer = pcall(require, "overseer")
  if not ok then
    timer:stop()
    return
  end
  local task = overseer.new_task({
    name = "ctags " .. root,
    cmd = "rg --files | ctags -f tags.temp --links=no -L -",
    cwd = root,
    components = {
      { "on_complete_notify", statuses = { "FAILURE" }, system = "unfocused" },
      "unique",
      { "on_complete_dispose", statuses = { "SUCCESS", "CANCELED" }, timeout = 5 },
      "default",
    },
  })
  task:subscribe("on_complete", function(_, status)
    if status == "SUCCESS" then
      if vim.fn.rename(root .. "/tags.temp", root .. "/tags") ~= 0 then
        vim.notify("Failed to rename tags.temp to tags", vim.log.levels.ERROR)
      end
    end
  end)
  task:start()
end

local function is_supported()
  -- Disabling this for now
  return false
  -- return is_plugged_in() and vim.fn.executable("ctags") == 1 and vim.fn.executable("rg") == 1
end

local function update_project_tags()
  if not is_supported() then
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
  update_tags(root)
  save_rev(root, current_rev)
end

vim.api.nvim_create_autocmd("DirChanged", {
  desc = "Update tags on directory change",
  group = "StevearcNewConfig",
  callback = update_project_tags,
})

-- maybe update project tags 10 seconds after startup, then every 4 minutes
timer:start(10 * 1000, 240 * 1000, vim.schedule_wrap(update_project_tags))
