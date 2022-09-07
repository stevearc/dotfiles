vim.o.winwidth = 1
vim.o.winheight = 1
vim.o.splitbelow = true
vim.o.splitright = true

vim.g.win_equal_size = false
local function resize_windows()
  local buftype = vim.api.nvim_buf_get_option(0, "buftype")
  -- Ignore prompt & quickfix windows
  -- For some reason wincmd = inside the preview window doesn't play nice when
  -- we have other windows present with winfixwidth/winfixheight
  if buftype == "prompt" or buftype == "quickfix" or not vim.g.win_equal_size or vim.wo.previewwindow then
    return
  end
  if vim.g.win_equal_size and not vim.wo.previewwindow then
    vim.cmd([[wincmd =]])
  end
end

local function soft_set(dimension, value)
  vim.o["win" .. dimension] = value
  vim.defer_fn(function()
    vim.o["win" .. dimension] = 1
  end, 1)
end

local function set_win_size()
  if not vim.g.win_equal_size then
    return
  end
  local buftype = vim.api.nvim_buf_get_option(0, "buftype")
  -- Ignore prompt & quickfix windows
  if buftype == "prompt" or buftype == "quickfix" then
    return
  end
  -- ignore floating windows
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    return
  end
  if not vim.wo.winfixwidth then
    soft_set("width", vim.bo.textwidth + 8)
  end
  if not vim.wo.winfixheight then
    soft_set("height", 20)
  end
end

local function toggle_maximize()
  if pcall(vim.api.nvim_win_get_var, 0, "is_maximized") then
    vim.api.nvim_win_del_var(0, "is_maximized")
    vim.cmd("wincmd =")
  else
    vim.api.nvim_win_set_var(0, "is_maximized", true)
    vim.cmd("resize | vertical resize")
  end
end

local aug = vim.api.nvim_create_augroup("StevearcWinWidth", {})

vim.api.nvim_create_autocmd({ "WinEnter" }, {
  desc = "Resize the current window on enter",
  pattern = "*",
  callback = set_win_size,
  group = aug,
})

vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  desc = "Make all windows equal size when switching window",
  pattern = "*",
  callback = resize_windows,
  group = aug,
})

vim.keymap.set("n", "<C-w>+", function()
  vim.g.win_equal_size = not vim.g.win_equal_size
  if vim.g.win_equal_size then
    vim.notify("Window resizing ENABLED")
  else
    vim.notify("Window resizing DISABLED")
  end
end, {})
vim.keymap.set("n", "<C-w>z", "<cmd>resize | vertical resize<CR>", {})
vim.keymap.set("n", "<A-m>", toggle_maximize, {})
vim.keymap.set("t", "<A-m>", toggle_maximize, {})
