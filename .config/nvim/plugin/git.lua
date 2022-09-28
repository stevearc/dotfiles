local function get_git_tabpage()
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    if pcall(vim.api.nvim_tabpage_get_var, tabpage, "is_git_main") then
      return vim.api.nvim_tabpage_get_number(tabpage)
    end
  end
end

local function set_buf_opts(focusable)
  vim.cmd("silent! PinBuffer!")
  vim.api.nvim_buf_set_option(0, "bufhidden", "delete")
  vim.api.nvim_buf_set_option(0, "buflisted", false)
  if not focusable then
    vim.api.nvim_buf_set_option(0, "scrollback", 1)
    vim.api.nvim_buf_set_var(0, "term_no_autoinsert", true)
  end
end

local function close_git_terms()
  local tabpage = get_git_tabpage()
  if tabpage then
    vim.cmd(string.format("tabclose %d", tabpage))
    return
  end
end

local TermDash = {}
TermDash.__index = TermDash
function TermDash:new()
  return setmetatable({
    debounce_id = 0,
    bufs = {},
  }, self)
end
function TermDash:on_output(_, data)
  for _, line in ipairs(data) do
    if string.find(line, "\r") then
      self:update()
    end
  end
end
function TermDash:add_buf(bufnr, command)
  self.bufs[bufnr] = command
end
function TermDash:update()
  self.debounce_id = self.debounce_id + 1
  local id = self.debounce_id
  vim.defer_fn(function()
    if self.debounce_id == id then
      self:_update()
    end
  end, 500)
end
local function sendcmd(bufnr, cmd)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    local ok, job_id = pcall(vim.api.nvim_buf_get_var, bufnr, "terminal_job_id")
    if ok then
      vim.fn.chansend(job_id, string.format("%s\n", cmd))
    end
  end
end
function TermDash:_update()
  for bufnr, cmd in pairs(self.bufs) do
    sendcmd(bufnr, string.format("clear; %s", cmd))
  end
end

local function toggle_git_terms()
  local tabpage = get_git_tabpage()
  if tabpage then
    vim.cmd(string.format("tabclose %d", tabpage))
    return
  end
  local dash = TermDash:new()
  vim.cmd("tabnew")
  vim.api.nvim_tabpage_set_var(0, "is_git_main", true)
  vim.fn.termopen("bash", {
    on_stdout = function(j, d)
      dash:on_output(j, d)
    end,
    on_stderr = function(j, d)
      dash:on_output(j, d)
    end,
    on_exit = function()
      close_git_terms()
    end,
  })
  set_buf_opts(true)

  -- Sidebar showing git history
  vim.cmd("botright vsplit")
  vim.cmd("terminal")
  set_buf_opts()
  local height = vim.api.nvim_win_get_height(0) - 3
  dash:add_buf(vim.api.nvim_get_current_buf(), string.format("git rc -%d", height))
  sendcmd(0, "export PS1=")
  vim.cmd("wincmd p")

  -- Top panel showing git status
  vim.cmd("leftabove split")
  vim.cmd("terminal")
  set_buf_opts()
  dash:add_buf(vim.api.nvim_get_current_buf(), "git status -s")
  sendcmd(0, "export PS1=")
  vim.cmd("wincmd p")
  dash:_update()
end

vim.keymap.set("n", "<leader>gt", toggle_git_terms)
