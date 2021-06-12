local M = {}

local default_opts = {
  autoclose = true,
  prefer_loclist = true,
  update_location = true,
  sort_lsp_diagnostics = true,
  quickfix = {
    min_height = 1,
    max_height = 10,
    default_bindings = true,
  },
  loclist = {
    min_height = 1,
    max_height = 10,
    default_bindings = true,
  },
}

M.opts = default_opts

local expand_type = function(qftype)
  return qftype == 'l' and 'loclist' or 'quickfix'
end

M._set_qf_defaults = function()
  local qftype = M.get_win_type()
  local conf = M.opts[expand_type(qftype)]
  local height = vim.api.nvim_win_get_height(0)
  if conf.min_height and height < conf.min_height then
    vim.api.nvim_win_set_height(0, conf.min_height)
  elseif conf.max_height and height > conf.max_height then
    vim.api.nvim_win_set_height(0, conf.max_height)
  end
  vim.api.nvim_buf_set_option(0, 'buflisted', false)
  vim.api.nvim_win_set_option(0, 'relativenumber', false)
  vim.api.nvim_win_set_option(0, 'winfixheight', true)

  if conf.default_bindings then
    -- CTRL-t opens selection in new tab
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-t>', '<C-W><CR><C-W>T', {noremap = true, silent = true})
    -- CTRL-s opens selection in horizontal split
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-s>', '<C-W><CR>', {noremap = true, silent = true})
    -- CTRL-s opens selection in vertical split TODO probably want it to still be above the qf list
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-v>', '<C-W><CR><C-W>L', {noremap = true, silent = true})
    -- p jumps without leaving quickfix
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-p>', '<CR><C-W>p', {noremap = true, silent = true})
    -- <C-k> scrolls up and jumps without leaving quickfix
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-k>', 'k<CR><C-W>p', {noremap = true, silent = true})
    -- <C-j> scrolls down and jumps without leaving quickfix
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-j>', 'j<CR><C-W>p', {noremap = true, silent = true})
    -- { and } navigates up and down by file
    vim.api.nvim_buf_set_keymap(0, 'n', '{', '<cmd>lua require"qf_helper".navigate(-1, {by_file = true})<CR><C-W>p', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, 'n', '}', '<cmd>lua require"qf_helper".navigate(1, {by_file = true})<CR><C-W>p', {noremap = true, silent = true})
  end
end

M.setup = function(opts)
  opts = vim.tbl_deep_extend('keep', opts or {}, default_opts)
  M.opts = opts

  if opts.sort_lsp_diagnostics then
    -- Sort diagnostics properly so our qf_helper cursor position works
    local diagnostics_handler = vim.lsp.handlers['textDocument/publishDiagnostics']
    vim.lsp.handlers['textDocument/publishDiagnostics'] = function(a, b, params, client_id, c, config)
      table.sort(params.diagnostics, function(a, b)
        if a.range.start.line == b.range.start.line then
          return a.range.start.character < b.range.start.character
        else
          return a.range.start.line < b.range.start.line
        end
      end)
      return diagnostics_handler(a, b, params, client_id, c, config)
    end
  end

  local autocmd = [[augroup QFHelper
    autocmd!
    autocmd FileType qf lua require'qf_helper'._set_qf_defaults()
  ]]
  if opts.autoclose then
    autocmd = autocmd .. [[
      autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
    ]]
  end
  if opts.update_location then
    autocmd = autocmd .. [[
      autocmd CursorMoved * lua require'qf_helper'.update_pos()
    ]]
  end
  autocmd = autocmd .. [[
    augroup END
  ]]

  vim.cmd(autocmd)
end

