local stevearc = require("stevearc")

vim.g.bufferline = {
  animation = false,
  icons = "numbers",
  tab_local_buffers = true,
  tabpages = "left",
}

vim.cmd([[
aug StickyRemote
  au!
  au BufEnter * if get(w:, 'is_remote') | silent! PinBuffer | endif
aug END
]])

local function map(lhs, rhs, mode, opts)
  opts = opts or { silent = true, noremap = true }
  mode = mode or "n"
  vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

map("H", "<cmd>BufferPrevious<CR>")
map("L", "<cmd>BufferNext<CR>")
map("<C-H>", "<cmd>BufferMovePrevious<CR>")
map("<C-L>", "<cmd>BufferMoveNext<CR>")
map("<leader>bm", ":BufferMove ", "n", { noremap = true })
map("<leader>bi", "<cmd>BufferPin<CR>")
map("<leader>bo", "<cmd>BufferOrderByTime<CR>")
map("<leader>1", "<cmd>BufferGoto 1<CR>")
map("<leader>2", "<cmd>BufferGoto 2<CR>")
map("<leader>3", "<cmd>BufferGoto 3<CR>")
map("<leader>4", "<cmd>BufferGoto 4<CR>")
map("<leader>5", "<cmd>BufferGoto 5<CR>")
map("<leader>6", "<cmd>BufferGoto 6<CR>")
map("<leader>7", "<cmd>BufferGoto 7<CR>")
map("<leader>8", "<cmd>BufferGoto 8<CR>")
map("<leader>9", "<cmd>BufferGoto 9<CR>")
map("<leader>`", "<cmd>BufferLast<CR>")
map("<leader>c", '<cmd>lua require("stevearc").smart_close()<CR>')
map("<leader>C", "<cmd>BufferClose<CR>")
map("<leader>h", "<cmd>BufferHide<CR>")
map("<leader>H", "<cmd>BufferHideAllButCurrent<CR>")
map("<C-w><C-b>", "<cmd>tab split<CR>")
map("<C-w><C-n>", "<cmd>TabClone<CR>")
map("<A-h>", "gT")
map("<A-l>", "gt")
map("<A-c>", "<cmd>tabclose<CR>")
map("<A-h>", "<cmd>tabprev<CR>", "t")
map("<A-l>", "<cmd>tabnext<CR>", "t")
map("<A-c>", "<cmd>tabclose<CR>", "t")

local function is_floating_win(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ""
end

local function is_normal_win(winid)
  if require("stickybuf.util").is_sticky_win(winid) then
    return false
  end
  -- Check for non-normal (e.g. popup/preview) windows
  if vim.fn.win_gettype(winid) ~= "" or is_floating_win(winid) then
    return false
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  local bt = vim.api.nvim_buf_get_option(bufnr, "buftype")

  -- Ignore quickfix, prompt, help, and aerial buffer windows
  return bt ~= "quickfix" and bt ~= "prompt" and bt ~= "help" and ft ~= "aerial"
end

local function other_normal_window_exists()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local curwin = vim.api.nvim_get_current_win()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if is_normal_win(winid) and curwin ~= winid then
      return true
    end
  end
  return false
end

function stevearc.smart_close()
  local curwin = vim.api.nvim_get_current_win()
  -- if we're in a non-normal or floating window: close
  if vim.fn.win_gettype() ~= "" or is_floating_win(curwin) then
    vim.cmd("close")
    return
  end

  local ok, is_remote = pcall(vim.api.nvim_win_get_var, curwin, "is_remote")
  if ok and is_remote then
    vim.cmd("BufferClose")
    if other_normal_window_exists() then
      vim.cmd("close")
    elseif #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("tabclose")
    end
  elseif other_normal_window_exists() then
    vim.cmd("close")
  else
    vim.cmd("BufferClose")
  end
end