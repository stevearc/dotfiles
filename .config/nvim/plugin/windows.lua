local stevearc = require'stevearc'
vim.o.winwidth = 1
vim.o.winheight = 1
vim.o.splitbelow = true
vim.o.splitright = true

vim.g.win_equal_size = true
function stevearc:resize_windows()
  if vim.g.win_equal_size then
    vim.cmd[[wincmd =]]
  end
end

local function soft_set(dimension, value)
  vim.o['win'..dimension] = value
  vim.defer_fn(function()
    vim.o['win'..dimension] = 1
  end, 1)
end

function stevearc:set_win_size()
  local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
  -- Ignore prompt & quickfix windows
  if buftype == 'prompt' or buftype == 'quickfix' then
    return
  end
  -- ignore floating windows
  if vim.api.nvim_win_get_config(0).relative ~= '' then
    return
  end
  if not vim.wo.winfixwidth then
    soft_set('width', vim.bo.textwidth + 8)
  end
  if not vim.wo.winfixheight then
    soft_set('height', 20)
  end
end

vim.cmd[[augroup WinWidth
au!
  au WinEnter * lua require'stevearc'.set_win_size()
  au VimEnter,WinEnter,BufWinEnter * lua require'stevearc'.resize_windows()
augroup END
]]
vim.api.nvim_set_keymap('n', '<C-w>+', '<cmd>lua vim.g.win_equal_size = not vim.g.win_equal_size<CR>', {silent = true})
vim.api.nvim_set_keymap('n', '<C-w>z', '<cmd>resize | vertical resize<CR>', {silent = true})
