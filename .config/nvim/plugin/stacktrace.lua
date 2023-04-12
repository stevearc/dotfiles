vim.api.nvim_create_user_command("Stacktrace", function(params)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 1,
    col = 1,
    border = "rounded",
    style = "minimal",
    title = "Stacktrace",
    title_pos = "center",
  })
  local cancel
  local confirm
  cancel = function()
    cancel = function() end
    confirm = function() end
    vim.api.nvim_win_close(winid, true)
  end
  confirm = function()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    cancel()
    local items = vim.fn.getqflist({
      lines = lines,
    }).items
    -- Use :Stacktrace! to not filter out invalid lines
    if not params.bang then
      items = vim.tbl_filter(function(item)
        return item.valid == 1
      end, items)
    end
    vim.fn.setqflist({}, " ", {
      title = "Stacktrace",
      items = items,
    })
    vim.cmd("copen")
  end
  vim.keymap.set("n", "q", cancel, { buffer = bufnr })
  vim.keymap.set({ "n", "i" }, "<C-c>", cancel, { buffer = bufnr })
  vim.keymap.set("n", "<CR>", confirm, { buffer = bufnr })
  vim.keymap.set({ "n", "i" }, "<C-s>", confirm, { buffer = bufnr })
end, {
  desc = "Parse a stacktrace using errorformat and add to quickfix",
  bang = true,
})
