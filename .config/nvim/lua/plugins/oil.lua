return {
  {
    "stevearc/resession.nvim",
    lazy = true,
    opts = {
      extensions = {
        oil = {},
      },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    cmd = { "Oil" },
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
      { "_", function() require("oil").open(vim.fn.getcwd()) end, desc = "Open cwd" },
    },
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = false,
      experimental_watch_for_changes = true,
      win_options = {
        concealcursor = "n",
      },
      keymaps = {
        ["`"] = "actions.tcd",
        ["~"] = "<cmd>edit $HOME<CR>",
        ["<leader>t"] = "actions.open_terminal",
        ["<leader>ff"] = {
          function()
            local dir = require("oil").get_current_dir()
            if vim.api.nvim_win_get_config(0).relative ~= "" then
              vim.api.nvim_win_close(0, true)
            end
            stevearc.find_files({ cwd = dir, hidden = true })
          end,
          desc = "[F]ind [F]iles in dir",
        },
        ["<leader>fg"] = {
          function()
            local dir = require("oil").get_current_dir()
            if vim.api.nvim_win_get_config(0).relative ~= "" then
              vim.api.nvim_win_close(0, true)
            end
            require("telescope.builtin").live_grep({ cwd = dir })
          end,
          desc = "[F]ind by [G]rep in dir",
        },
        ["gd"] = {
          desc = "Toggle detail view",
          callback = function()
            local oil = require("oil")
            local config = require("oil.config")
            if #config.columns == 1 then
              oil.set_columns({ "icon", "permissions", "size", "mtime" })
            else
              oil.set_columns({ "icon" })
            end
          end,
        },
      },
      view_options = {
        is_always_hidden = function(name, bufnr) return name == ".." end,
      },
    },
    config = function(_, opts)
      local oil = require("oil")
      oil.setup(opts)

      local p = require("p")
      local ftplugin = p.require("ftplugin")
      ftplugin.set("oil", {
        callback = function(bufnr)
          vim.api.nvim_buf_create_user_command(
            bufnr,
            "Save",
            function(params) oil.save({ confirm = not params.bang }) end,
            {
              desc = "Save oil changes with a preview",
              bang = true,
            }
          )
          vim.api.nvim_buf_create_user_command(
            bufnr,
            "OpenTerminal",
            function(params) require("oil.adapters.ssh").open_terminal() end,
            {
              desc = "Open the debug terminal for ssh connections",
            }
          )
        end,
      })
    end,
  },
}
