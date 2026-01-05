---@type table<integer, ClaudeProcess>
local procs = {}

---Creates an iterator that processes stdout data chunks into complete lines
---@return fun(data: string[]): string[]
local function get_stdout_line_iter()
  local pending = ""
  return function(data)
    local ret = {}
    for i, chunk in ipairs(data) do
      if i == 1 then
        if chunk == "" then
          if pending:len() > 0 then
            table.insert(ret, pending)
          end
          pending = ""
        else
          pending = pending .. chunk
        end
      else
        if not (data[1] == "" and i == 2) then
          if pending:len() > 0 then
            table.insert(ret, pending)
          end
        end
        pending = chunk
      end
    end
    return ret
  end
end

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@class (exact) ClaudeProcess
---@field prompt string
---@field bufnr integer
---@field private target_lnum integer
---@field private progress_mark? integer
---@field private messages_win? integer
---@field private messages_buf? integer
---@field jid? integer
---@field canceled? boolean
---@field messages string[]
local ClaudeProcess = {}

---Check if the Claude process is currently running
function ClaudeProcess:running() return self.jid ~= nil end

---Cancel the currently running Claude process
function ClaudeProcess:cancel()
  local jid = self.jid
  if jid then
    self.jid = nil
    self.canceled = true
    vim.fn.jobstop(jid)
  end
end

---Start a new Claude process with the given prompt
---@param prompt string
local function start_proc(prompt)
  local bufnr = vim.api.nvim_get_current_buf()
  if procs[bufnr] and procs[bufnr]:running() then
    vim.notify("You may only have one active claude process per buffer", vim.log.levels.ERROR)
    return
  end
  local self = setmetatable({
    prompt = prompt,
    bufnr = bufnr,
    target_lnum = vim.api.nvim_win_get_cursor(0)[1],
    messages = { prompt, "Starting claude..." },
  }, { __index = ClaudeProcess })

  vim.bo.modifiable = false
  local stdout_iter = get_stdout_line_iter()
  local render_timer = assert(vim.uv.new_timer())
  render_timer:start(0, 100, vim.schedule_wrap(function() self:_render_progress() end))

  local cmd = {
    "claude",
    "--verbose",
    "--permission-mode=acceptEdits",
    "--print",
    "--output-format",
    "stream-json",
    prompt,
  }
  local jid = vim.fn.jobstart(cmd, {
    pty = true,
    on_stdout = function(job_id, data, method)
      for _, line in ipairs(stdout_iter(data)) do
        local ok, output = pcall(vim.json.decode, line)
        if ok then
          if output.type == "assistant" then
            for _, msg in ipairs(output.message.content) do
              if msg.type == "text" then
                self:_on_msg(msg.text)
              end
            end
          end
        end
      end
    end,
    on_exit = vim.schedule_wrap(function(job_id, exit_code, event)
      render_timer:stop()
      render_timer:close()
      self:_on_exit(exit_code)
    end),
  })
  if jid == 0 then
    vim.notify("Invalid arguments to jobstart", vim.log.levels.ERROR)
  elseif jid == -1 then
    vim.notify("'claude' is not executable", vim.log.levels.ERROR)
  else
    self.jid = jid
  end

  procs[self.bufnr] = self
end

---Toggle the messages history window
function ClaudeProcess:toggle_messages_win()
  if self.messages_win and vim.api.nvim_win_is_valid(self.messages_win) then
    vim.api.nvim_win_close(self.messages_win, true)
    self.messages_win = nil
    self.messages_buf = nil
    return
  end
  self.messages_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[self.messages_buf].buftype = "nofile"
  vim.bo[self.messages_buf].bufhidden = "wipe"
  self.messages_win = vim.api.nvim_open_win(self.messages_buf, true, {
    relative = "editor",
    width = vim.o.columns - 2,
    height = vim.o.lines - vim.o.cmdheight - 2,
    row = 1,
    col = 1,
    style = "minimal",
    title = "Claude",
    title_pos = "center",
  })

  vim.bo[self.messages_buf].filetype = "markdown"
  vim.b[self.messages_buf].is_claude_messages = true
  local lines = {}
  for _, msg in ipairs(self.messages) do
    if #lines > 0 then
      table.insert(lines, "")
      table.insert(lines, "---")
    end
    vim.list_extend(lines, vim.split(msg, "\n"))
  end
  vim.api.nvim_buf_set_lines(self.messages_buf, 0, -1, false, lines)
  vim.bo[self.messages_buf].modifiable = false
  vim.bo[self.messages_buf].modified = false
end

---Handle process exit cleanup and notifications
---@param exit_code integer
function ClaudeProcess:_on_exit(exit_code)
  self.jid = nil
  vim.bo[self.bufnr].modifiable = true
  if self.progress_mark and vim.api.nvim_buf_is_valid(self.bufnr) then
    local ns = vim.api.nvim_create_namespace("claude")
    vim.api.nvim_buf_del_extmark(self.bufnr, ns, self.progress_mark)
  end
  if exit_code == 0 then
    if vim.api.nvim_buf_is_valid(self.bufnr) then
      vim.cmd.checktime({ args = { self.bufnr } })
    end
    vim.notify("Claude code done")
  elseif not self.canceled then
    vim.notify("Claude code error", vim.log.levels.ERROR)
  end
