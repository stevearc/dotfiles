" Customizations for terminal mode
tnoremap \\ <C-\><C-N>

if g:use_barbar
  tnoremap <silent> \1 <C-\><C-N>:BufferGoto 1<CR>
  tnoremap <silent> \2 <C-\><C-N>:BufferGoto 2<CR>
  tnoremap <silent> \3 <C-\><C-N>:BufferGoto 3<CR>
  tnoremap <silent> \4 <C-\><C-N>:BufferGoto 4<CR>
  tnoremap <silent> \5 <C-\><C-N>:BufferGoto 5<CR>
  tnoremap <silent> \6 <C-\><C-N>:BufferGoto 6<CR>
  tnoremap <silent> \7 <C-\><C-N>:BufferGoto 7<CR>
  tnoremap <silent> \8 <C-\><C-N>:BufferGoto 8<CR>
  tnoremap <silent> \9 <C-\><C-N>:BufferGoto 9<CR>
  tnoremap <silent> \` <C-\><C-N>:BufferLast<CR>
  tnoremap <silent> \c <C-\><C-N>:BufferClose<CR>
else
  tnoremap \1 <C-\><C-N>1gt
  tnoremap \2 <C-\><C-N>2gt
  tnoremap \3 <C-\><C-N>3gt
  tnoremap \4 <C-\><C-N>4gt
  tnoremap \5 <C-\><C-N>5gt
  tnoremap \6 <C-\><C-N>6gt
  tnoremap \7 <C-\><C-N>7gt
  tnoremap \8 <C-\><C-N>8gt
  tnoremap \9 <C-\><C-N>9gt
  nnoremap \` <C-\><C-N>:$tabnext<CR>
endif
tnoremap \h <C-\><C-N><c-w>h<CR>
tnoremap \l <C-\><C-N><c-w>l<CR>
tnoremap \j <C-\><C-N><c-w>j<CR>
tnoremap \k <C-\><C-N><c-w>k<CR>
tnoremap \: <C-\><C-N>:
highlight TermCursor ctermfg=DarkRed guifg=red

function! s:MaybeFocus() abort
  if &buftype == 'terminal' && winnr('$') > 1
    startinsert
  endif
endfunction
" auto-enter insert mode when switching to a terminal
aug TerminalInsert
  au!
  au TermOpen * setlocal nonumber norelativenumber signcolumn=no | :startinsert
  au BufEnter * :call <sid>MaybeFocus()
aug END


lua <<EOF
require("toggleterm").setup{
  open_mapping = [[<c-\>]],
  hide_numbers = true,
  shade_terminals = false,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = false,
  direction = 'float',
  close_on_exit = true,
  float_opts = {
    border = 'single',
    winblend = 3,
  }
}
EOF
