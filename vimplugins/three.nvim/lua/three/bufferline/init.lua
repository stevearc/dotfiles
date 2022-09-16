local state = require("three.bufferline.state")
local M = {}

---@param group string
---@param field string
---@return nil|string
local function get_color(group, field)
  local id = vim.fn.hlID(group)
  if id == 0 then
    return nil
  end
  local color = vim.fn.synIDattr(id, field, "gui")
  return color ~= "" and color or nil
end

local function get_color_fallback(...)
  for _, pair in ipairs({ ... }) do
    local color = get_color(unpack(pair))
    if color then
      return color
    end
  end
end

local function has_hl(group)
  return get_color(group, "fg#") or get_color(group, "bg#")
end

local function set_colors()
  -- TabLine (standard)
  -- TabLineSel (standard)
  -- TabLineVisible
  -- TabLineFill (standard)
  -- TabLineDir
  -- TabLineDividerVisible
  -- TabLineDivider
  -- TabLineDividerSel
  -- TabLineDividerVisible
  -- TabLineIndex
  -- TabLineIndexSel
  -- TabLineIndexVisible
  -- TabLineModified
  -- TabLineModifiedSel
  -- TabLineModifiedVisible
  -- TabLineScrollIndicator
  vim.cmd([[
    hi default link TabLineVisible TabLine
    hi default link TabLineIndex TabLine
    hi default link TabLineModified DiagnosticWarn
    hi default link TabLineModifiedSel DiagnosticWarn
    hi default link TabLineModifiedVisible DiagnosticWarn
  ]])
  local tabfill_bg = get_color_fallback({ "TabLineFill", "bg#" }, { "Normal", "bg#" })
  if not has_hl("TabLineDir") then
    vim.api.nvim_set_hl(0, "TabLineDir", {
      bg = get_color("TabLineFill", "bg#"),
      fg = get_color_fallback({ "Title", "fg#" }, { "TabLineSel", "fg#" }),
    })
  end
  if not has_hl("TabLineScrollIndicator") then
    vim.api.nvim_set_hl(0, "TabLineScrollIndicator", {
      bg = get_color("TabLineFill", "bg#"),
      fg = get_color("TabLine", "fg#"),
    })
  end
  -- TabLineModified
  if not has_hl("TabLineModifiedSel") then
    vim.api.nvim_set_hl(0, "TabLineModifiedSel", {
      bg = get_color("TabLineSel", "bg#"),
      fg = get_color_fallback({ "DiagnosticWarn", "fg#" }, { "TabLineSel", "fg#" }),
    })
  end
  if not has_hl("TabLineModifiedVisible") then
    vim.api.nvim_set_hl(0, "TabLineModifiedVisible", {
      bg = get_color_fallback({ "TabLineVisible", "bg#" }, { "TabLine", "bg#" }),
      fg = get_color_fallback({ "DiagnosticWarn", "fg#" }, { "TabLineVisible", "fg#" }),
    })
  end
  if not has_hl("TabLineModified") then
    vim.api.nvim_set_hl(0, "TabLineModified", {
      bg = get_color("TabLine", "bg#"),
      fg = get_color_fallback({ "DiagnosticWarn", "fg#" }, { "TabLine", "fg#" }),
    })
  end

  -- TabLineIndex
  if not has_hl("TabLineIndexSel") then
    vim.api.nvim_set_hl(0, "TabLineIndexSel", {
      bg = get_color("TabLineSel", "bg#"),
      fg = get_color_fallback({ "Title", "fg#" }, { "TabLineSel", "fg#" }),
      bold = true,
    })
  end
  if not has_hl("TabLineIndexVisible") then
    vim.api.nvim_set_hl(0, "TabLineIndexVisible", {
      bg = get_color_fallback({ "TabLineVisible", "bg#" }, { "TabLine", "bg#" }),
      fg = get_color_fallback({ "Title", "fg#" }, { "TabLineVisible", "fg#" }),
      bold = true,
    })
  end

  -- TabLineDivider
  if not has_hl("TabLineDividerSel") then
    vim.api.nvim_set_hl(0, "TabLineDividerSel", {
      bg = get_color("TabLineSel", "bg#"),
      fg = tabfill_bg,
    })
  end
  if not has_hl("TabLineDividerVisible") then
    vim.api.nvim_set_hl(0, "TabLineDividerVisible", {
      bg = get_color_fallback({ "TabLineVisible", "bg#" }, { "TabLine", "bg#" }),
      fg = tabfill_bg,
    })
  end
  if not has_hl("TabLineDivider") then
    vim.api.nvim_set_hl(0, "TabLineDivider", {
      bg = get_color("TabLine", "bg#"),
      fg = tabfill_bg,
    })
  end
end

M.setup = function(config)
  local group = vim.api.nvim_create_augroup("Three.nvim", { clear = true })
  vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
    pattern = "*",
    group = group,
    callback = set_colors,
  })
  state.create_autocmds(group)
  state.display_all_buffers()
  vim.o.showtabline = 2
  vim.o.tabline = "%{%v:lua.require('three.bufferline').render()%}"
end

M.render = function()
  local renderer = require("three.bufferline.renderer")
  local ok, ret = xpcall(renderer.render, debug.traceback)
  if ok then
    return ret
  else
    vim.api.nvim_err_writeln(ret)
    return ""
  end
end

return M
