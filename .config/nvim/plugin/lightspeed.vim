lua <<EOF
require'lightspeed'.setup{
  jump_to_first_match = false,
}
EOF

" Try using sS for a while
" unmap s
" unmap S
" Disable all of lightspeed's default keymaps
unmap f
unmap F
unmap t
unmap T
map <leader>j <Plug>Lightspeed_s
map <leader>k <Plug>Lightspeed_S