M.get_win_type = function(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(winid)[1]
  if info.quickfix == 0 then
    return ''
  elseif info.loclist == 0 then
    return 'c'
  else
    return 'l'
  end
end

M.is_open = function(qftype)
  local ll = qftype == 'l' and 1 or 0
  for _,info in ipairs(vim.fn.getwininfo()) do
    if info.quickfix == 1 and info.loclist == ll then
      return true
    end
  end
  return false
end

M.get_active_list = function()
  local loclist = vim.fn.getloclist(0)
  local qflist = vim.fn.getqflist()

  local lret = {qftype = 'l', list = loclist}
  local cret = {qftype = 'c', list = qflist}
  -- If loclist is empty, use quickfix
  if vim.tbl_isempty(loclist) then
    return cret
  -- If quickfix is empty, use loclist
  elseif vim.tbl_isempty(qflist) then
    return lret
  elseif M.is_open('c') then
    if not M.is_open('l') then
      return cret
    end
  elseif M.is_open('l') then
    return lret
  end
  -- They're either both empty or both open
  return M.opts.prefer_loclist and lret or cret
end

M.get_list = function(qftype)
  return qftype == 'l' and vim.fn.getloclist(0) or vim.fn.getqflist()
end

-- pos is 1-indexed, like nr in the quickfix
M.get_pos = function(qftype)
  if qftype == 'l' then
    return vim.fn.getloclist(0, {idx = 0}).idx
  else
    return vim.fn.getqflist({idx = 0}).idx
  end
end

M.update_pos = function(qftype)
  if qftype == nil then
    M.update_pos('l')
    M.update_pos('c')
  elseif M.is_open(qftype) then
    M.set_pos(qftype, M._calculate_pos(qftype, M.get_list(qftype)))
  end
end

-- pos is 1-indexed, like nr in the quickfix
M._calculate_pos = function(qftype, list)
  if vim.api.nvim_buf_get_option(0, 'buftype') ~= '' then
    return -1
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local foundbuf = false
  local foundline = false
  local prev_lnum = -1
  local prev_col = -1
  local prev_bufnr = -1
  local ret = -1
  for i,entry in ipairs(list) do
    -- If we detect that the list isn't sorted, bail.
    if entry.bufnr ~= prev_bufnr then
      prev_lnum = -1
      prev_col = -1
    elseif entry.lnum < prev_lnum then
      return -1
    elseif entry.lnum == prev_lnum and entry.col < prev_col then
      return -1
    end

    if ret > 0 then
      -- pass
    elseif bufnr == entry.bufnr then
      if entry.lnum == cursor[1] then
        if entry.col > 1 + cursor[2] then
          ret = foundline and i - 1 or i
        end
        foundline = true
      elseif entry.lnum > cursor[1] then
        ret = math.max(1, foundbuf and i - 1 or i)
      end
      foundbuf = true
    elseif foundbuf then
      ret = i - 1
    end
    prev_lnum = entry.lnum
    prev_col = entry.col
  end

  if foundbuf then
    return ret == -1 and vim.tbl_count(list) or ret
  else
    return M.get_pos(qftype)
  end
end

M.open = function(qftype, opts)
  opts = vim.tbl_extend('keep', opts or {}, {
    enter = false,
    height = nil,
  })
  local list = M.get_list(qftype)
  if M.is_open(qftype) then
    if opts.enter and M.get_win_type() ~= qftype then
      M.set_pos(qftype, M._calculate_pos(qftype, list))
      vim.cmd(qftype .. "open")
    end
    return
  end
  local conf = M.opts[expand_type(qftype)]
  if not opts.height then
    opts.height = math.min(conf.max_height, math.max(conf.min_height, vim.tbl_count(list)))
  end
  M.set_pos(qftype, M._calculate_pos(qftype, list))
  local winid = vim.api.nvim_get_current_win()
  local cmd = qftype .. "open " .. opts.height
  if qftype == 'c' then
    cmd = 'botright ' .. cmd
  end
  vim.cmd(cmd)
  if not opts.enter then
    vim.api.nvim_set_current_win(winid)
  end
end

M.toggle = function(qftype, opts)
  if M.is_open(qftype) then
    M.close(qftype)
  else
    M.open(qftype, opts)
  end
end

M.close = function(qftype)
  vim.cmd(qftype .. 'close')
end

-- pos is 1-indexed, like nr in the quickfix
M._debounce_idx = 0
M.set_pos = function(qftype, pos)
  M._debounce_idx = M._debounce_idx + 1
  local idx = M._debounce_idx
  vim.defer_fn(function()
    if idx == M._debounce_idx then
      M._set_pos(qftype, pos)
    end
  end, 10)
end
M._set_pos = function(qftype, pos)
  if pos < 1 then
    return
  end
  local start_in_qf = M.get_win_type() == qftype
  if start_in_qf then
    -- If we're in the qf buffer, executing :cc will cause a nearby window to
    -- jump to the qf location. We want this to be totally silent, so we have to
    -- leave the qf buffer
    vim.cmd('wincmd w')
  end
  local prev = vim.fn.winsaveview()
  local bufnr = vim.api.nvim_get_current_buf()

  vim.cmd('silent ' .. pos .. qftype .. qftype)

  vim.api.nvim_set_current_buf(bufnr)
  vim.fn.winrestview(prev)
  if start_in_qf then
    vim.cmd(qftype .. 'open')
  end
end

M.navigate = function(direction, opts)
  opts = vim.tbl_extend('keep', opts or {}, {
    qftype = nil,
    wrap = true,
    by_file = false,
  })
  local active_list
  if opts.qftype == nil then
    active_list = M.get_active_list()
  else
    active_list = {
      qftype = opts.qftype,
      list = M.get_list(opts.qftype),
    }
  end

  local pos = M.get_pos(active_list.qftype) - 1 + direction
  if opts.by_file then
    if direction < 0 then
      vim.cmd(string.format('silent! %dcpf', math.abs(direction)))
    else
      vim.cmd(string.format('silent! %dcnf', direction))
    end
  else
    if opts.wrap then
      pos = pos % vim.tbl_count(active_list.list)
    end
    pos = pos + 1
    local cmd = pos .. active_list.qftype .. active_list.qftype
    vim.cmd('silent! ' .. cmd)
  end
  vim.cmd('normal! zv')
end

return M
