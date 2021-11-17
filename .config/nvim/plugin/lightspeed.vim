lua <<EOF
require'lightspeed'.setup{
  jump_to_first_match = false,
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
map <C-s> <Plug>Lightspeed_s
