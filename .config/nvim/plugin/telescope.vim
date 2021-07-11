lua <<EOF
require('telescope').setup{
  defaults = {
    winblend = 10,
  },
}
EOF
nnoremap <leader>t <cmd>lua require('stevearc.telescope').find_files({previewer=false})<cr>
nnoremap <leader>bb <cmd>lua require('stevearc.telescope').buffers({previewer=false})<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').live_grep{grep_open_files = true}<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fd <cmd>lua require('stevearc.telescope').find_files({cwd='/home/stevearc/dotfiles/.config/nvim/', follow=true, hidden=true, previewer=false})<cr>
nnoremap <leader>fc <cmd>lua require('telescope.builtin').commands()<CR>
nnoremap <leader>fs <cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>
