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
EOF
nnoremap <leader>t <cmd>lua require('telescope.builtin').find_files({previewer=false})<cr>
nnoremap <leader>bb <cmd>lua require('telescope.builtin').buffers({previewer=false})<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').live_grep{grep_open_files = true}<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fd <cmd>lua require('telescope.builtin').find_files({cwd=string.format('%s/dotfiles/.config/nvim/', os.getenv('HOME')), follow=true, hidden=true, previewer=false})<cr>
nnoremap <leader>fc <cmd>lua require('telescope.builtin').commands()<CR>
nnoremap <leader>fs <cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>
