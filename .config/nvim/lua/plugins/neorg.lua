return {
  "nvim-neorg/neorg",
  dependencies = {
    "jbyuki/venn.nvim",
  },
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
}
