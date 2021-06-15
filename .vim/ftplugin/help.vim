" Enter to follow links
nnoremap <buffer> <CR> <C-]>
" Backspace to go back
nnoremap <buffer> <BS> <C-T>
" find next/prev option
nnoremap <buffer> <C-o> /'\l\{2,\}'<CR>
nnoremap <buffer> <C-O> ?'\l\{2,\}'<CR>
" find next/prev subject
nnoremap <buffer> <C-s> /\|\zs\S\+\ze\|<CR>
nnoremap <buffer> <C-S> ?\|\zs\S\+\ze\|<CR>

setlocal bufhidden=wipe