end

---Handle incoming message from Claude process
---@param msg string
function ClaudeProcess:_on_msg(msg)
  table.insert(self.messages, msg)
  if self.messages_buf and vim.api.nvim_buf_is_valid(self.messages_buf) then
    local new_lines = vim.list_extend({ "", "---" }, vim.split(msg, "\n"))
    local nlines = vim.api.nvim_buf_line_count(self.messages_buf)
    vim.bo[self.messages_buf].modifiable = true
    vim.api.nvim_buf_set_lines(self.messages_buf, nlines, nlines, false, new_lines)
    vim.bo[self.messages_buf].modifiable = false
    vim.bo[self.messages_buf].modified = false
  end
end

---Render progress indicator with spinner
function ClaudeProcess:_render_progress()
  local ns = vim.api.nvim_create_namespace("claude")
  local lines = vim.split(self.messages[#self.messages], "\n")
  local icon = spinner[math.floor(vim.uv.hrtime() / (1e6 * 100)) % #spinner + 1]
  lines[1] = icon .. " " .. lines[1]
  local virt_lines = vim.tbl_map(function(l) return { { l, "Comment" } } end, lines)
  self.progress_mark = vim.api.nvim_buf_set_extmark(self.bufnr, ns, self.target_lnum - 1, 0, {
    id = self.progress_mark,
    virt_lines = virt_lines,
  })
end

vim.api.nvim_create_autocmd("BufUnload", {
  pattern = "*",
  desc = "Clean up claude state",
  group = vim.api.nvim_create_augroup("Claude", {}),
  callback = function(args)
    local proc = procs[args.buf]
    if proc and proc:running() then
      proc:cancel()
    end
    procs[args.buf] = nil
  end,
})

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

---@class (exact) ClaudeOpts
---@field context? 'file'|'line'

---Run Claude with a prompt on the current buffer, line, or visual selection
---@param prompt string
---@param opts? ClaudeOpts
local function run_claude_on_range(prompt, opts)
  opts = opts or {}
  if vim.bo.buftype ~= "" then
    vim.notify("Cannot run Claude on non-normal buffer", vim.log.levels.ERROR)
    return
  end
  vim.cmd.update()

  local filename = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  if vim.startswith(filename, cwd) then
    filename = filename:sub(cwd:len() + 2)
  end

  local location
  local mode = vim.api.nvim_get_mode().mode
  local lnum
  if mode == "v" or mode == "V" then
    if opts.context == nil then
      opts.context = "line"
    end
    local range = range_from_selection()
    location = string.format("lines %d-%d in %s", range[1], range[2], filename)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  else
    lnum = vim.api.nvim_win_get_cursor(0)[1]
    location = string.format("line %d in %s", lnum, filename)
  end
  if opts.context ~= "line" then
    location = filename
  end

  prompt = string.format("Look at %s. %s.", location, prompt)
  start_proc(prompt)
end

local actions = {
  autofill = {
    desc = "Auto implement some code",
    callback = function()
      run_claude_on_range("Implement the missing code. No need to run tests or format the code", { context = "line" })
    end,
  },
  skeleton = {
    desc = "Implement file skeleton",
    callback = function()
      run_claude_on_range("Implement the skeleton of this file. No need to run tests or format the code")
    end,
  },
  prompt = {
    desc = "Create and execute prompt",
    callback = function()
      vim.ui.input({ prompt = "claude" }, function(text)
        if text then
          run_claude_on_range(text)
        end
      end)
    end,
  },
  toggle_messages = {
    desc = "Toggle messages history",
    cond = function() return procs[vim.api.nvim_get_current_buf()] ~= nil or vim.b.is_claude_messages end,
    callback = function()
      if vim.b.is_claude_messages then
        vim.cmd.quit()
      else
        procs[vim.api.nvim_get_current_buf()]:toggle_messages_win()
      end
    end,
  },
  cancel = {
    desc = "Cancel current process",
    cond = function()
      local proc = procs[vim.api.nvim_get_current_buf()]
      return proc and proc:running()
    end,
    callback = function()
      local proc = procs[vim.api.nvim_get_current_buf()]
      proc:cancel()
    end,
  },
}

---Map a keymap to a Claude action
local function map_action(keys, action_name)
  local action = assert(actions[action_name])
  vim.keymap.set({ "n", "v" }, keys, function()
    if action.cond and not action.cond() then
      vim.notify("Cannot " .. action.desc, vim.log.levels.ERROR)
    else
      action.callback()
    end
  end, { desc = action.desc })
end

map_action("<leader>if", "autofill")
map_action("<leader>is", "skeleton")
map_action("<leader>ip", "prompt")
map_action("<leader>ic", "cancel")
map_action("<leader>im", "toggle_messages")

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
