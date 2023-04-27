local lazy_aerial = setmetatable({}, {
  __index = function(_, k)
    return function(...)
      require("aerial")[k](...)
    end
  end,
})
return {
  "stevearc/aerial.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  cmd = { "AerialToggle", "AerialOpen" },
  keys = {
    { "<leader>a", "<cmd>AerialToggle!<CR>", desc = "[A]erial toggle", mode = "n" },
    { "<leader>A", "<cmd>AerialNavToggle<CR>", desc = "[A]erial nav toggle", mode = "n" },
    { "[s", lazy_aerial.prev, desc = "Previous aerial symbol", mode = { "n", "v" } },
    { "]s", lazy_aerial.next, desc = "Next aerial symbol", mode = { "n", "v" } },
    { "[u", lazy_aerial.prev_up, desc = "Previous aerial parent symbol", mode = { "n", "v" } },
    { "]u", lazy_aerial.next_up, desc = "Next aerial parent symbol", mode = { "n", "v" } },
  },
  opts = {
    show_guides = true,
    layout = {
      max_width = { 80, 0.2 },
      default_direction = "prefer_left",
      -- placement = "edge",
      -- preserve_equality = true,
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
    lazy_load = false,
    -- backends = { "lsp", "treesitter", "markdown" },
    -- filter_kind = false,
    keymaps = {
      ["<"] = "actions.tree_decrease_fold_level",
      [">"] = "actions.tree_increase_fold_level",
    },
  },
  config = function(_, opts)
    require("aerial").setup(opts)
    local p = require("p")
    local ftplugin = p.require("ftplugin")
    ftplugin.extend("aerial", {
      ignore_win_opts = true,
    })
    ftplugin.extend("aerial-nav", {
      ignore_win_opts = true,
    })
  end,
}
