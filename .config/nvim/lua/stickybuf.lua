local M = {}

-- stylua: ignore
local config = {
  buftype = {
    [""]     = false,
    acwrite  = false,
    help     = "buftype",
    nofile   = false,
    nowrite  = false,
    quickfix = "buftype",
    terminal = false,
    prompt   = "bufnr",
  },
  wintype = {
    autocmd = false,
    popup   = "bufnr",
    preview = false,
    command = false,
    [""]    = false,
    unknown = false,
  },
  filetype = {
    aerial = 'filetype',
  },
}

local function is_empty_buffer()
  return vim.api.nvim_buf_line_count(0) == 1
    and vim.bo.buftype == ""
    and vim.api.nvim_buf_get_lines(0, 0, 1, true)[1] == ""
end

local function get_win_type()
  local wt = vim.fn.win_gettype()
  if wt == "" and vim.api.nvim_win_get_config(0).relative ~= "" then
    return "floating"
  else
    return wt
  end
end

local function get_stick_type()
  if is_empty_buffer() then
    return nil
  end
  return config.buftype[vim.bo.buftype] or config.wintype[get_win_type()] or config.filetype[vim.bo.filetype]
end

local function is_sticky_win(winid)
  winid = winid or vim.api.nvim_get_current_win()
  return pcall(vim.api.nvim_win_get_var, winid, "sticky_original_bufnr")
end

local function is_sticky_match()
  if vim.w.sticky_bufnr and vim.w.sticky_bufnr ~= vim.api.nvim_get_current_buf() then
    return false
  end
  if vim.w.sticky_buftype and vim.w.sticky_buftype ~= vim.bo.buftype then
    return false
  end
  if vim.w.sticky_filetype and vim.w.sticky_filetype ~= vim.bo.filetype then
    return false
  end
  return true
end

local function open_in_best_window(bufnr)
  -- If a non-special window exists, open the buffer there
  for winnr = 1, vim.fn.winnr("$") do
    local winid = vim.fn.win_getid(winnr)
    if not is_sticky_win(winid) then
      vim.cmd(string.format("%dwincmd w", winnr))
      vim.cmd(string.format("buffer %d", bufnr))
      return
    end
  end
  -- Otherwise, open the buffer in a vsplit from the first window
  vim.fn.win_execute(vim.fn.win_getid(1), string.format("vertical rightbelow sbuffer %d", bufnr))
  vim.cmd([[2wincmd w]])
end

local function _on_buf_enter()
  if is_empty_buffer() then
    return
  end
  local stick_type = get_stick_type()
  if not is_sticky_match() then
    -- If this was a sticky buffer window and the buffer no longer matches, restore it
    local winid = vim.api.nvim_get_current_win()
    local newbuf = vim.api.nvim_get_current_buf()
    vim.fn.win_execute(winid, "noau buffer " .. vim.w.sticky_original_bufnr)
    -- Then open the new buffer in the appropriate location
    vim.defer_fn(function()
      open_in_best_window(newbuf)
    end, 1)
  elseif stick_type then
    if stick_type == "bufnr" then
      M.pin_buffer()
    elseif stick_type == "buftype" then
      M.pin_buftype()
    elseif stick_type == "filetype" then
      M.pin_filetype()
    else
      error(string.format("Unknown sticky buf type '%s'", stick_type))
    end
  end
end

local function override_bufhidden()
  -- We have to override bufhidden so that the buffer won't be
  -- unloaded or deleted if we navigate away from it
  local bufhidden = vim.bo.bufhidden
  if bufhidden == "unload" or bufhidden == "delete" or bufhidden == "wipe" then
    vim.b.prev_bufhidden = bufhidden
    vim.bo.bufhidden = "hide"
    vim.cmd([[
    augroup StickyBufOnHide
      au! * <buffer>
      autocmd BufHidden <buffer> call luaeval("require'stickybuf'.on_buf_hidden(tonumber(_A))", expand('<abuf>'))
    augroup END
    ]])
  end
end

M.on_buf_enter = function()
  -- Delay just in case the buffer is blank when entered but some process is
  -- about to set all the filetype/buftype/etc options
  vim.defer_fn(_on_buf_enter, 5)
end

M.on_buf_hidden = function(bufnr)
  local ok, prev_bufhidden = pcall(vim.api.nvim_buf_get_var, bufnr, "prev_bufhidden")
  if ok then
    -- We need a long delay for this to make sure we're not going to restore this buffer
    vim.defer_fn(function()
      if #vim.fn.win_findbuf(bufnr) == 0 then
        vim.cmd(string.format("b%s! %d", prev_bufhidden, bufnr))
      end
    end, 1000)
  end
end

M.pin_buffer = function()
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_bufnr = vim.api.nvim_get_current_buf()
  override_bufhidden()
end

M.pin_buftype = function()
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_buftype = vim.bo.buftype
  override_bufhidden()
end

M.pin_filetype = function()
  vim.w.sticky_original_bufnr = vim.api.nvim_get_current_buf()
  vim.w.sticky_filetype = vim.bo.filetype
  override_bufhidden()
end

M.unpin_buffer = function()
  vim.w.sticky_original_bufnr = nil
  vim.w.sticky_bufnr = nil
  vim.w.sticky_buftype = nil
  vim.w.sticky_filetype = nil
  if vim.b.prev_bufhidden then
    vim.bo.bufhidden = vim.b.prev_bufhidden
    vim.b.prev_bufhidden = nil
    vim.cmd([[
    augroup StickyBufOnHide
      au! * <buffer>
    augroup END
    ]])
  end
end

M.setup = function(opts)
  config = vim.tbl_deep_extend("keep", opts or {}, config)
  vim.cmd([[
  augroup StickyBuf
    au!
    autocmd BufEnter * lua require'stickybuf'.on_buf_enter()
  augroup END
  ]])
  vim.cmd([[command! PinBuffer lua require'stickybuf'.pin_buffer()]])
  vim.cmd([[command! PinBuftype lua require'stickybuf'.pin_buftype()]])
  vim.cmd([[command! PinFiletype lua require'stickybuf'.pin_filetype()]])
  vim.cmd([[command! UnpinBuffer lua require'stickybuf'.unpin_buffer()]])
end

return M
