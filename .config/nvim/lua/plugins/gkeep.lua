local is_mac = vim.loop.os_uname().sysname == "Darwin"
return {
  "stevearc/gkeep.nvim",
  enabled = not is_mac,
  event = "BufReadPre gkeep://*",
  cmd = { "GkeepToggle", "GkeepNew", "GkeepOpen", "GkeepLogin", "GkeepLogout" },
  keys = {
    {
      "<leader>n",
      "<cmd>GkeepToggle<CR>",
      desc = "[N]otes",
      mode = "n",
    },
    {
      "<tab>",
      function()
        require("luasnip").jump(1)
      end,
      mode = "s",
    },
    {
      "<s-tab>",
      function()
        require("luasnip").jump(-1)
      end,
      mode = { "i", "s" },
    },
  },
  config = function()
    -- vim.g.gkeep_sync_dir = '~/notes'
    -- vim.g.gkeep_sync_archived = true
    vim.g.gkeep_log_levels = {
      gkeep = "debug",
      gkeepapi = "warning",
    }
    local p = require("p")
    local ftplugin = p.require("ftplugin")
    local gkeep_bindings = {
      { "n", "<leader>m", "<CMD>GkeepEnter menu<CR>" },
      { "n", "<leader>l", "<CMD>GkeepEnter list<CR>" },
    }
    ftplugin.set("GoogleKeepList", {
      callback = function(bufnr)
        -- FIXME update the api for stickybuf
        vim.cmd("silent! PinBuffer")
      end,
      bindings = gkeep_bindings,
    })
    ftplugin.set("GoogleKeepMenu", ftplugin.get("GoogleKeepList"))
    ftplugin.set("GoogleKeepNote", {
      bindings = vim.list_extend({
        { "n", "<leader>x", "<CMD>GkeepCheck<CR>" },
        { "n", "<leader>p", "<CMD>GkeepPopup<CR>" },
        { "n", "<leader>fl", "<CMD>Telescope gkeep link<CR>" },
      }, gkeep_bindings),
    })
    ftplugin.extend("norg", { bindings = gkeep_bindings })
  end,
}
