local lazy = require("lazy")
local ftplugin = lazy.require("ftplugin")

lazy.require("oil", function(oil)
  oil.setup({
    trash = false,
    skip_confirm_for_simple_edits = true,
    restore_win_options = false,
    keymaps = {
      ["`"] = "actions.tcd",
      ["~"] = "actions.cd",
      ["<C-t>"] = "actions.open_terminal",
      ["gd"] = {
        desc = "Toggle detail view",
        callback = function()
          local config = require("oil.config")
          if #config.columns == 1 then
            oil.set_columns({ "icon", "permissions", "size", "mtime" })
          else
            oil.set_columns({ "icon" })
          end
        end,
      },
    },
  })
  vim.keymap.set("n", "-", oil.open, { desc = "Open parent directory" })
  vim.keymap.set("n", "_", function()
    oil.open(vim.fn.getcwd())
  end, { desc = "Open cwd" })
  local function find_files()
    local dir = oil.get_current_dir()
    if vim.api.nvim_win_get_config(0).relative ~= "" then
      vim.api.nvim_win_close(0, true)
    end
    stevearc.find_files({ cwd = dir, hidden = true })
  end

  local function livegrep()
    local dir = oil.get_current_dir()
    if vim.api.nvim_win_get_config(0).relative ~= "" then
      vim.api.nvim_win_close(0, true)
    end
    require("telescope.builtin").live_grep({ cwd = dir })
  end

  ftplugin.set("oil", {
    bindings = {
      { "n", "<leader>ff", find_files, { desc = "[F]ind [F]iles in dir" } },
      { "n", "<leader>fg", livegrep, { desc = "[F]ind by [G]rep in dir" } },
    },
    opt = {
      conceallevel = 3,
      concealcursor = "n",
      list = false,
      wrap = false,
    },
    callback = function(bufnr)
      vim.api.nvim_buf_create_user_command(bufnr, "Save", function(params)
        oil.save({ confirm = not params.bang })
      end, {
        desc = "Save oil changes with a preview",
        bang = true,
      })
      vim.api.nvim_buf_create_user_command(bufnr, "EmptyTrash", function(params)
        oil.empty_trash()
      end, {
        desc = "Empty the trash directory",
      })
      vim.api.nvim_buf_create_user_command(bufnr, "OpenTerminal", function(params)
        require("oil.adapters.ssh").open_terminal()
      end, {
        desc = "Open the debug terminal for ssh connections",
      })
    end,
  })
end)