" Customizations for terminal mode
tnoremap <leader><leader> <C-\><C-N>
tnoremap <leader>1 <C-\><C-N>1gt
tnoremap <leader>2 <C-\><C-N>2gt
tnoremap <leader>3 <C-\><C-N>3gt
tnoremap <leader>4 <C-\><C-N>4gt
tnoremap <leader>5 <C-\><C-N>5gt
tnoremap <leader>6 <C-\><C-N>6gt
tnoremap <leader>7 <C-\><C-N>7gt
tnoremap <leader>8 <C-\><C-N>8gt
tnoremap <leader>9 <C-\><C-N>9gt
tnoremap <leader>h <C-\><C-N>:wincmd h<CR>
tnoremap <leader>l <C-\><C-N>:wincmd l<CR>
tnoremap <leader>j <C-\><C-N>:wincmd j<CR>
tnoremap <leader>k <C-\><C-N>:wincmd k<CR>
tnoremap <leader>: <C-\><C-N>:
highlight TermCursor ctermfg=DarkRed guifg=red
aug TerminalInsert
    au!
    au BufEnter * if &buftype == 'terminal' | :startinsert | endif
aug END
