" Customizations for terminal mode
tnoremap \\ <C-\><C-N>

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
tnoremap \h <C-\><C-N><c-w>h<CR>
tnoremap \l <C-\><C-N><c-w>l<CR>
tnoremap \j <C-\><C-N><c-w>j<CR>
tnoremap \k <C-\><C-N><c-w>k<CR>
tnoremap \: <C-\><C-N>:
highlight TermCursor ctermfg=DarkRed guifg=red

lua <<EOF
local aug = vim.api.nvim_create_augroup("TerminalDefaults", {})
vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Set defaults for terminal window",
  pattern = "*",
  command = "setlocal nonumber norelativenumber signcolumn=no",
  group = aug,
})
vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Auto enter insert mode when opening a terminal",
  pattern = "*",
  group = aug,
  callback = function()
    -- Wait briefly just in case we immediately switch out of the buffer
    vim.defer_fn(function()
      if vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal' then
        vim.cmd([[startinsert]])
      end
    end, 100)
  end,
})

safe_require("toggleterm").setup({
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
})
EOF

nnoremap <silent><c-\> <Cmd>exe v:count1 . "ToggleTerm"<CR>
inoremap <silent><c-\> <Esc><Cmd>exe v:count1 . "ToggleTerm"<CR>
