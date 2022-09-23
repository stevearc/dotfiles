local M = {}

M.is_windows = vim.loop.os_uname().version:match("Windows")

M.sep = M.is_windows and "\\" or "/"

M.join = function(...)
  return table.concat({ ... }, M.sep)
end

---@param glob string
---@return string
M.glob_to_pattern = function(glob)
  local pattern = glob:gsub("%.", "%%."):gsub("*", ".*")
  return pattern
end

---@return nil|integer
M.tbl_index = function(tbl, needle)
  for i, v in ipairs(tbl) do
    if v == needle then
      return i
    end
  end
end

M.rerender = function()
  vim.cmd("redrawtabline")
end

M.defaultdict = function(default)
  local index
  if type(default) == "function" then
    index = function(_, key)
      return default(key)
    end
  else
    index = function()
      return default
    end
  end
  return setmetatable({}, {
    __index = index,
  })
end

M.remove_duplicates = function(items)
  local count = M.defaultdict(0)
  return vim.tbl_filter(function(item)
    count[item] = count[item] + 1
    return count[item] == 1
  end, items)
end

---@param root string
---@param candidate string
---@return boolean
M.is_subdir = function(root, candidate)
  return candidate ~= "" and candidate:find(root) == 1
end

---@param winid integer
---@return boolean
M.is_floating_win = function(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ""
end

---@param winid integer
---@return boolean
M.is_normal_win = function(winid)
  local ok, stickybuf_util = pcall(require, "stickybuf.util")
  if ok and stickybuf_util.is_sticky_win(winid) then
    return false
  end
  -- Check for non-normal (e.g. popup/preview) windows
  if vim.fn.win_gettype(winid) ~= "" or M.is_floating_win(winid) then
    return false
  end
  -- If winfixwidth or winfixheight, then this is probably a sidebar or tray
  if vim.wo[winid].winfixwidth or vim.wo[winid].winfixheight then
    return false
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local bt = vim.api.nvim_buf_get_option(bufnr, "buftype")

  -- Ignore quickfix, prompt, and help
  return bt ~= "quickfix" and bt ~= "prompt" and bt ~= "help"
end

local function ipairsrev(list)
  local i = #list
  return function()
    if i == 0 then
      return
    end
    local v = list[i]
    local idx = i
    i = i - 1
    return idx, v
  end
end

local PostfixTree = {}

function PostfixTree.new()
  return setmetatable({
    root = {},
    force_fullname = {},
  }, { __index = PostfixTree })
end

---@param name string
---@param pieces string[]
function PostfixTree:insert(name, pieces)
  local lookup = self.root
  for i, v in ipairsrev(pieces) do
    local prev = lookup
    lookup = lookup[v]
    if not lookup then
      -- Insert
      prev[v] = {
        type = "leaf",
        full_name = name,
        pieces = pieces,
        idx = i,
      }
      return
    elseif lookup.type == "leaf" then
      -- Split
      local conflict = lookup
      if conflict.full_name == name then
        -- Completely ignore duplicate names
        return
      end
      lookup = {}
      prev[v] = lookup
      if conflict.idx == 1 then
        -- If the conflicting node is out of pieces, use its full name
        self.force_fullname[conflict.full_name] = true
      else
        -- Otherwise, move it to the new branch we just created
        conflict.idx = conflict.idx - 1
        lookup[conflict.pieces[conflict.idx]] = conflict
      end
    end
  end
  self.force_fullname[name] = true
end

---@param name string
---@param pieces string[]
---@return string
function PostfixTree:get(name, pieces)
  if self.force_fullname[name] then
    return name
  end
  local lookup = self.root
  local ret = ""
  for i, key in ipairsrev(pieces) do
    if ret == "" then
      ret = key
    else
      ret = key .. M.sep .. ret
    end
    lookup = lookup[key]
    if lookup.type == "leaf" then
      if i == 1 then
        return lookup.full_name
      else
        return ret
      end
    end
  end
  error(string.format("Name '%s' not found", name))
end

---@param names string[]
---@return string[]
M.get_unique_names = function(names)
  local tree = PostfixTree.new()
  local all_pieces = {}
  for i, full_name in ipairs(names) do
    local pieces = vim.split(full_name, M.sep, { plain = true, trimempty = true })
    all_pieces[i] = pieces
    tree:insert(full_name, pieces)
  end
  local ret = {}
  for i, name in ipairs(names) do
    local pieces = all_pieces[i]
    ret[i] = tree:get(name, pieces)
  end
  return ret
end

return M
