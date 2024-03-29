local uv = vim.uv or vim.loop
return {
  "glacambre/firenvim",
  lazy = not vim.g.started_by_firenvim,
  build = function()
    vim.fn["firenvim#install"](0)
  end,
  config = function()
    if not vim.g.started_by_firenvim then
      return
    end
    local timer = nil
    local function throttle_write(delay)
      local bufnr = vim.api.nvim_get_current_buf()
      if timer then
        timer:close()
      end
      timer = uv.new_timer()
      timer:start(
        delay or 1000,
        0,
        vim.schedule_wrap(function()
          timer:close()
          timer = nil
          if vim.bo[bufnr].modified then
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd.write()
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

    vim.o.guifont = "UbuntuMono Nerd Font:h11"
    local group = vim.api.nvim_create_augroup("FireNvimFT", {})
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "github.com_*.txt",
      command = "set filetype=markdown",
      group = group,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*.*",
      once = true,
      group = group,
      callback = function()
        -- We wait to call this function until the firenvim buffer is loaded
        local buf_group = vim.api.nvim_create_augroup("FireNvimWrite", {})
        vim.api.nvim_create_autocmd({ "FocusLost", "TextChanged", "TextChangedI" }, {
          buffer = vim.api.nvim_get_current_buf(),
          group = buf_group,
          nested = true,
          callback = function(params)
            local delay = params.event == "FocusLost" and 10 or 1000
            throttle_write(delay)
          end,
        })
        -- These create unnecessary autocmds for BufWritePre and BufWritePost
        -- By clearing them, we can improve the performance of :write
        local unnecessary_groups = { "filetypedetect", "gzip", "eunuch" }
        for _, name in ipairs(unnecessary_groups) do
          local ok, err = pcall(vim.api.nvim_del_augroup_by_name, name)
          if not ok then
            vim.notify(string.format("Could not delete augroup '%s': %s", name, err), vim.log.levels.WARN)
          end
        end
      end,
    })
  end,
}
