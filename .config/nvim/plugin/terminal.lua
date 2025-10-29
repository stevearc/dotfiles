local p = require("p")
local ftplugin = p.require("ftplugin")
vim.keymap.set("t", "\\\\", [[<C-\><C-N>]])

local function is_floating_win(winid) return vim.api.nvim_win_get_config(winid or 0).relative ~= "" end

ftplugin.extend("terminal", {
  opt = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
  },
  keys = {
    {
      "<C-e>",
      function()
        local bufnr = vim.fn.bufadd(vim.fn.expand("<cWORD>"))
        if is_floating_win(0) then
          vim.api.nvim_win_close(0, false)
        end
        vim.api.nvim_win_set_buf(0, bufnr)
        vim.bo[bufnr].buflisted = true
      end,
    },
    {
      "<C-t>",
      "<CMD>tabnew <cWORD><CR>",
    },
  },
})

local function make_cursor_red()
  vim.api.nvim_set_hl(0, "TermCursor", { fg = "red", ctermfg = "DarkRed", reverse = true })
end
local aug = vim.api.nvim_create_augroup("TerminalDefaults", {})
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  group = aug,
  callback = make_cursor_red,
})
make_cursor_red()

vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Auto enter insert mode when opening a terminal",
  pattern = "*",
  group = aug,
  callback = function()
    -- Wait briefly just in case we immediately switch out of the buffer
    vim.defer_fn(function()
      if vim.bo.buftype == "terminal" and not vim.b.overseer_task then
        vim.cmd.startinsert()
      end
    end, 100)
  end,
})

local dir_to_buf = {}
local global_bufs = {}

local function is_open()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[winid].is_floating_term then
      return true
    end
  end
  return false
end

local function close()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[winid].is_floating_term then
      vim.api.nvim_win_close(winid, true)
    end
  end
end

---@param bufnr? integer Optional existing buffer
---@param background? boolean Open in background
---@return integer bufnr
local function open_terminal_win(bufnr, background)
  local open_term = false
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
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
  vim.w[winid].is_floating_term = true
  vim.api.nvim_create_autocmd("VimResized", {
    desc = "Resize floating terminal on vim resize",
    callback = function()
      if vim.api.nvim_win_is_valid(winid) then
        width = vim.o.columns - border - 2 * padding
        height = vim.o.lines - vim.o.cmdheight - border - 2 * padding
        vim.api.nvim_win_set_width(winid, width)
        vim.api.nvim_win_set_height(winid, height)
      else
        return true
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
  if background then
    vim.api.nvim_win_close(winid, true)
  else
    vim.cmd.startinsert()
  end

  return bufnr
end

---@param background? boolean Open in background
local function open_dir(background)
  local cwd = vim.fn.getcwd()
  local bufnr = open_terminal_win(dir_to_buf[cwd], background)
  dir_to_buf[cwd] = bufnr
end

local function toggle()
  if is_open() then
    close()
  elseif vim.v.count == 0 then
    open_dir()
  else
    local bufnr = open_terminal_win(global_bufs[vim.v.count])
    global_bufs[vim.v.count] = bufnr
  end
end

vim.keymap.set({ "n", "t" }, [[<C-\>]], toggle, { desc = "Toggle floating terminal" })

-- preload the default terminal
vim.defer_fn(function() open_dir(true) end, 1000)

vim.api.nvim_create_autocmd("DirChanged", {
  desc = "Preload a terminal for the new directory",
  pattern = "*",
  group = aug,
  callback = function() open_dir(true) end,
})
