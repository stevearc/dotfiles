local timer = nil
function stevearc.throttle_write(delay)
  if timer then
    timer:close()
  end
  timer = vim.loop.new_timer()
  timer:start(
    delay or 1000,
    0,
    vim.schedule_wrap(function()
      timer:close()
      timer = nil
      if vim.o.modified then
        vim.cmd("write")
      end
    end)
  )
end

vim.g.firenvim_config = {
  globalSettings = {
    -- ["<C-w>"] = "noop",
    -- ["<C-n>"] = "noop",
  },
  localSettings = {
    [".*"] = {
      takeover = "never",
    },
  },
}

if vim.g.started_by_firenvim then
  vim.cmd([[
aug FireNvimFT
  au!
  au BufEnter github.com_*.txt set filetype=markdown
  au FocusLost * ++nested lua stevearc.throttle_write(10)
  au TextChanged * ++nested lua stevearc.throttle_write(1000)
  au TextChangedI * ++nested lua stevearc.throttle_write(1000)
aug END
]])
end
