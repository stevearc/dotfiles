lua <<EOF
require'lightspeed'.setup{
  highlight_unique_chars = false,
  safe_labels = nil,
}
EOF

" Disable all of lightspeed's default keymaps
unmap s
" unmap S
unmap f
unmap F
unmap t
unmap T
map <leader>j <Plug>Lightspeed_s
map <leader>k <Plug>Lightspeed_S
