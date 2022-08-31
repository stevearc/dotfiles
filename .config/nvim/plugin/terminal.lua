local ftplugin = safe_require("ftplugin")
vim.keymap.set("t", "\\\\", [[<C-\><C-N>]])
for i = 1, 9 do
  vim.keymap.set("t", string.format([[\%d]], i), string.format([[<C-\><C-N>:BufferGoto %d<CR>]], i))
end
vim.keymap.set("t", [[\`]], [[<C-\><C-N>:BufferLast<CR>]])

vim.cmd([[highlight TermCursor ctermfg=DarkRed guifg=red]])

local function is_floating_win(winid)
  return vim.api.nvim_win_get_config(winid or 0).relative ~= ""
end

ftplugin.extend("terminal", {
  opt = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
  },
  bindings = {
    {
      "n",
      "<C-e>",
      function()
        local bufnr = vim.fn.bufadd(vim.fn.expand("<cWORD>"))
        if is_floating_win(0) then
          vim.api.nvim_win_close(0, false)
        end
        vim.api.nvim_win_set_buf(0, bufnr)
      end,
    },
    {
      "n",
      "<C-t>",
      "<CMD>tabnew <cWORD><CR>",
    },
  },
})
local function set_defaults()
  if vim.bo.buftype ~= "terminal" then
    return
  end
  vim.bo.number = false
  vim.bo.relativenumber = false
  vim.bo.signcolumn = "no"
end

local aug = vim.api.nvim_create_augroup("TerminalDefaults", {})
vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Auto enter insert mode when opening a terminal",
  pattern = "*",
  group = aug,
  callback = function()
    -- Wait briefly just in case we immediately switch out of the buffer
    vim.defer_fn(function()
      if vim.api.nvim_buf_get_option(0, "buftype") == "terminal" then
        vim.cmd([[startinsert]])
      end
    end, 100)
  end,
})

local dir_to_buf = {}

local function is_open()
  local bufnr = vim.api.nvim_get_current_buf()
  for _, v in pairs(dir_to_buf) do
    if bufnr == v then
      return true
    end
  end
  return false
end

local function close()
  if vim.api.nvim_get_mode().mode == "t" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "n", false)
  end
  vim.api.nvim_win_close(0, true)
end

local function open()
  local cwd = vim.fn.getcwd(0)
  local bufnr = dir_to_buf[cwd]
  local open_term = false
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
    dir_to_buf[cwd] = bufnr
    open_term = true
    vim.api.nvim_create_autocmd("BufLeave", {
      desc = "Close floating window when leaving terminal buffer",
      buffer = bufnr,
      once = true,
      nested = true,
      callback = function()
        vim.defer_fn(function()
          for _, winid in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(winid) == bufnr then
              vim.api.nvim_win_close(winid, true)
            end
          end
        end, 10)
      end,
    })
  end

  local padding = 2
  local border = 2
  local width = vim.o.columns - border - 2 * padding
  local height = vim.o.lines - vim.o.cmdheight - border - 2 * padding
  local winid = vim.api.nvim_open_win(bufnr, true, {
    border = "rounded",
    relative = "editor",
    width = width,
    height = height,
    row = padding,
    col = padding,
  })
  vim.api.nvim_win_set_option(winid, "winblend", 3)
  local autocmd_id
  autocmd_id = vim.api.nvim_create_autocmd("VimResized", {
    desc = "Resize floating terminal on vim resize",
    callback = function()
      if vim.api.nvim_win_is_valid(winid) then
        width = vim.o.columns - border - 2 * padding
        height = vim.o.lines - vim.o.cmdheight - border - 2 * padding
        vim.api.nvim_win_set_width(winid, width)
        vim.api.nvim_win_set_height(winid, height)
      else
        vim.api.nvim_del_autocmd(autocmd_id)
      end
    end,
  })

  if open_term then
    vim.fn.termopen(vim.o.shell, {
      on_exit = function(j, c)
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == bufnr then
            vim.api.nvim_win_close(win, true)
          end
        end
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end,
    })
  end
  vim.cmd([[startinsert]])
end

local function toggle()
  if is_open() then
    close()
  else
    open()
  end
end

vim.keymap.set({ "n", "t" }, [[<C-\>]], toggle, { desc = "Toggle floating terminal" })
