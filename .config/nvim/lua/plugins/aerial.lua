local lazy = require("lazy")
local ftplugin = lazy.require("ftplugin")
lazy.require("aerial", function(aerial)
  ftplugin.extend("aerial", {
    ignore_win_opts = true,
  })
  aerial.setup({
    show_guides = true,
    layout = {
      max_width = { 80, 0.2 },
      default_direction = "prefer_left",
      -- placement = "edge",
      preserve_equality = true,
    },
    -- attach_mode = "global",
    highlight_on_hover = true,
    close_automatic_events = {
      -- "unfocus",
      -- "switch_buffer",
      -- "unsupported",
    },
    -- open_automatic = true,
    -- highlight_on_jump = false,
    link_folds_to_tree = true,
    link_tree_to_folds = true,
    manage_folds = {
      ["_"] = true,
    },
    nerd_font = vim.g.nerd_font,

    -- backends = { "treesitter", "markdown" },
    -- backends = { "lsp", "treesitter" },
    lazy_load = true,
    -- backends = { "lsp", "treesitter", "markdown" },
    -- filter_kind = false,
    on_attach = function(bufnr)
      -- vim.keymap.set({ "n", "v" }, "{", aerial.prev, { buffer = bufnr })
      -- vim.keymap.set({ "n", "v" }, "}", aerial.next, { buffer = bufnr })
    end,
    keymaps = {
      ["<"] = "actions.tree_decrease_fold_level",
      [">"] = "actions.tree_increase_fold_level",
    },
  })
  vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>", { desc = "[A]erial toggle" })
  vim.keymap.set({ "n", "v" }, "[s", aerial.prev, { desc = "Previous aerial symbol" })
  vim.keymap.set({ "n", "v" }, "]s", aerial.next, { desc = "Next aerial symbol" })
  vim.keymap.set({ "n", "v" }, "[u", aerial.prev_up, { desc = "Previous aerial parent symbol" })
  vim.keymap.set({ "n", "v" }, "]u", aerial.next_up, { desc = "Next aerial parent symbol" })
end)
