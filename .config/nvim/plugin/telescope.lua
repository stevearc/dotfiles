require("telescope").setup({
  defaults = {
    winblend = 10,
    file_ignore_patterns = {
      ".*%.png$",
      ".*%.jpg$",
      ".*%.jpeg$",
      ".*%.gif$",
      ".*%.wav$",
      ".*%.aiff$",
      ".*%.dll$",
      ".*%.pdb$",
      ".*%.mdb$",
      ".*%.so$",
      ".*%.swp$",
      ".*%.zip$",
      ".*%.gz$",
      ".*%.bz2$",
      ".*%.meta",
      ".*%.cache",
      ".*/%.git/",
    },
  },
  extensions = {
    gkeep = {
      find_method = "title",
    },
  },
})
require("telescope").load_extension("aerial")
require("telescope").load_extension("gkeep")
require("telescope").load_extension("luasnip")

local function map(lhs, rhs, mode)
  vim.api.nvim_set_keymap(mode or "n", lhs, rhs, { noremap = true, silent = true })
end

map("<leader>t", "<cmd>lua require('telescope.builtin').find_files({previewer=false})<cr>")
map("<leader>bb", "<cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>")
map("<leader>fg", "<cmd>Telescope live_grep<CR>")
map("<leader>fb", "<cmd>lua require('telescope.builtin').live_grep({grep_open_files = true})<cr>")
map("<leader>fh", "<cmd>Telescope help_tags<CR>")
map("<leader>fp", "<cmd>lua require('stevearc').telescope_pick_project()<CR>")
map(
  "<leader>f.",
  "<cmd>lua require('telescope.builtin').find_files({cwd=string.format('%s/dotfiles/.config/nvim/', os.getenv('HOME')), follow=true, hidden=true, previewer=false})<cr>"
)
map(
  "<leader>fl",
  "<cmd>lua require('telescope.builtin').find_files({cwd=string.format('%s/.local/share/nvim-local/', os.getenv('HOME')), follow=true, hidden=true, previewer=false})<cr>"
)
map("<leader>fc", "<cmd>Telescope commands<CR>")
map("<leader>fs", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>")
map("<leader>fd", "<cmd>Telescope aerial<CR>")
map("<leader>fn", "<cmd>Telescope gkeep<CR>")
if vim.g.snippet_engine == "luasnip" then
  map(
    "<C-s>",
    "<cmd>lua require('telescope').extensions.luasnip.luasnip(require('telescope.themes').get_cursor({}))<CR>",
    "i"
  )
end
