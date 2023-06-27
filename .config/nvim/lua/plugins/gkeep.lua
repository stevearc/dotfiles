local uv = vim.uv or vim.loop
local is_mac = uv.os_uname().sysname == "Darwin"
return {
  "stevearc/gkeep.nvim",
  build = "UpdateRemotePlugins",
  enabled = not is_mac,
  event = "BufReadPre gkeep://*",
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
      bindings = gkeep_bindings,
    })
    ftplugin.set("GoogleKeepMenu", ftplugin.get("GoogleKeepList"))
    ftplugin.set("GoogleKeepNote", {
      bindings = vim.list_extend({
        { "n", "<leader>p", "<CMD>GkeepPopup<CR>" },
        { "n", "<leader>fl", "<CMD>Telescope gkeep link<CR>" },
      }, gkeep_bindings),
    })
    ftplugin.extend("norg", { bindings = gkeep_bindings })

    p.require("quick_action", function(quick_action)
      quick_action.add("menu", {
        name = "Toggle Gkeep check",
        condition = function()
          return vim.bo.filetype == "GoogleKeepNote" and vim.b.note_type == "list"
        end,
        action = function()
          vim.cmd.GkeepCheck()
        end,
      })
    end)
  end,
}
