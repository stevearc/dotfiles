local config = require("claude.config")
local window = require("claude.window")

local M = {}

---@class (exact) ClaudeProcess
---@field bufnr integer
---@field jid integer
---@field tab integer
local ClaudeProcess = {}

---@type table<integer, ClaudeProcess>
local _procs_by_tab = {}

local _initialized = false

local function _setup_global_handlers()
  if _initialized then
    return
  end
  _initialized = true

  vim.api.nvim_create_autocmd("TabClosed", {
    group = vim.api.nvim_create_augroup("ClaudeTabClose", {}),
    desc = "Clean up claude processes when tab is closed",
    callback = vim.schedule_wrap(function()
      for tid, p in pairs(_procs_by_tab) do
        if not vim.api.nvim_tabpage_is_valid(tid) then
          p:terminate()
          _procs_by_tab[tid] = nil
        end
      end
    end),
  })
end

function ClaudeProcess:terminate()
  if self:is_alive() then
    vim.fn.jobstop(self.jid)
  end
end

---@return ClaudeProcess
M.get_proc = function()
  local proc = _procs_by_tab[vim.api.nvim_get_current_tabpage()]
  if proc and proc:is_alive() then
    return proc
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local jid
  local self
  vim.api.nvim_buf_call(bufnr, function()
    jid = vim.fn.jobstart({ vim.o.shell }, {
      pty = true,
      term = true,
    })
  end)
  if jid == 0 then
    error("Invalid arguments to jobstart")
  elseif jid == -1 then
    error("shell is not executable")
  end
  -- Set the scrollback to max
  vim.bo[bufnr].scrollback = 100000

  ---@type ClaudeProcess
  self = setmetatable({
    bufnr = bufnr,
    jid = jid,
    tab = vim.api.nvim_get_current_tabpage(),
  }, { __index = ClaudeProcess })

  _procs_by_tab[vim.api.nvim_get_current_tabpage()] = self
  config.on_create(self)
  _setup_global_handlers()

  return self
end

---@return boolean
function ClaudeProcess:is_alive()
  return vim.fn.jobwait({ self.jid }, 0)[1] == -1
end

---@param text string
---@param submit? boolean
function ClaudeProcess:send_text(text, submit)
  pcall(vim.api.nvim_chan_send, self.jid, text)

  if submit then
    local winid
    if vim.api.nvim_get_current_buf() ~= self.bufnr then
      winid = window.open_float(self.bufnr)
    end

    local cr = "\r"
    if vim.api.nvim_get_mode().mode ~= "ix" then
      cr = "i" .. cr
    end
    vim.defer_fn(function()
      vim.api.nvim_feedkeys(cr, "n", false)
    end, 500)

    if winid then
      vim.defer_fn(function()
        vim.api.nvim_win_close(winid, true)
      end, 1000)
    end
  end
end

return M
