" Enter to follow links
nnoremap <buffer> <CR> <C-]>
" Backspace to go back
nnoremap <buffer> <BS> <C-T>
" o and O to find next/prev option
nnoremap <buffer> o /'\l\{2,\}'<CR>
nnoremap <buffer> O ?'\l\{2,\}'<CR>
" s and S to find next/prev subject
nnoremap <buffer> s /\|\zs\S\+\ze\|<CR>
nnoremap <buffer> S ?\|\zs\S\+\ze\|<CR>
