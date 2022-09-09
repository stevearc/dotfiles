local M = {}

local dirs = {}
local sep = package.config:sub(1, 1)
local function get_cache_file()
  local cache_dir = vim.fn.stdpath("cache")
  return cache_dir .. sep .. "recent_dirs.json"
end

M.load_cache = function()
  local filename = get_cache_file()
  local file = io.open(filename, "r")
  if file then
    local ok, data = pcall(file.read, file)
    if ok then
      dirs = vim.json.decode(data)
    end
    file:close()
    local to_remove = {}
    for k in pairs(dirs) do
      if vim.fn.isdirectory(k) == 0 then
        table.insert(to_remove, k)
      end
    end
    if not vim.tbl_isempty(to_remove) then
      for _, v in ipairs(to_remove) do
        dirs[v] = nil
      end
      M.save_cache()
    end
  end
end

M.save_cache = function()
  local filename = get_cache_file()
  local file = io.open(filename, "w")
  if file then
    file:write(vim.json.encode(dirs))
    file:close()
  end
end

M.record_dir = function(dir)
  dirs[dir] = 1
  M.save_cache()
end

M.remove_dir = function(dir)
  dirs[dir] = nil
  M.save_cache()
end

M.get_dirs = function()
  return vim.tbl_keys(dirs)
end

return M
