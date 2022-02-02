safe_require("aerial", function(aerial)
  aerial.setup({
    default_direction = "left",
    close_behavior = "global",
    placement_editor_edge = true,
    highlight_on_jump = false,
    link_folds_to_tree = true,
    link_tree_to_folds = true,
    manage_folds = true,
    nerd_font = vim.g.nerd_font,

    backends = {
      ["_"] = { "treesitter", "lsp", "markdown" },
      -- ["_"] = { "treesitter", "markdown" },
      -- ["_"] = { "lsp", "markdown" },
    },
    on_attach = function(bufnr)
      local function map(mode, key, result)
        vim.api.nvim_buf_set_keymap(bufnr, mode, key, result, { noremap = true, silent = true })
      end
      map("n", "<leader>a", "<cmd>AerialToggle!<CR>")
      map("n", "{", "<cmd>AerialPrev<CR>")
      map("v", "{", "<cmd>AerialPrev<CR>")
      map("n", "}", "<cmd>AerialNext<CR>")
      map("v", "}", "<cmd>AerialNext<CR>")
      map("n", "[[", "<cmd>AerialPrevUp<CR>")
      map("v", "[[", "<cmd>AerialPrevUp<CR>")
      map("n", "]]", "<cmd>AerialNextUp<CR>")
      map("v", "]]", "<cmd>AerialNextUp<CR>")
    end,
  })
end)
