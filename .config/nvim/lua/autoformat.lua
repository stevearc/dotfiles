local projects = require("projects")
local lsp = require("lsp")

local M = {}

vim.g.smartformat_enabled = true
---@param buflocal boolean
---@param enabled boolean
local function set_format_enabled(buflocal, enabled)
  if buflocal then
    vim.b.smartformat_enabled = enabled
  else
    vim.g.smartformat_enabled = enabled
  end
end
vim.api.nvim_create_user_command("FormatEnable", function(params)
  set_format_enabled(params.bang, true)
end, {
  bang = true,
})
vim.api.nvim_create_user_command("FormatDisable", function(params)
  set_format_enabled(params.bang, false)
end, {
  bang = true,
})

local function is_enabled()
  local ok, enabled = pcall(vim.api.nvim_buf_get_var, 0, "smartformat_enabled")
  if ok then
    return enabled
  end
  return vim.g.smartformat_enabled
end

local function php_has_format()
  for i = 2, vim.api.nvim_buf_line_count(0) do
    local line = vim.api.nvim_buf_get_lines(0, i, i + 1, true)[1]
    if string.find(line, "^%s//%s*@format%s*$") then
      return true
    elseif not string.find(line, "^%s*//") then
      return false
    end
  end
  return false
end

local function js_has_format()
  for i = 1, vim.api.nvim_buf_line_count(0) do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, true)[1]
    if string.find(line, "@format") then
      return true
    elseif not string.find(line, "^%s*//") and not string.find(line, "^%s*/?%*") then
      return false
    end
  end
  return false
end

local function has_format_directive()
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  if ft == "php" then
    return php_has_format()
  elseif ft == "javascript" or ft == "javascriptreact" or ft == "javascript.jsx" then
    return js_has_format()
  end
  return true
end

M.format = function()
  local project = projects[0]
  if
    not is_enabled()
    or not project.autoformat
    or vim.g.started_by_firenvim
    or vim.api.nvim_buf_line_count(0) > project.autoformat_threshold
  then
    return
  end
  if project.autoformat == "directive" and not has_format_directive() then
    return
  end
  local restore = lsp.save_win_positions(0)
  vim.lsp.buf.format({ timeout_ms = 500 })
  restore()
end

return M
