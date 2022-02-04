local timer = nil
function stevearc.throttle_write(delay)
  local bufnr = vim.api.nvim_get_current_buf()
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
      if vim.api.nvim_buf_get_option(bufnr, "modified") then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("write")
        end)
      end
    end)
  )
end

vim.g.firenvim_config = {
  globalSettings = {
    -- replace with "noop" to disable
    ["<C-w>"] = "default",
    ["<C-n>"] = "default",
    ["<C-t>"] = "default",
  },
  localSettings = {
    [".*"] = {
      takeover = "never",
    },
  },
}

-- We wait to call this function until the firenvim buffer is loaded
function stevearc.firenvim_setup()
  vim.cmd([[
  aug FireNvimWrite
    au! * <buffer>
    au FocusLost <buffer> ++nested lua stevearc.throttle_write(10)
    au TextChanged <buffer> ++nested lua stevearc.throttle_write(1000)
    au TextChangedI <buffer> ++nested lua stevearc.throttle_write(1000)
  aug END
  ]])
  -- These create unnecessary autocmds for BufWritePre and BufWritePost
  -- By clearing them, we can improve the performance of :write
  vim.cmd([[
   aug filetypedetect
   au!
   aug END
   aug gzip
   au!
   aug END
   aug eunuch
   au!
   aug END
    ]])
end

if vim.g.started_by_firenvim then
  vim.api.nvim_set_option("guifont", "UbuntuMono Nerd Font:h11")
  vim.cmd([[
  aug FireNvimFT
    au!
    au BufEnter github.com_*.txt set filetype=markdown
    au BufEnter *.* ++once lua stevearc.firenvim_setup()
  aug END
  ]])
end
