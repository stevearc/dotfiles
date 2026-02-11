local config = require("claude.config")
local window = require("claude.window")

local M = {}

---@class (exact) ClaudeProcess
---@field bufnr integer
---@field jid integer
---@field tab integer
---@field initialized boolean
---@field thinking boolean
---@field private timer uv.uv_timer_t
---@field private command_buffer {[1]: string, [2]: nil|boolean}
local ClaudeProcess = {}

---@type table<integer, ClaudeProcess>
local _procs_by_tab = {}

function ClaudeProcess:_cleanup()
  if self.timer then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end
  vim.t[self.tab].claude_thinking = nil
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
    jid = vim.fn.jobstart({ "claude", "--permission-mode=acceptEdits", "--model", "opus" }, {
      pty = true,
      term = true,
      on_exit = function()
        self:_cleanup()
      end,
    })
  end)
  if jid == 0 then
    error("Invalid arguments to jobstart")
  elseif jid == -1 then
    error("'claude' is not executable")
  end
  -- Set the scrollback to max
  vim.bo[bufnr].scrollback = 100000

  local timer = assert(vim.uv.new_timer())
  ---@type ClaudeProcess
  self = setmetatable({
    bufnr = bufnr,
    jid = jid,
    initialized = false,
    thinking = false,
    timer = timer,
    tab = vim.api.nvim_get_current_tabpage(),
    command_buffer = {},
  }, { __index = ClaudeProcess })
  timer:start(
    100,
    100,
    vim.schedule_wrap(function()
      self:_render()
    end)
  )

  _procs_by_tab[vim.api.nvim_get_current_tabpage()] = self
  config.on_create(self)

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

  return self
end

---@return boolean
function ClaudeProcess:is_alive()
  return vim.fn.jobwait({ self.jid }, 0)[1] == -1
end

---@return boolean
function ClaudeProcess:_check_thinking()
  for _, line in ipairs(vim.api.nvim_buf_get_lines(self.bufnr, -vim.o.lines, -1, false)) do
    if vim.startswith(line, "✻ ") then
      return true
    end
  end
  return false
end

function ClaudeProcess:_render()
  if not self.initialized then
    local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
    for _, line in ipairs(lines) do
      if vim.startswith(line, "❯") then
        self.initialized = true
        if #self.command_buffer > 0 then
          for _, v in ipairs(self.command_buffer) do
            self:send_text(v[1], v[2])
          end
          self.command_buffer = {}
        end
      end
    end
  end

  local thinking = self:_check_thinking()
  if thinking ~= self.thinking then
    if not thinking then
      vim.notify("Claude is finished")
    end
    self.thinking = thinking
    vim.api.nvim_exec_autocmds("User", {
      pattern = "ClaudeStatus",
      modeline = false,
      data = {
        tab = self.tab,
        thinking = thinking,
      },
    })
  end
  vim.t[self.tab].claude_thinking = thinking
end

---Wait for claude to finish starting up
function ClaudeProcess:_watch_for_init()
  vim.wait(15000, function()
    local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
    for _, line in ipairs(lines) do
      if vim.startswith(line, "❯ ") then
        vim.notify("DEBUG: Found starting prompt")
        self.initialized = true
        return true
      end
    end
    return false
  end, 100)
end

---@param text string
---@param submit? boolean
function ClaudeProcess:send_text(text, submit)
  if not self.initialized then
    table.insert(self.command_buffer, { text, submit })
    return
  end
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
