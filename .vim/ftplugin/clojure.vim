" Always enable rainbow parentheses
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

nnoremap <buffer> gd :exec "normal \<Plug>FireplaceDjump"<CR>
