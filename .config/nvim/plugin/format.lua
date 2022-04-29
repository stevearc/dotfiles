local projects = require("projects")
local lsp = require("lsp")

vim.g.smartformat_enabled = true
vim.cmd([[command! FormatDisable let g:smartformat_enabled = v:false]])
vim.cmd([[command! FormatEnable let g:smartformat_enabled = v:true]])

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

function stevearc.autoformat()
  local project = projects[0]
  if
    not vim.g.smartformat_enabled
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
  vim.lsp.buf.formatting_sync(nil, 1000)
  restore()
end
