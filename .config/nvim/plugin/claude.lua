---@class (exact) ClaudeProcess
---@field bufnr integer
---@field jid integer
---@field private initialized boolean
---@field private thinking boolean
---@field private timer uv.uv_timer_t
---@field private tab integer
---@field private command_buffer {[1]: string, [2]: nil|boolean}
local ClaudeProcess = {}

---@type table<integer, ClaudeProcess>
local _procs_by_tab = {}

---@param bufnr integer
---@return integer
local function open_float(bufnr)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  return vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
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
local function get_claude()
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
      on_exit = function() self:_cleanup() end,
    })
  end)
  if jid == 0 then
    error("Invalid arguments to jobstart")
  elseif jid == -1 then
    error("'claude' is not executable")
  end
  -- Set the scrollback to max
  vim.bo[bufnr].scrollback = 100000

  vim.keymap.set("t", "<C-i>", function() vim.cmd.close() end, { buffer = bufnr })

  if Snacks then
    vim.keymap.set("t", "@", function()
      vim.api.nvim_win_close(0, true)
      Snacks.picker.buffers({
        layout = { preview = false },
        on_close = function()
          open_float(bufnr)
          vim.api.nvim_feedkeys("i", "n", true)
        end,
        confirm = function(picker, item)
          picker:close()
          if item and item.file then
            local filename = item.file
            local cwd = vim.fn.getcwd()
            if vim.startswith(filename, cwd) then
              filename = filename:sub(cwd:len() + 2)
            end
            vim.api.nvim_chan_send(jid, "@" .. filename .. " ")
          end
        end,
      })
    end, { buffer = bufnr })
  end

  local timer = assert(vim.uv.new_timer())
  self = setmetatable({
    bufnr = bufnr,
    jid = jid,
    initialized = false,
    thinking = false,
    timer = timer,
    tab = vim.api.nvim_get_current_tabpage(),
    command_buffer = {},
  }, { __index = ClaudeProcess })
  timer:start(100, 100, vim.schedule_wrap(function() self:_render() end))

  _procs_by_tab[vim.api.nvim_get_current_tabpage()] = self
  return self
end

---@return boolean
function ClaudeProcess:is_alive() return vim.fn.jobwait({ self.jid }, 0)[1] == -1 end

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
      winid = open_float(self.bufnr)
    end

    local cr = "\r"
    if vim.api.nvim_get_mode().mode ~= "ix" then
      cr = "i" .. cr
    end
    vim.defer_fn(function() vim.api.nvim_feedkeys(cr, "n", false) end, 500)

    if winid then
      vim.defer_fn(function() vim.api.nvim_win_close(winid, true) end, 1000)
    end
  else
  end
end

---Get the start and end line numbers from the current visual selection
---@return {[1]: integer, [2]: integer}
local function range_from_selection()
  local start = vim.fn.getpos("v")
  local end_ = vim.fn.getpos(".")
  local start_row = start[2]
  local end_row = end_[2]

  -- A user can start visual selection at the end and move backwards
  -- Normalize the range to start < end
  if end_row < start_row then
    start_row, end_row = end_row, start_row
  end
  return { start_row, end_row }
end

---@class (exact) LocationOpts
---@field context? 'file'|'line'

---@return string
local function get_location(opts)
  opts = opts or {}
  if vim.bo.buftype ~= "" then
    error("Cannot get location of non-normal buffer")
  end

  local mode = vim.api.nvim_get_mode().mode
  local is_visual_mode = mode == "v" or mode == "V"
  if opts.context == nil and is_visual_mode then
    opts.context = "line"
  end

  vim.cmd.update()

  local filename = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  if vim.startswith(filename, cwd) then
    filename = filename:sub(cwd:len() + 2)
  end

  if opts.context ~= "line" then
    return "@" .. filename
  end

  if is_visual_mode then
    local range = range_from_selection()
    if range[1] == range[2] then
      return string.format("%s:%d", filename, range[1])
    else
      return string.format("%s:%d-%d", filename, range[1], range[2])
    end
  else
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    return string.format("%s:%d", filename, lnum)
  end
end

local actions = {
  send_location = {
    desc = "Send cursor location to claude",
    mode = { "n", "v" },
    callback = function()
      local location = get_location()
      local c = get_claude()
      c:send_text(location .. " ")
    end,
  },
  toggle_split = {
    desc = "Open claude buffer in a vertical split",
    callback = function()
      local c = get_claude()
      -- Check if there's already a window showing the claude buffer
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == c.bufnr then
          vim.api.nvim_win_close(win, false)
          return
        end
      end

      vim.cmd.vsplit()
      vim.api.nvim_win_set_buf(0, c.bufnr)
      vim.wo.winfixwidth = true
      vim.cmd.startinsert()
    end,
  },
  toggle_float = {
    desc = "Open claude buffer in a floating window",
    callback = function()
      local c = get_claude()
      -- Check if there's already a floating window showing the claude buffer
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == c.bufnr then
          local config = vim.api.nvim_win_get_config(win)
          if config.relative ~= "" then
            vim.api.nvim_win_close(win, false)
            return
          end
        end
      end

      -- Create a floating window
      open_float(c.bufnr)
      vim.cmd.startinsert()
    end,
  },
  autofill = {
    desc = "Auto implement some code",
    mode = { "n", "v" },
    callback = function()
      local location = get_location({ context = "line" })
      local c = get_claude()
      c:send_text(
        string.format("Implement the missing code in %s. No need to run tests or format the code.", location),
        true
      )
    end,
  },
}

---Map a keymap to a Claude action
local function map_action(keys, action_name)
  local action = assert(actions[action_name])
  vim.keymap.set(action.mode or "n", keys, function()
    if action.cond and not action.cond() then
      vim.notify("Cannot " .. action.desc, vim.log.levels.ERROR)
    else
      action.callback()
    end
  end, { desc = action.desc })
end

map_action("<leader>if", "autofill")
map_action("<leader>ic", "send_location")
map_action("<leader>iw", "toggle_float")
map_action("<leader>il", "toggle_split")

---Show a menu to select and execute a Claude action
local function choose_action()
  local items = vim.tbl_filter(function(action) return not action.cond or action.cond() end, actions)
  vim.ui.select(items, { format_item = function(item) return item.desc end }, function(action)
    if action and (not action.cond or action.cond()) then
      action.callback()
    end
  end)
end

vim.keymap.set("n", "<leader>ii", choose_action, {
  desc = "Select and run claude action",
})
vim.keymap.set(
  "n",
  "<leader>yf",
  function() vim.fn.setreg("+", vim.fn.expand("%:~")) end,
  { desc = "[Y]ank [F]ilename" }
)

vim.api.nvim_create_autocmd("TabClosed", {
  group = vim.api.nvim_create_augroup("ClaudeTabClose", {}),
  desc = "Clean up claude processes when tab is closed",
  callback = function()
    for tid, proc in pairs(_procs_by_tab) do
      if not vim.api.nvim_tabpage_is_valid(tid) then
        proc:terminate()
        _procs_by_tab[tid] = nil
      end
    end
  end,
})
