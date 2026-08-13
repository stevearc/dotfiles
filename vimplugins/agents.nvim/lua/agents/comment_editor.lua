local M = {}
local active

---@param initial string
---@param commit fun(text:string): boolean|string
---@param opts? {on_close?:fun()}
function M.open(initial, commit, opts)
  opts = opts or {}
  if active and vim.api.nvim_win_is_valid(active.winid) then
    vim.notify("A review comment editor is already open", vim.log.levels.WARN)
    return
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "agents-review-comment://" .. bufnr)
  -- acwrite makes :w dispatch to the buffer-local BufWriteCmd handler while
  -- retaining all other scratch-buffer behavior below.
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "agents-review-comment"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(initial, "\n", { plain = true }))
  local width = math.min(math.max(60, math.floor(vim.o.columns * 0.6)), vim.o.columns - 4)
  local height =
    math.min(math.max(8, #vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) + 2), vim.o.lines - 4)
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    title = " Review comment ",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
  })
  active = { bufnr = bufnr, winid = winid }
  local closed = false
  local function close()
    if closed then
      return
    end
    closed = true
    if opts.on_close then
      opts.on_close()
    end
  end
  local function save()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
    local ok, err = commit(text)
    if not ok then
      vim.notify(err or "Could not save comment", vim.log.levels.WARN)
      return
    end
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = save,
  })
  vim.keymap.set("n", "<CR>", save, { buffer = bufnr, desc = "Save review comment" })
  local function cancel()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end
  vim.keymap.set({ "n", "i" }, "<C-c>", cancel, { buffer = bufnr, desc = "Cancel review comment" })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function()
      active = nil
      close()
    end,
  })
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(winid, { line_count, 0 })
  -- Feed normal-mode `A` after the window is visible; unlike :startinsert,
  -- this preserves the normal interactive mode transition for a float.
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_get_current_win() == winid then
      vim.api.nvim_feedkeys(vim.keycode("A"), "n", false)
    end
  end)
end

return M
