local config = require("claude.config")
local window = require("claude.window")

local M = {}

---@class (exact) ClaudeProcess
---@field bufnr integer
---@field jid integer
---@field tab integer
---@field initialized boolean
---@field thinking boolean
---@field private timer? uv.uv_timer_t
---@field private command_buffer {[1]: string, [2]: nil|boolean}
---@field private last_output_time number
local ClaudeProcess = {}

---@type table<integer, ClaudeProcess>
local _procs_by_tab = {}

local _initialized = false
local _last_keypress_time = 0

local function _setup_global_handlers()
  if _initialized then
    return
  end
  _initialized = true

  _last_keypress_time = vim.uv.now()

  vim.on_key(function()
    _last_keypress_time = vim.uv.now()
  end)

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
      on_stdout = vim.schedule_wrap(function()
        self:_on_output()
      end),
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

  ---@type ClaudeProcess
  self = setmetatable({
    bufnr = bufnr,
    jid = jid,
    initialized = false,
    thinking = false,
    tab = vim.api.nvim_get_current_tabpage(),
    command_buffer = {},
    last_output_time = vim.uv.now(),
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

---Called when output is received from the job
function ClaudeProcess:_on_output()
  self.last_output_time = vim.uv.now()

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

    return
  end

  if self.timer then
    self.timer:stop()
  else
    self.timer = assert(vim.uv.new_timer())
  end
  self.timer:start(
    1000,
    0,
    vim.schedule_wrap(function()
      -- Set thinking=false after no output for 1 second
      self:_set_thinking(false)
    end)
  )

  if not self.thinking then
    local now = vim.uv.now()
    local time_since_keypress = now - _last_keypress_time
    -- Set thinking=true when there is output in the claude window and it has been
    -- 1 second since user pressed keys, OR user is in a different window
    if time_since_keypress > 1000 or vim.api.nvim_get_current_buf() ~= self.bufnr then
      self:_set_thinking(true)
    end
  end
end

---@param thinking boolean
function ClaudeProcess:_set_thinking(thinking)
  if thinking == self.thinking then
    return
  end
  self.thinking = thinking
  vim.t[self.tab].claude_thinking = thinking
  vim.api.nvim_exec_autocmds("User", {
    pattern = "ClaudeStatus",
    modeline = false,
    data = {
      tab = self.tab,
      thinking = thinking,
    },
  })
  if not thinking then
    vim.notify("Claude is finished")
  end
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
