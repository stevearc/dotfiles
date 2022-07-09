---@mod proc
local M = {}

---@class proc.ProcessData
---@field pid integer
---@field command string

---@param str string
---@return string
M.remove_ansi = function(str)
  return str:gsub("\x1b%[[%d;]*%dm", "")
end

M.get_stdout_line_iter = function()
  local pending = ""
  return function(data)
    local ret = {}
    for i, chunk in ipairs(data) do
      if i == 1 then
        if chunk == "" then
          table.insert(ret, pending)
          pending = ""
        else
          pending = pending .. string.gsub(M.remove_ansi(chunk), "\r$", "")
        end
      else
        if data[1] ~= "" then
          table.insert(ret, pending)
        end
        pending = string.gsub(M.remove_ansi(chunk), "\r$", "")
      end
    end
    return ret
  end
end

---@param data table
---@return proc.ProcessData
local function validate_proc(data)
  vim.validate({
    cmd = {data.cmd, 's'},
    pid = {data.pid, 's'},
  })
  data.pid = tonumber(data.pid)
  vim.validate({
    pid = {data.pid, 'n'},
  })
  return data
end

---@param lines string[]
---@return proc.ProcessData[]
local function parse_ps_output(lines)
  local headers = vim.tbl_map(function(h) return h:lower() end, vim.split(vim.trim(lines[1]), '%s+'))
  local pattern_pieces = vim.tbl_map(function(header)
    return header == 'cmd' and '(.+)' or '([^%s]+)'
  end, headers)
  local pattern = '^' .. table.concat(pattern_pieces, '%s+') .. '$'
  local ret = {}
  for i = 2, #lines do
    line = vim.trim(lines[i])
    local values = {line:match(pattern)}
    if not vim.tbl_isempty(values) then
      local proc = {}
      for j,header in ipairs(headers) do
        proc[header] = values[j]
      end
      table.insert(ret, validate_proc(proc))
    end
  end
  return ret
end

---@param callback fun(procs: nil|proc.ProcessData[])
M.list = function(callback)
  local stdout_iter = M.get_stdout_line_iter()
  local lines = {}
  vim.fn.jobstart('ps', {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local lines = vim.list_extend(lines, stdout_iter(data))
    end,
    on_exit = function(_, code)
      if code == 0 then
        callback(parse_ps_output(lines))
      else
        callback(nil)
      end
    end,
  })
end

---@param name string
---@param callback fun(procs: nil|proc.ProcessData[])
M.find_by_name = function(name, callback)
  M.list(function(procs)
    if not procs then
      callback(nil)
      return
    end
    local ret = {}
    for _,v in ipairs(procs) do
      if v.cmd:match(name) then
        table.insert(ret, v)
      end
    end
    callback(ret)
  end)
end

return M
