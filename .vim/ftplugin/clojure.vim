" Always enable rainbow parentheses
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

nnoremap <buffer> gd :exec "normal \<Plug>FireplaceDjump"<CR>
inoremap <buffer> <C-j> <C-o>])
inoremap <buffer> <C-k> <C-o>[(

" Auto insert closing parens
inoremap <buffer> ( ()<C-o>F(<C-o>a
" When closing a paren, just move cursor to the right if it's already there
function! MaybeDeleteCloseParen()
  let pos = col('.')
  let line = getline('.')
  " This is more complicated than it should be because at the end of the line
  " vim doesn't know if it's inserting before or after the last character >.<
  if strlen(line) == pos
    if line[pos-2] == ")" && line[pos-1] == ")"
      normal x$
    endif
  elseif line[pos-1] == ")"
    normal x
  endif
endfunction
inoremap <buffer> ) )<C-o>:call MaybeDeleteCloseParen()<CR>
