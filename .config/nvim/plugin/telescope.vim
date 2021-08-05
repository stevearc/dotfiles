lua <<EOF
require('telescope').setup{
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
      ".*/%.git/"
    },
  },
}
require('telescope').load_extension('aerial')
require('telescope').load_extension('gkeep')
EOF
nnoremap <leader>t <cmd>lua require('telescope.builtin').find_files({previewer=false})<cr>
nnoremap <leader>bb <cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<CR>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').live_grep{grep_open_files = true}<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<CR>
nnoremap <leader>f. <cmd>lua require('telescope.builtin').find_files({cwd=string.format('%s/dotfiles/.config/nvim/', os.getenv('HOME')), follow=true, hidden=true, previewer=false})<cr>
nnoremap <leader>fl <cmd>lua require('telescope.builtin').find_files({cwd=string.format('%s/.local/share/nvim-local/', os.getenv('HOME')), follow=true, hidden=true, previewer=false})<cr>
nnoremap <leader>fc <cmd>Telescope commands<CR>
nnoremap <leader>fs <cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>
nnoremap <leader>fd <cmd>Telescope aerial<CR>
nnoremap <leader>fn <cmd>Telescope gkeep<CR>
