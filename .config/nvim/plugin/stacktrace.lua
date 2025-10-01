---@return boolean has_errorformat_line
---@return nil|string errorformat
---@return string[] lines
local function parse(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  local efm = nil
  local has_efm_line = false
  if lines[1] and vim.startswith(lines[1], "errorformat:") then
    efm = lines[1]:match("^errorformat: ?(.*)$")
    if efm == "" then
      efm = nil
    end
    table.remove(lines, 1)
    has_efm_line = true
  end
  return has_efm_line, efm, lines
end

local function set_quickfix(bufnr, valid_only)
  local _, efm, lines = parse(bufnr)
  local items = vim.fn.getqflist({
    lines = lines,
    efm = efm,
  }).items
  if valid_only then
    items = vim.tbl_filter(function(item) return item.valid == 1 end, items)
  end
  vim.fn.setqflist({}, " ", {
    title = "Stacktrace",
    items = items,
  })
end

HELP = {
  "%f  file name",
  "%l  line number",
  "%e  end line number",
  "%c  column number",
  "%k  end column number",
  "%m  error message",
  "%t  error type (e, w, i, or n)",
  "%n  error number",
  '%r  matches the "rest" of a message',
}

local function render(bufnr)
  local ns = vim.api.nvim_create_namespace("stacktrace")

  local has_efm, efm, lines = parse(bufnr)
  local ok, qflist = pcall(vim.fn.getqflist, {
    lines = lines,
    efm = efm,
  })

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if not ok then
    vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
      sign_text = "X",
      sign_hl_group = "DiagnosticError",
      virt_text = { { "Invalid errorformat", "DiagnosticError" } },
    })
    return
  end
  if has_efm then
    vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
      hl_group = "Title",
      end_col = 12,
      virt_text = { { "Press ? for errorformat help", "Comment" } },
      virt_text_pos = "right_align",
      virt_lines = #lines == 0
          and { { { "^-- Set the errorformat above, and paste the stack below --v", "Comment" } } }
        or nil,
    })
  end

  local offset = has_efm and 1 or 0
  for i, item in ipairs(qflist.items) do
    if item.valid == 1 then
      local filename = item.bufnr and vim.api.nvim_buf_get_name(item.bufnr) or "unknown"
      if item.bufnr and vim.fn.filereadable(filename) == 1 then
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1 + offset, 0, {
          sign_text = "✔",
          sign_hl_group = "DiagnosticOk",
        })
      else
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1 + offset, 0, {
          sign_text = "~",
          sign_hl_group = "DiagnosticWarn",
          virt_text = { { string.format("File '%s' not found", filename), "DiagnosticWarn" } },
        })
      end
    end
  end
end

vim.api.nvim_create_user_command("Stacktrace", function(params)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(bufnr, "stacktrace")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, { "errorformat: " })
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = vim.o.columns - 2,
    height = vim.o.lines - vim.o.cmdheight - 2,
    row = 1,
    col = 1,
    style = "minimal",
    title = "Stacktrace",
    title_pos = "center",
  })
  local cancel
  local confirm
  local help_winid
  cancel = function()
    cancel = function() end
    confirm = function() end
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
    if help_winid and vim.api.nvim_win_is_valid(help_winid) then
      vim.api.nvim_win_close(help_winid, true)
    end
  end
  confirm = function()
    set_quickfix(bufnr, not params.bang)
    cancel()
    vim.cmd.copen()
  end

  local function toggle_help()
    if help_winid and vim.api.nvim_win_is_valid(help_winid) then
      vim.api.nvim_win_close(help_winid, true)
      help_winid = nil
      return
    end
    local help_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[help_buf].buftype = "nofile"
    vim.bo[help_buf].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(help_buf, 0, -1, true, HELP)
    help_winid = vim.api.nvim_open_win(help_buf, false, {
      border = "none",
      style = "minimal",
      relative = "win",
      anchor = "NE",
      row = 0,
      col = vim.api.nvim_win_get_width(0),
      width = 40,
      height = #HELP,
      noautocmd = true,
      focusable = false,
      zindex = 70,
    })
  end

  vim.keymap.set("n", "?", toggle_help, { buffer = bufnr, desc = "Toggle help" })
  vim.keymap.set({ "n", "i" }, "<C-c>", cancel, { buffer = bufnr })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = confirm,
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    desc = "Close stacktrace window when leaving buffer",
    buffer = bufnr,
    once = true,
    nested = true,
    callback = cancel,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = bufnr,
    callback = function() render(bufnr) end,
  })
end, {
  desc = "Parse a stacktrace using errorformat and add to quickfix",
  bang = true,
})
