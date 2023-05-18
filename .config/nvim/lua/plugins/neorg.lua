-- Treesitter parser requires a compiler with C++14 support
-- On mac, you can get this with `brew install gcc`
local enabled = true
if vim.loop.os_uname().sysname == "Darwin" then
  enabled = false
  local bins = vim.split(vim.fn.glob("/opt/homebrew/Cellar/gcc/*/bin/gcc-*"), "\n")
  for _, bin in ipairs(bins) do
    local basename = vim.fn.fnamemodify(bin, ":t")
    if basename:match("^gcc%-%d+$") then
      vim.env.CC = bin
      enabled = true
      break
    end
  end
end
return {
  "nvim-neorg/neorg",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter", "jbyuki/venn.nvim" },
  enabled = enabled,
  build = ":Neorg sync-parsers",
  keys = {
    { "<CR>", ":VBox<CR>", mode = "v" },
  },
  ft = "norg",
  cmd = "Neorg",
  opts = {
    load = {
      ["core.defaults"] = {}, -- Loads default behaviour
      ["core.concealer"] = { -- Adds pretty icons to your documents
        config = {
          icons = {
            todo = {
              undone = {
                icon = " ",
              },
            },
          },
        },
      },
      ["core.completion"] = {
        config = {
          engine = "nvim-cmp",
        },
      },
      -- This is deleting the non-empty contents of files
      -- ["core.esupports.metagen"] = {
      --   config = {
      --     type = "auto",
      --   },
      -- },
      ["core.presenter"] = {
        config = {
          zen_mode = "zen-mode",
        },
      },
      ["core.keybinds"] = {
        config = {
          hook = function(keybinds)
            keybinds.unmap("norg", "n", "<CR>")

            keybinds.unmap("presenter", "n", "l")
            keybinds.unmap("presenter", "n", "h")
            keybinds.unmap("presenter", "n", "<CR>")
            keybinds.unmap("presenter", "n", "q")

            -- Unmaps any Neorg key from the `norg` mode
            keybinds.remap_event("presenter", "n", "<Right>", "core.presenter.next_page")
            keybinds.remap_event("presenter", "n", "<C-j>", "core.presenter.next_page")
            keybinds.remap_event("presenter", "n", "<Left>", "core.presenter.previous_page")
            keybinds.remap_event("presenter", "n", "<C-k>", "core.presenter.previous_page")
            keybinds.remap_event("presenter", "n", "<Down>", "core.presenter.close")
            keybinds.map("norg", "n", "<Up>", "<CMD>Neorg presenter start<CR>")
          end,
        },
      },
    },
  },
  config = function(_, opts)
    local neorg = require("neorg")
    neorg.setup(opts)

    local p = require("p")

    p.require("quick_action", function(quick_action)
      quick_action.add("menu", {
        name = "Toggle todo status",
        condition = function()
          if vim.bo.filetype ~= "norg" then
            return false
          end
          local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
          local todo_module = neorg.modules.get_module("core.qol.todo_items")
          local item = todo_module and todo_module.get_todo_item_from_cursor(0, lnum)
          local row = item and item:start()
          return row == lnum
        end,
        action = function()
          vim.cmd("Neorg keybind norg core.qol.todo_items.todo.task_cycle")
        end,
      })
    end)
  end,
}
